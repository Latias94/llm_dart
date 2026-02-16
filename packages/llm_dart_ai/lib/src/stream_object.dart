import 'dart:async';
import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_core/utils/tool_call_aggregator.dart';

import 'generate_object.dart';
import 'prompt_input.dart';
import 'response_messages.dart';
import 'metadata_fallbacks.dart';
import 'stream_parts.dart';
import 'types.dart';
import 'openai_tool_control.dart';

enum StreamObjectOutput { object, array }

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

  /// Text stream of the JSON representation of the generated object.
  ///
  /// This is best-effort and is typically derived from streamed tool arguments.
  /// When the stream is finished, [text] should be valid JSON and can be
  /// parsed into [object].
  final Stream<String> textStream;

  /// Resolves to the final JSON text for the generated object.
  ///
  /// This is the text that was parsed into [object].
  final Future<String> text;

  /// Resolves to the final parsed object (map).
  final Future<Map<String, dynamic>> object;

  /// Resolves to the final array elements (only supported when [output] is
  /// [StreamObjectOutput.array]).
  ///
  /// In array mode, the tool arguments are parsed into a wrapper object
  /// `{ "elements": [...] }`. This future resolves to the `elements` array.
  final Future<List<Map<String, dynamic>>> elements;

  /// Stream over complete array elements (only supported when [output] is
  /// [StreamObjectOutput.array]).
  final Stream<Map<String, dynamic>> elementStream;

  /// Warnings from the model provider (e.g. unsupported settings).
  ///
  /// This is best-effort and is typically derived from the stream-start part.
  final Future<List<LLMWarning>> warnings;

  /// Stable response metadata emitted during streaming (best-effort).
  ///
  /// This is derived from [LLMResponseMetadataPart].
  final Future<LLMResponseMetadataPart?> responseMetadata;

  /// Request metadata emitted during streaming (best-effort).
  ///
  /// This is derived from [LLMRequestMetadataPart].
  final Future<LLMRequestMetadataPart?> requestMetadata;

  /// Resolves to the final usage snapshot, if available.
  final Future<UsageInfo?> usage;

  /// Resolves to the final finish reason, if available.
  final Future<LLMFinishReason?> finishReason;

  /// Resolves to the final providerMetadata snapshot, best-effort.
  final Future<Map<String, dynamic>?> providerMetadata;

  /// Resolves to the final non-streaming view of the response.
  final Future<GenerateObjectResult> finalResult;

  /// Resolves to the provider tool-approval blocked state when provider-executed
  /// tools require explicit approval and streaming stops early.
  ///
  /// This is best-effort and is populated when the upstream stream emits an
  /// [LLMProviderToolApprovalBlockedPart].
  final Future<ProviderToolApprovalBlockedState?>
      providerToolApprovalBlockedState;

  /// Resolves when the stream completes (success or error).
  final Future<void> done;

  StreamObjectResult._({
    required this.fullStream,
    required this.partialObjectStream,
    required this.textStream,
    required this.text,
    required this.object,
    required this.elements,
    required this.elementStream,
    required this.warnings,
    required this.responseMetadata,
    required this.requestMetadata,
    required this.usage,
    required this.finishReason,
    required this.providerMetadata,
    required this.finalResult,
    required this.providerToolApprovalBlockedState,
    required this.done,
  });

  factory StreamObjectResult.fromPartsStream(
    Stream<LLMStreamPart> upstream, {
    required ParametersSchema schema,
    required String toolName,
    StreamObjectOutput output = StreamObjectOutput.object,
    String? defaultModelId,
  }) {
    final startedAt = DateTime.now().toUtc();
    var currentStepStartedAt = startedAt;
    final toolSchema =
        output == StreamObjectOutput.array ? _wrapArraySchema(schema) : schema;

    final fullController =
        StreamController<LLMStreamPart>.broadcast(sync: true);
    final partialController =
        StreamController<Map<String, dynamic>>.broadcast(sync: true);
    final textController = StreamController<String>.broadcast(sync: true);
    final elementController =
        StreamController<Map<String, dynamic>>.broadcast(sync: true);

    final doneCompleter = Completer<void>();
    final warningsCompleter = Completer<List<LLMWarning>>();
    final responseMetadataCompleter = Completer<LLMResponseMetadataPart?>();
    final requestMetadataCompleter = Completer<LLMRequestMetadataPart?>();
    final textCompleter = Completer<String>();
    final objectCompleter = Completer<Map<String, dynamic>>();
    final elementsCompleter = Completer<List<Map<String, dynamic>>>();
    final usageCompleter = Completer<UsageInfo?>();
    final finishReasonCompleter = Completer<LLMFinishReason?>();
    final providerMetadataCompleter = Completer<Map<String, dynamic>?>();
    final finalResultCompleter = Completer<GenerateObjectResult>();
    final providerToolApprovalBlockedStateCompleter =
        Completer<ProviderToolApprovalBlockedState?>();

    // Prevent unhandled asynchronous errors when callers choose to only consume
    // the streams (or only await a subset of futures).
    unawaited(
      warningsCompleter.future.catchError((_) => const <LLMWarning>[]),
    );
    unawaited(responseMetadataCompleter.future.catchError((_) => null));
    unawaited(requestMetadataCompleter.future.catchError((_) => null));
    unawaited(textCompleter.future.catchError((_) => ''));
    unawaited(
        objectCompleter.future.catchError((_) => const <String, dynamic>{}));
    unawaited(elementsCompleter.future
        .catchError((_) => const <Map<String, dynamic>>[]));
    unawaited(usageCompleter.future.catchError((_) => null));
    unawaited(finishReasonCompleter.future.catchError((_) => null));
    unawaited(providerMetadataCompleter.future.catchError((_) => null));
    unawaited(providerToolApprovalBlockedStateCompleter.future
        .catchError((_) => null));
    unawaited(finalResultCompleter.future.catchError(
      (_) => GenerateObjectResult(
        object: const <String, dynamic>{},
        rawResponse: const _UnhandledStreamErrorResponse(),
      ),
    ));

    var toolCallAgg = ToolCallAggregator();
    final endedToolCalls = <String>{};

    final targetToolCallIds = <String, bool>{};
    final toolCallPreNameArgs = <String, StringBuffer>{};

    final toolInputBuffers = <String, StringBuffer>{};
    final toolInputNames = <String, String>{};
    final endedToolInputs = <String>{};
    final targetToolInputIds = <String>{};
    var hasTargetToolInputs = false;

    final textBuffer = StringBuffer();
    final objectJsonTextBuffer = StringBuffer();

    LLMResponseMetadataPart currentResponseMetadata =
        responseMetadataWithDefaults(
      null,
      currentStepStartedAt,
      defaultModelId: defaultModelId,
    );
    LLMRequestMetadataPart? lastRequestMetadata;
    Map<String, dynamic>? lastProviderMetadata;
    LLMFinishPart? finishPart;
    LLMError? terminalError;
    ProviderToolApprovalBlockedState? providerToolApprovalBlockedState;

    LLMResponseMetadataPart mergeResponseMetadata(
      LLMResponseMetadataPart base,
      LLMResponseMetadataPart update,
    ) {
      Map<String, String>? mergeHeaders(
        Map<String, String>? x,
        Map<String, String>? y,
      ) {
        if (x == null || x.isEmpty) {
          return y == null ? null : Map<String, String>.from(y);
        }
        if (y == null || y.isEmpty) {
          return Map<String, String>.from(x);
        }
        return {
          ...x,
          ...y,
        };
      }

      Map<String, dynamic>? mergeMap(
        Map<String, dynamic>? x,
        Map<String, dynamic>? y,
      ) {
        if (x == null || x.isEmpty) {
          return y == null ? null : Map<String, dynamic>.from(y);
        }
        if (y == null || y.isEmpty) {
          return Map<String, dynamic>.from(x);
        }
        return {
          ...x,
          ...y,
        };
      }

      return LLMResponseMetadataPart(
        id: update.id ?? base.id,
        timestamp: update.timestamp ?? base.timestamp,
        model: update.model ?? base.model,
        headers: mergeHeaders(base.headers, update.headers),
        body: update.body ?? base.body,
        status: update.status ?? base.status,
        systemFingerprint: update.systemFingerprint ?? base.systemFingerprint,
        providerMetadata:
            mergeMap(base.providerMetadata, update.providerMetadata),
        raw: mergeMap(base.raw, update.raw),
      );
    }

    String? lastEmittedJson;
    var publishedElements = 0;

    void emitPartialIfParsable(String raw) {
      final parsed = _tryParseJsonObject(raw);
      if (parsed == null) return;

      final normalized = output == StreamObjectOutput.array
          ? _normalizeArrayWrapperPartial(parsed, elementSchema: schema)
          : parsed;

      // Best-effort dedupe to avoid noisy re-emissions.
      try {
        final json = jsonEncode(normalized);
        if (json == lastEmittedJson) return;
        lastEmittedJson = json;
      } catch (_) {
        // Ignore JSON encoding failures; still emit.
      }

      if (output == StreamObjectOutput.array) {
        final els = _extractElements(normalized);
        if (els != null) {
          for (; publishedElements < els.length; publishedElements++) {
            elementController.add(els[publishedElements]);
          }
        }
      }

      partialController.add(normalized);
    }

    void validateObjectOrThrow(Map<String, dynamic> obj) {
      final errors = ToolValidator.validateParameters(obj, toolSchema);
      if (errors.isNotEmpty) {
        throw InvalidRequestError(
          'Generated object does not match schema: ${errors.join(', ')}',
        );
      }
    }

    Future<void> pump() async {
      try {
        await for (final part in upstream) {
          final isInternalBlockedPart =
              part is LLMProviderToolApprovalBlockedPart;
          if (!isInternalBlockedPart) {
            fullController.add(part);
          }

          switch (part) {
            case LLMStreamStartPart(:final warnings):
              if (!warningsCompleter.isCompleted) {
                warningsCompleter.complete(warnings);
              }

            case LLMResponseMetadataPart():
              currentResponseMetadata = responseMetadataWithDefaults(
                mergeResponseMetadata(currentResponseMetadata, part),
                currentStepStartedAt,
                defaultModelId: defaultModelId,
              );

            case LLMRequestMetadataPart():
              lastRequestMetadata = part;

            case LLMStepStartPart():
              // AI SDK semantics: stable result futures are derived from the
              // *last step* when step boundaries are present.
              currentStepStartedAt = DateTime.now().toUtc();
              toolCallAgg = ToolCallAggregator();
              endedToolCalls.clear();

              targetToolCallIds.clear();
              toolCallPreNameArgs.clear();

              toolInputBuffers.clear();
              toolInputNames.clear();
              endedToolInputs.clear();
              targetToolInputIds.clear();

              textBuffer.clear();
              objectJsonTextBuffer.clear();

              currentResponseMetadata = responseMetadataWithDefaults(
                null,
                currentStepStartedAt,
                defaultModelId: defaultModelId,
              );
              lastRequestMetadata = null;
              lastProviderMetadata = null;

              lastEmittedJson = null;
              publishedElements = 0;

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
              final id = aggregated.id;
              final name = aggregated.function.name;

              // AI SDK v3 semantics: prefer tool-input-* parts when available.
              // `ensureBlockEndsPart` may mirror tool-call deltas into tool-input
              // deltas; consuming both would duplicate JSON fragments.
              if (hasTargetToolInputs) {
                break;
              }

              final knownTarget = targetToolCallIds[id];
              if (knownTarget == true) {
                final delta = toolCall.function.arguments;
                if (delta.isNotEmpty) {
                  textController.add(delta);
                  objectJsonTextBuffer.write(delta);
                }
              } else if (knownTarget == null) {
                final buf =
                    toolCallPreNameArgs.putIfAbsent(id, StringBuffer.new);
                final delta = toolCall.function.arguments;
                if (delta.isNotEmpty) buf.write(delta);

                if (name.isNotEmpty) {
                  final isTarget = name == toolName;
                  targetToolCallIds[id] = isTarget;
                  if (isTarget) {
                    final flushed = buf.toString();
                    if (flushed.isNotEmpty) {
                      textController.add(flushed);
                      objectJsonTextBuffer.write(flushed);
                    }
                  }
                  toolCallPreNameArgs.remove(id);
                }
              }

              if (name == toolName) {
                emitPartialIfParsable(aggregated.function.arguments);
              }

            case LLMToolCallEndPart(:final toolCallId):
              endedToolCalls.add(toolCallId);

            case LLMToolInputStartPart(id: final id, toolName: final name):
              toolInputNames[id] = name;
              toolInputBuffers[id] = StringBuffer();
              if (name == toolName) {
                targetToolInputIds.add(id);
                hasTargetToolInputs = true;
              }

            case LLMToolInputDeltaPart(id: final id, delta: final delta):
              final buf = toolInputBuffers[id];
              if (buf == null) break;
              buf.write(delta);
              if (toolInputNames[id] == toolName) {
                emitPartialIfParsable(buf.toString());
                if (targetToolInputIds.contains(id) && delta.isNotEmpty) {
                  textController.add(delta);
                  objectJsonTextBuffer.write(delta);
                }
              }

            case LLMToolInputEndPart(id: final id):
              endedToolInputs.add(id);

            case LLMFinishPart():
              finishPart = part;

            case LLMErrorPart(error: final error):
              terminalError ??= error;

            case LLMProviderToolApprovalBlockedPart(:final state):
              if (state is ProviderToolApprovalBlockedState) {
                providerToolApprovalBlockedState ??= state;
              }

            default:
              break;
          }
        }
      } catch (e) {
        terminalError ??= GenericError('Unexpected stream error: $e');
      } finally {
        await fullController.close();
        await partialController.close();
        await textController.close();
        await elementController.close();
        doneCompleter.complete();

        if (terminalError != null) {
          final err = terminalError!;
          if (!warningsCompleter.isCompleted) {
            warningsCompleter.completeError(err);
          }
          if (!responseMetadataCompleter.isCompleted) {
            responseMetadataCompleter.completeError(err);
          }
          if (!requestMetadataCompleter.isCompleted) {
            requestMetadataCompleter.completeError(err);
          }
          if (!textCompleter.isCompleted) textCompleter.completeError(err);
          if (!objectCompleter.isCompleted) objectCompleter.completeError(err);
          if (!elementsCompleter.isCompleted) {
            elementsCompleter.completeError(err);
          }
          if (!usageCompleter.isCompleted) usageCompleter.completeError(err);
          if (!finishReasonCompleter.isCompleted) {
            finishReasonCompleter.completeError(err);
          }
          if (!providerMetadataCompleter.isCompleted) {
            providerMetadataCompleter.completeError(err);
          }
          if (!providerToolApprovalBlockedStateCompleter.isCompleted) {
            providerToolApprovalBlockedStateCompleter.completeError(err);
          }
          if (!finalResultCompleter.isCompleted) {
            finalResultCompleter.completeError(err);
          }
          return;
        }

        final finish = finishPart;
        if (finish == null) {
          final blocked = providerToolApprovalBlockedState;
          final err = blocked ??
              const GenericError('Stream finished without a finish part.');
          if (!warningsCompleter.isCompleted) {
            warningsCompleter.complete(const <LLMWarning>[]);
          }
          if (!responseMetadataCompleter.isCompleted) {
            responseMetadataCompleter.complete(
              currentResponseMetadata,
            );
          }
          if (!requestMetadataCompleter.isCompleted) {
            requestMetadataCompleter.complete(lastRequestMetadata);
          }
          if (!providerToolApprovalBlockedStateCompleter.isCompleted) {
            providerToolApprovalBlockedStateCompleter.complete(blocked);
          }

          if (blocked != null) {
            final partialText = objectJsonTextBuffer.toString();
            if (!textCompleter.isCompleted) textCompleter.complete(partialText);

            Map<String, dynamic> partialObject = const <String, dynamic>{};
            try {
              final parsed = _tryParseJsonObject(partialText);
              if (parsed != null) {
                partialObject = output == StreamObjectOutput.array
                    ? _normalizeArrayWrapperPartial(
                        parsed,
                        elementSchema: schema,
                      )
                    : parsed;
              }
            } catch (_) {
              // best-effort
            }

            if (!objectCompleter.isCompleted)
              objectCompleter.complete(
                partialObject,
              );

            if (!elementsCompleter.isCompleted) {
              if (output == StreamObjectOutput.array) {
                final els = _extractElements(partialObject);
                elementsCompleter.complete(els ?? const []);
              } else {
                elementsCompleter.completeError(
                  UnsupportedError(
                    'elements is only available when output == StreamObjectOutput.array',
                  ),
                );
              }
            }

            if (!usageCompleter.isCompleted) usageCompleter.complete(null);
            if (!finishReasonCompleter.isCompleted)
              finishReasonCompleter.complete(null);
            if (!providerMetadataCompleter.isCompleted) {
              providerMetadataCompleter.complete(lastProviderMetadata);
            }

            if (!finalResultCompleter.isCompleted) {
              final partialResponse = _PartialStreamResponse(
                text: textBuffer.toString(),
                providerMetadata: lastProviderMetadata,
              );
              finalResultCompleter.complete(
                GenerateObjectResult(
                  object: partialObject,
                  rawResponse: partialResponse,
                  requestMetadata: lastRequestMetadata,
                  responseMetadata: currentResponseMetadata,
                  responseMessages:
                      buildResponseMessagesBestEffort(partialResponse),
                  responsePromptMessages:
                      buildResponsePromptMessagesBestEffort(partialResponse),
                ),
              );
            }
          } else {
            if (!textCompleter.isCompleted) textCompleter.complete('');
            if (!objectCompleter.isCompleted)
              objectCompleter.completeError(err);
            if (!elementsCompleter.isCompleted) {
              elementsCompleter.completeError(err);
            }
            if (!usageCompleter.isCompleted) usageCompleter.complete(null);
            if (!finishReasonCompleter.isCompleted)
              finishReasonCompleter.complete(null);
            if (!providerMetadataCompleter.isCompleted) {
              providerMetadataCompleter.complete(lastProviderMetadata);
            }
            if (!finalResultCompleter.isCompleted)
              finalResultCompleter.completeError(err);
          }
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
        if (!providerToolApprovalBlockedStateCompleter.isCompleted) {
          providerToolApprovalBlockedStateCompleter
              .complete(providerToolApprovalBlockedState);
        }

        final didSeeTargetToolCall = targetToolCallIds.values.any((v) => v);
        final didSeeTargetToolInput = targetToolInputIds.isNotEmpty;
        if (finishReason?.unified == LLMUnifiedFinishReason.toolCalls &&
            !didSeeTargetToolCall &&
            !didSeeTargetToolInput) {
          // Provider-native tool flows (e.g. provider tool approvals) can
          // finish with `tool-calls` without ever producing the target
          // return_object tool call. Treat this as a blocked/partial outcome
          // rather than failing schema validation.
          if (!warningsCompleter.isCompleted) {
            warningsCompleter.complete(const <LLMWarning>[]);
          }
          if (!responseMetadataCompleter.isCompleted) {
            responseMetadataCompleter.complete(currentResponseMetadata);
          }
          if (!requestMetadataCompleter.isCompleted) {
            requestMetadataCompleter.complete(lastRequestMetadata);
          }
          if (!textCompleter.isCompleted) textCompleter.complete('');
          if (!objectCompleter.isCompleted) {
            objectCompleter.complete(const <String, dynamic>{});
          }
          if (!elementsCompleter.isCompleted) {
            if (output == StreamObjectOutput.array) {
              elementsCompleter.complete(const []);
            } else {
              elementsCompleter.completeError(
                UnsupportedError(
                  'elements is only available when output == StreamObjectOutput.array',
                ),
              );
            }
          }
          if (!finalResultCompleter.isCompleted) {
            finalResultCompleter.complete(
              GenerateObjectResult(
                object: const <String, dynamic>{},
                rawResponse: response,
                requestMetadata: lastRequestMetadata,
                responseMetadata: currentResponseMetadata,
                responseMessages: buildResponseMessagesBestEffort(response),
                responsePromptMessages:
                    buildResponsePromptMessagesBestEffort(response),
              ),
            );
          }
          return;
        }

        try {
          final resolved = _resolveFinalObjectAndText(
            toolName: toolName,
            toolCallAgg: toolCallAgg,
            endedToolCalls: endedToolCalls,
            toolInputNames: toolInputNames,
            toolInputBuffers: toolInputBuffers,
            endedToolInputs: endedToolInputs,
            fallbackText: textBuffer.toString(),
            output: output,
          );

          validateObjectOrThrow(resolved.object);

          if (!warningsCompleter.isCompleted) {
            warningsCompleter.complete(const <LLMWarning>[]);
          }
          if (!responseMetadataCompleter.isCompleted) {
            responseMetadataCompleter.complete(currentResponseMetadata);
          }
          if (!requestMetadataCompleter.isCompleted) {
            requestMetadataCompleter.complete(lastRequestMetadata);
          }
          textCompleter.complete(resolved.text);
          objectCompleter.complete(resolved.object);

          if (output == StreamObjectOutput.array) {
            final els = _extractElements(resolved.object);
            if (els == null) {
              throw const InvalidRequestError(
                'Array output requires an "elements" array in the generated object.',
              );
            }
            elementsCompleter.complete(els);
          } else {
            elementsCompleter.completeError(
              UnsupportedError(
                'elements is only available when output == StreamObjectOutput.array',
              ),
            );
          }

          finalResultCompleter.complete(
            GenerateObjectResult(
              object: resolved.object,
              rawResponse: response,
              requestMetadata: lastRequestMetadata,
              responseMetadata: currentResponseMetadata,
              responseMessages: buildResponseMessagesBestEffort(response),
              responsePromptMessages: buildResponsePromptMessagesBestEffort(
                response,
              ),
            ),
          );
        } catch (e) {
          final err = e is LLMError
              ? e
              : GenericError('Failed to parse streamed object: $e');
          if (!warningsCompleter.isCompleted) {
            warningsCompleter.complete(const <LLMWarning>[]);
          }
          if (!responseMetadataCompleter.isCompleted) {
            responseMetadataCompleter.complete(
              currentResponseMetadata,
            );
          }
          if (!requestMetadataCompleter.isCompleted) {
            requestMetadataCompleter.complete(lastRequestMetadata);
          }
          if (!textCompleter.isCompleted) textCompleter.completeError(err);
          if (!objectCompleter.isCompleted) objectCompleter.completeError(err);
          if (!elementsCompleter.isCompleted) {
            elementsCompleter.completeError(err);
          }
          if (!finalResultCompleter.isCompleted) {
            finalResultCompleter.completeError(err);
          }
        }
      }
    }

    // Start pumping in a microtask so callers can subscribe before events flow.
    scheduleMicrotask(() => unawaited(pump()));

    return StreamObjectResult._(
      fullStream: fullController.stream,
      partialObjectStream: partialController.stream,
      textStream: textController.stream,
      text: textCompleter.future,
      object: objectCompleter.future,
      elements: elementsCompleter.future,
      elementStream: output == StreamObjectOutput.array
          ? elementController.stream
          : Stream<Map<String, dynamic>>.error(
              UnsupportedError(
                'elementStream is only available when output == StreamObjectOutput.array',
              ),
            ),
      warnings: warningsCompleter.future,
      responseMetadata: responseMetadataCompleter.future,
      requestMetadata: requestMetadataCompleter.future,
      usage: usageCompleter.future,
      finishReason: finishReasonCompleter.future,
      providerMetadata: providerMetadataCompleter.future,
      finalResult: finalResultCompleter.future,
      providerToolApprovalBlockedState:
          providerToolApprovalBlockedStateCompleter.future,
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

class _PartialStreamResponse implements ChatResponse {
  @override
  final String? text;

  @override
  String? get thinking => null;

  @override
  List<ToolCall>? get toolCalls => null;

  @override
  UsageInfo? get usage => null;

  @override
  final Map<String, dynamic>? providerMetadata;

  const _PartialStreamResponse({this.text, this.providerMetadata});
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
  StreamObjectOutput output = StreamObjectOutput.object,
  String toolName = 'return_object',
  String toolDescription =
      'Return the result as a JSON object that matches the schema.',
  List<ProviderTool>? providerTools,
  ToolChoice? toolChoice,
  bool? parallelToolCalls,
  ProviderToolApprovalHandler? onProviderToolApprovalRequests,
  bool stopOnProviderToolApprovalRequests = false,
  int providerToolApprovalMaxSteps = 10,
  bool waitForDeferredProviderToolResults = true,
  int maxAdditionalProviderToolResultSteps = 1,
  IncludeOptions include = const IncludeOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) {
  Stream<LLMStreamPart> upstream() async* {
    final effectiveCallOptions = applyOpenAIToolControlsToCallOptions(
      callOptions,
      toolChoice: toolChoice,
      parallelToolCalls: parallelToolCalls,
    );
    final input = standardizePromptInput(
      system: system,
      prompt: prompt,
      messages: messages,
      promptIr: promptIr,
    );

    final tool = Tool.function(
      name: toolName,
      description: toolDescription,
      parameters: output == StreamObjectOutput.array
          ? _wrapArraySchema(schema)
          : schema,
    );

    switch (input) {
      case StandardizedChatMessages(:final messages):
        final augmentedMessages = <ChatMessage>[
          ChatMessage.system(
            output == StreamObjectOutput.array
                ? 'You must call the tool "$toolName" exactly once and only provide the JSON result via tool arguments. The arguments must be a JSON object with a single key "elements" whose value is an array of JSON objects matching the element schema.'
                : 'You must call the tool "$toolName" exactly once and only provide the JSON object via tool arguments.',
          ),
          ...messages,
        ];

        try {
          yield* streamPartsWithInclude(
            streamChatParts(
              model: model,
              messages: augmentedMessages,
              tools: [tool],
              providerTools: providerTools,
              toolChoice: toolChoice,
              parallelToolCalls: parallelToolCalls,
              onProviderToolApprovalRequests: onProviderToolApprovalRequests,
              stopOnProviderToolApprovalRequests:
                  stopOnProviderToolApprovalRequests,
              providerToolApprovalMaxSteps: providerToolApprovalMaxSteps,
              waitForDeferredProviderToolResults:
                  waitForDeferredProviderToolResults,
              maxAdditionalProviderToolResultSteps:
                  maxAdditionalProviderToolResultSteps,
              callOptions: effectiveCallOptions,
              cancelToken: cancelToken,
            ),
            include,
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
              output == StreamObjectOutput.array
                  ? 'You must call the tool "$toolName" exactly once and only provide the JSON result via tool arguments. The arguments must be a JSON object with a single key "elements" whose value is an array of JSON objects matching the element schema.'
                  : 'You must call the tool "$toolName" exactly once and only provide the JSON object via tool arguments.',
            ),
            ...prompt.messages,
          ],
        );

        try {
          yield* streamPartsWithInclude(
            streamChatParts(
              model: model,
              promptIr: augmentedPrompt,
              tools: [tool],
              providerTools: providerTools,
              toolChoice: toolChoice,
              parallelToolCalls: parallelToolCalls,
              onProviderToolApprovalRequests: onProviderToolApprovalRequests,
              stopOnProviderToolApprovalRequests:
                  stopOnProviderToolApprovalRequests,
              providerToolApprovalMaxSteps: providerToolApprovalMaxSteps,
              waitForDeferredProviderToolResults:
                  waitForDeferredProviderToolResults,
              maxAdditionalProviderToolResultSteps:
                  maxAdditionalProviderToolResultSteps,
              callOptions: effectiveCallOptions,
              cancelToken: cancelToken,
            ),
            include,
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
    output: output,
    defaultModelId: model is ModelIdentityCapability
        ? (model as ModelIdentityCapability).modelId
        : null,
  );
}

/// Resume a `streamObject` run that finished because a provider-executed tool
/// required explicit approval.
///
/// This is intended to pair with [StreamObjectResult.providerToolApprovalBlockedState]
/// when `stopOnProviderToolApprovalRequests` was enabled.
StreamObjectResult resumeStreamObjectAfterProviderToolApprovalBlocked({
  required ChatCapability model,
  required ProviderToolApprovalBlockedState blockedState,
  required List<ToolApprovalDecision> decisions,
  required ParametersSchema schema,
  StreamObjectOutput output = StreamObjectOutput.object,
  String toolName = 'return_object',
  String toolDescription =
      'Return the result as a JSON object that matches the schema.',
  List<ProviderTool>? providerTools,
  ToolChoice? toolChoice,
  bool? parallelToolCalls,
  int providerToolApprovalMaxSteps = 10,
  bool waitForDeferredProviderToolResults = true,
  int maxAdditionalProviderToolResultSteps = 1,
  IncludeOptions include = const IncludeOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) {
  Stream<LLMStreamPart> upstream() async* {
    final effectiveCallOptions = applyOpenAIToolControlsToCallOptions(
      callOptions,
      toolChoice: toolChoice,
      parallelToolCalls: parallelToolCalls,
    );
    final tool = Tool.function(
      name: toolName,
      description: toolDescription,
      parameters: output == StreamObjectOutput.array
          ? _wrapArraySchema(schema)
          : schema,
    );

    try {
      yield* streamPartsWithInclude(
        resumeChatPartsAfterProviderToolApprovalRequired(
          model: model,
          blockedState: blockedState,
          decisions: decisions,
          tools: [tool],
          providerTools: providerTools,
          toolChoice: toolChoice,
          parallelToolCalls: parallelToolCalls,
          providerToolApprovalMaxSteps: providerToolApprovalMaxSteps,
          waitForDeferredProviderToolResults:
              waitForDeferredProviderToolResults,
          maxAdditionalProviderToolResultSteps:
              maxAdditionalProviderToolResultSteps,
          callOptions: effectiveCallOptions,
          cancelToken: cancelToken,
        ),
        include,
      );
    } catch (e) {
      if (e is LLMError) {
        yield LLMErrorPart(e);
        return;
      }
      yield LLMErrorPart(GenericError('Unexpected error: $e'));
      return;
    }
  }

  return StreamObjectResult.fromPartsStream(
    upstream(),
    schema: schema,
    toolName: toolName,
    output: output,
    defaultModelId: model is ModelIdentityCapability
        ? (model as ModelIdentityCapability).modelId
        : null,
  );
}

({String text, Map<String, dynamic> object}) _resolveFinalObjectAndText({
  required String toolName,
  required ToolCallAggregator toolCallAgg,
  required Set<String> endedToolCalls,
  required Map<String, String> toolInputNames,
  required Map<String, StringBuffer> toolInputBuffers,
  required Set<String> endedToolInputs,
  required String fallbackText,
  required StreamObjectOutput output,
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
    return (text: raw.trim(), object: parsed);
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
    return (text: call.function.arguments.trim(), object: parsed);
  }

  // Text fallback (best-effort).
  final fallback = _extractFirstJsonObject(fallbackText);
  if (fallback != null) return (text: jsonEncode(fallback), object: fallback);

  if (output == StreamObjectOutput.array) {
    final fallbackArray = _extractFirstJsonArray(fallbackText);
    if (fallbackArray != null) {
      final wrapped = <String, dynamic>{'elements': fallbackArray};
      return (text: jsonEncode(wrapped), object: wrapped);
    }
  }

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

ParametersSchema _wrapArraySchema(ParametersSchema elementSchema) {
  final elementProperty = ParameterProperty(
    propertyType: 'object',
    description: 'Array element',
    properties: elementSchema.properties,
    required: elementSchema.required,
  );

  return ParametersSchema(
    schemaType: 'object',
    properties: {
      'elements': ParameterProperty(
        propertyType: 'array',
        description: 'Array elements',
        items: elementProperty,
      ),
    },
    required: const ['elements'],
  );
}

Map<String, dynamic> _normalizeArrayWrapperPartial(
  Map<String, dynamic> obj, {
  required ParametersSchema elementSchema,
}) {
  final elementsRaw = obj['elements'];
  if (elementsRaw is! List) return obj;

  final normalized = <Map<String, dynamic>>[];
  for (final el in elementsRaw) {
    if (el is! Map<String, dynamic>) break;

    final errors = ToolValidator.validateParameters(el, elementSchema);
    if (errors.isNotEmpty) break;

    normalized.add(el);
  }

  return {'elements': normalized};
}

List<Map<String, dynamic>>? _extractElements(Map<String, dynamic> obj) {
  final raw = obj['elements'];
  if (raw is! List) return null;

  final out = <Map<String, dynamic>>[];
  for (final el in raw) {
    if (el is! Map<String, dynamic>) return null;
    out.add(el);
  }
  return out;
}

List<dynamic>? _extractFirstJsonArray(String text) {
  final start = text.indexOf('[');
  if (start == -1) return null;

  var depth = 0;
  for (var i = start; i < text.length; i++) {
    final ch = text.codeUnitAt(i);
    if (ch == 0x5B) depth++; // [
    if (ch == 0x5D) depth--; // ]
    if (depth == 0) {
      final candidate = text.substring(start, i + 1);
      try {
        final decoded = jsonDecode(candidate);
        if (decoded is List) return decoded;
        return null;
      } catch (_) {
        return null;
      }
    }
  }
  return null;
}
