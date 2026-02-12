import 'dart:async';
import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_core/utils/tool_call_aggregator.dart';

import 'generate_object.dart';
import 'prompt_input.dart';
import 'stream_parts.dart';

/// A streaming object generation result (AI SDK-inspired).
///
/// This is a lightweight wrapper around parts-first streaming (`LLMStreamPart`)
/// that:
/// - exposes a broadcast stream (`fullStream`) of canonical parts,
/// - exposes a best-effort parsed object stream (`partialObjectStream`), and
/// - provides futures that resolve once the stream completes.
class StreamObjectResult {
  final Stream<LLMStreamPart> fullStream;

  /// Best-effort stream of parsed objects from the tool call arguments.
  ///
  /// This only emits when the buffered tool arguments contain a valid JSON
  /// object (map). Partial/incomplete JSON chunks are ignored.
  final Stream<Map<String, dynamic>> partialObjectStream;

  /// Resolves to the final parsed object (map).
  final Future<Map<String, dynamic>> object;

  /// Resolves to the final usage snapshot, if available.
  final Future<UsageInfo?> usage;

  /// Resolves to the final finish reason, if available.
  final Future<LLMFinishReason?> finishReason;

  /// Resolves to the final providerMetadata snapshot, best-effort.
  final Future<Map<String, dynamic>?> providerMetadata;

  /// Resolves to the final non-streaming view of the response.
  final Future<GenerateObjectResult> finalResult;

  /// Resolves when the stream completes (success or error).
  final Future<void> done;

  StreamObjectResult._({
    required this.fullStream,
    required this.partialObjectStream,
    required this.object,
    required this.usage,
    required this.finishReason,
    required this.providerMetadata,
    required this.finalResult,
    required this.done,
  });

  factory StreamObjectResult.fromPartsStream(
    Stream<LLMStreamPart> upstream, {
    required ParametersSchema schema,
    required String toolName,
  }) {
    final fullController =
        StreamController<LLMStreamPart>.broadcast(sync: true);
    final partialController =
        StreamController<Map<String, dynamic>>.broadcast(sync: true);

    final doneCompleter = Completer<void>();
    final objectCompleter = Completer<Map<String, dynamic>>();
    final usageCompleter = Completer<UsageInfo?>();
    final finishReasonCompleter = Completer<LLMFinishReason?>();
    final providerMetadataCompleter = Completer<Map<String, dynamic>?>();
    final finalResultCompleter = Completer<GenerateObjectResult>();

    // Prevent unhandled asynchronous errors when callers choose to only consume
    // the streams (or only await a subset of futures).
    unawaited(
        objectCompleter.future.catchError((_) => const <String, dynamic>{}));
    unawaited(usageCompleter.future.catchError((_) => null));
    unawaited(finishReasonCompleter.future.catchError((_) => null));
    unawaited(providerMetadataCompleter.future.catchError((_) => null));
    unawaited(finalResultCompleter.future.catchError(
      (_) => GenerateObjectResult(
        object: const <String, dynamic>{},
        rawResponse: const _UnhandledStreamErrorResponse(),
      ),
    ));

    final toolCallAgg = ToolCallAggregator();
    final endedToolCalls = <String>{};

    final toolInputBuffers = <String, StringBuffer>{};
    final toolInputNames = <String, String>{};
    final endedToolInputs = <String>{};

    final textBuffer = StringBuffer();

    Map<String, dynamic>? lastProviderMetadata;
    LLMFinishPart? finishPart;
    LLMError? terminalError;

    String? lastEmittedJson;

    void emitPartialIfParsable(String raw) {
      final parsed = _tryParseJsonObject(raw);
      if (parsed == null) return;

      // Best-effort dedupe to avoid noisy re-emissions.
      try {
        final json = jsonEncode(parsed);
        if (json == lastEmittedJson) return;
        lastEmittedJson = json;
      } catch (_) {
        // Ignore JSON encoding failures; still emit.
      }

      partialController.add(parsed);
    }

    void validateObjectOrThrow(Map<String, dynamic> obj) {
      final errors = ToolValidator.validateParameters(obj, schema);
      if (errors.isNotEmpty) {
        throw InvalidRequestError(
          'Generated object does not match schema: ${errors.join(', ')}',
        );
      }
    }

    Future<void> pump() async {
      try {
        await for (final part in upstream) {
          fullController.add(part);

          switch (part) {
            case LLMTextDeltaPart(:final delta):
              textBuffer.write(delta);

            case LLMTextEndPart(:final text):
              if (textBuffer.isEmpty && text.isNotEmpty) {
                textBuffer.write(text);
              }

            case LLMProviderMetadataPart(providerMetadata: final pm):
              lastProviderMetadata = pm;

            case LLMToolCallStartPart(:final toolCall):
            case LLMToolCallDeltaPart(:final toolCall):
              final aggregated = toolCallAgg.addDelta(toolCall);
              if (aggregated.function.name == toolName) {
                emitPartialIfParsable(aggregated.function.arguments);
              }

            case LLMToolCallEndPart(:final toolCallId):
              endedToolCalls.add(toolCallId);

            case LLMToolInputStartPart(id: final id, toolName: final name):
              toolInputNames[id] = name;
              toolInputBuffers[id] = StringBuffer();

            case LLMToolInputDeltaPart(id: final id, delta: final delta):
              final buf = toolInputBuffers[id];
              if (buf == null) break;
              buf.write(delta);
              if (toolInputNames[id] == toolName) {
                emitPartialIfParsable(buf.toString());
              }

            case LLMToolInputEndPart(id: final id):
              endedToolInputs.add(id);

            case LLMFinishPart():
              finishPart = part;

            case LLMErrorPart(error: final error):
              terminalError ??= error;

            default:
              break;
          }
        }
      } catch (e) {
        terminalError ??= GenericError('Unexpected stream error: $e');
      } finally {
        await fullController.close();
        await partialController.close();
        doneCompleter.complete();

        if (terminalError != null) {
          final err = terminalError!;
          if (!objectCompleter.isCompleted) objectCompleter.completeError(err);
          if (!usageCompleter.isCompleted) usageCompleter.completeError(err);
          if (!finishReasonCompleter.isCompleted) {
            finishReasonCompleter.completeError(err);
          }
          if (!providerMetadataCompleter.isCompleted) {
            providerMetadataCompleter.completeError(err);
          }
          if (!finalResultCompleter.isCompleted) {
            finalResultCompleter.completeError(err);
          }
          return;
        }

        final finish = finishPart;
        if (finish == null) {
          final err =
              const GenericError('Stream finished without a finish part.');
          if (!objectCompleter.isCompleted) objectCompleter.completeError(err);
          if (!usageCompleter.isCompleted) usageCompleter.complete(null);
          if (!finishReasonCompleter.isCompleted)
            finishReasonCompleter.complete(null);
          if (!providerMetadataCompleter.isCompleted) {
            providerMetadataCompleter.complete(lastProviderMetadata);
          }
          if (!finalResultCompleter.isCompleted)
            finalResultCompleter.completeError(err);
          return;
        }

        final response = finish.response;
        final usage = finish.usage ?? response.usage;
        final finishReason = finish.finishReason ??
            (response is ChatResponseWithFinishReason
                ? response.finishReason
                : null);

        usageCompleter.complete(usage);
        finishReasonCompleter.complete(finishReason);
        providerMetadataCompleter.complete(
          response.providerMetadata ?? lastProviderMetadata,
        );

        try {
          final object = _resolveFinalObject(
            toolName: toolName,
            toolCallAgg: toolCallAgg,
            endedToolCalls: endedToolCalls,
            toolInputNames: toolInputNames,
            toolInputBuffers: toolInputBuffers,
            endedToolInputs: endedToolInputs,
            fallbackText: textBuffer.toString(),
          );

          validateObjectOrThrow(object);

          objectCompleter.complete(object);
          finalResultCompleter.complete(
            GenerateObjectResult(object: object, rawResponse: response),
          );
        } catch (e) {
          if (e is LLMError) {
            objectCompleter.completeError(e);
            finalResultCompleter.completeError(e);
            return;
          }
          final err = GenericError('Failed to parse streamed object: $e');
          objectCompleter.completeError(err);
          finalResultCompleter.completeError(err);
        }
      }
    }

    // Start pumping in a microtask so callers can subscribe before events flow.
    scheduleMicrotask(() => unawaited(pump()));

    return StreamObjectResult._(
      fullStream: fullController.stream,
      partialObjectStream: partialController.stream,
      object: objectCompleter.future,
      usage: usageCompleter.future,
      finishReason: finishReasonCompleter.future,
      providerMetadata: providerMetadataCompleter.future,
      finalResult: finalResultCompleter.future,
      done: doneCompleter.future,
    );
  }
}

class _UnhandledStreamErrorResponse implements ChatResponse {
  const _UnhandledStreamErrorResponse();

  @override
  String? get text => null;

  @override
  String? get thinking => null;

  @override
  List<ToolCall>? get toolCalls => null;

  @override
  UsageInfo? get usage => null;

  @override
  Map<String, dynamic>? get providerMetadata => null;
}

/// Stream a JSON object using a tool-call schema (AI SDK-inspired).
///
/// This uses a function tool schema (cross-provider stable) and streams the
/// provider output as `LLMStreamPart`. The final object is parsed from the tool
/// call arguments, with a text fallback that extracts the first JSON object from
/// the generated text.
StreamObjectResult streamObject({
  required ChatCapability model,
  String? system,
  String? prompt,
  List<ChatMessage>? messages,
  Prompt? promptIr,
  required ParametersSchema schema,
  String toolName = 'return_object',
  String toolDescription =
      'Return the result as a JSON object that matches the schema.',
  CancelToken? cancelToken,
}) {
  Stream<LLMStreamPart> upstream() async* {
    final input = standardizePromptInput(
      system: system,
      prompt: prompt,
      messages: messages,
      promptIr: promptIr,
    );

    final tool = Tool.function(
      name: toolName,
      description: toolDescription,
      parameters: schema,
    );

    switch (input) {
      case StandardizedChatMessages(:final messages):
        final augmentedMessages = <ChatMessage>[
          ChatMessage.system(
            'You must call the tool "$toolName" exactly once and only provide the JSON object via tool arguments.',
          ),
          ...messages,
        ];

        try {
          yield* streamChatParts(
            model: model,
            messages: augmentedMessages,
            tools: [tool],
            cancelToken: cancelToken,
          );
        } catch (e) {
          if (e is LLMError) {
            yield LLMErrorPart(e);
            return;
          }
          yield LLMErrorPart(GenericError('Unexpected error: $e'));
          return;
        }
        return;

      case StandardizedPromptIr(:final prompt):
        final augmentedPrompt = Prompt(
          messages: [
            PromptMessage.system(
              'You must call the tool "$toolName" exactly once and only provide the JSON object via tool arguments.',
            ),
            ...prompt.messages,
          ],
        );

        try {
          yield* streamChatParts(
            model: model,
            promptIr: augmentedPrompt,
            tools: [tool],
            cancelToken: cancelToken,
          );
        } catch (e) {
          if (e is LLMError) {
            yield LLMErrorPart(e);
            return;
          }
          yield LLMErrorPart(GenericError('Unexpected error: $e'));
          return;
        }
        return;
    }
  }

  return StreamObjectResult.fromPartsStream(
    upstream(),
    schema: schema,
    toolName: toolName,
  );
}

Map<String, dynamic> _resolveFinalObject({
  required String toolName,
  required ToolCallAggregator toolCallAgg,
  required Set<String> endedToolCalls,
  required Map<String, String> toolInputNames,
  required Map<String, StringBuffer> toolInputBuffers,
  required Set<String> endedToolInputs,
  required String fallbackText,
}) {
  final toolInputMatches = <String, String>{};
  for (final entry in toolInputBuffers.entries) {
    final id = entry.key;
    final name = toolInputNames[id];
    if (name != toolName) continue;
    if (endedToolInputs.isNotEmpty && !endedToolInputs.contains(id)) continue;
    toolInputMatches[id] = entry.value.toString();
  }

  if (toolInputMatches.length > 1) {
    throw InvalidRequestError('Expected exactly one "$toolName" tool call.');
  }

  if (toolInputMatches.length == 1) {
    final raw = toolInputMatches.values.single;
    final parsed = _parseRequiredJsonMap(raw, context: 'tool arguments');
    return parsed;
  }

  final toolCalls = toolCallAgg.completedCalls
      .where((c) => c.function.name == toolName)
      .toList(growable: false);

  if (toolCalls.length > 1) {
    throw InvalidRequestError('Expected exactly one "$toolName" tool call.');
  }

  if (toolCalls.length == 1) {
    final call = toolCalls.single;
    if (endedToolCalls.isNotEmpty && !endedToolCalls.contains(call.id)) {
      // Best-effort: if the provider did not emit explicit end parts, accept
      // the aggregated arguments at finish time.
    }
    final parsed = _parseRequiredJsonMap(call.function.arguments,
        context: 'tool arguments');
    return parsed;
  }

  // Text fallback (best-effort).
  final fallback = _extractFirstJsonObject(fallbackText);
  if (fallback != null) return fallback;

  throw const InvalidRequestError('No tool call and no text content to parse.');
}

Map<String, dynamic> _parseRequiredJsonMap(String raw,
    {required String context}) {
  final trimmed = raw.trim();
  final toParse = trimmed.isEmpty ? '{}' : trimmed;
  final decoded = jsonDecode(toParse);
  if (decoded is! Map) {
    throw InvalidRequestError('$context must be a JSON object (map).');
  }
  return Map<String, dynamic>.from(decoded as Map);
}

Map<String, dynamic>? _tryParseJsonObject(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return const <String, dynamic>{};

  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map) return Map<String, dynamic>.from(decoded as Map);
  } catch (_) {
    // ignore
  }

  return _extractFirstJsonObject(trimmed);
}

Map<String, dynamic>? _extractFirstJsonObject(String text) {
  final start = text.indexOf('{');
  if (start == -1) return null;

  var depth = 0;
  for (var i = start; i < text.length; i++) {
    final ch = text.codeUnitAt(i);
    if (ch == 0x7B) depth++; // {
    if (ch == 0x7D) depth--; // }
    if (depth == 0) {
      final candidate = text.substring(start, i + 1);
      try {
        final decoded = jsonDecode(candidate);
        if (decoded is Map<String, dynamic>) return decoded;
        return null;
      } catch (_) {
        return null;
      }
    }
  }
  return null;
}
