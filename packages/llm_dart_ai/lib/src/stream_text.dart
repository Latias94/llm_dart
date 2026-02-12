import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'prompt_input.dart';
import 'stream_parts.dart';
import 'tool_loop.dart';
import 'tool_types.dart';
import 'tool_set.dart';
import 'types.dart';

/// A streaming text generation result (AI SDK-inspired).
///
/// This is a convenience wrapper around parts-first streaming (`LLMStreamPart`)
/// that:
/// - exposes a broadcast stream (`fullStream`) of canonical parts, and
/// - provides futures that resolve once the stream completes.
///
/// This stays intentionally Dart-flavored and does not attempt to mirror the
/// full TypeScript AI SDK surface.
class StreamTextResult {
  final Stream<LLMStreamPart> fullStream;

  /// Warnings from the model provider (e.g. unsupported settings).
  ///
  /// This is best-effort and is typically derived from the stream-start part.
  final Future<List<Map<String, dynamic>>> warnings;

  /// Stable response metadata emitted during streaming (best-effort).
  ///
  /// This is derived from [LLMResponseMetadataPart]. When step boundaries are
  /// available, this is taken from the last step.
  final Future<LLMResponseMetadataPart?> responseMetadata;

  /// Resolves to the final aggregated text from text blocks.
  final Future<String> text;

  /// Resolves to the final aggregated reasoning/thinking text, when present.
  final Future<String?> thinkingText;

  /// Resolves to the final usage snapshot, if available.
  final Future<UsageInfo?> usage;

  /// Resolves to the total usage across all steps, when step boundaries are
  /// available.
  ///
  /// For single-step streaming, this typically matches [usage].
  final Future<UsageInfo?> totalUsage;

  /// Resolves to the final finish reason, if available.
  final Future<LLMFinishReason?> finishReason;

  /// Resolves to the final providerMetadata snapshot, best-effort.
  final Future<Map<String, dynamic>?> providerMetadata;

  /// Resolves to per-step results when step boundaries are available.
  ///
  /// Tool loops can perform multiple model calls (steps). When step boundary
  /// parts are not emitted, this returns a best-effort single-step list derived
  /// from the final finish part.
  final Future<List<ToolLoopStep>> steps;

  /// Resolves to the collected source parts (URL + document).
  final Future<List<LLMStreamPart>> sources;

  /// Resolves to the collected generated file parts.
  final Future<List<LLMFilePart>> files;

  /// Resolves to the final non-streaming view of the response.
  ///
  /// This is derived from the final `LLMFinishPart` when present.
  final Future<GenerateTextResult> finalResult;

  /// Resolves when the stream completes (success or error).
  final Future<void> done;

  StreamTextResult._({
    required this.fullStream,
    required this.warnings,
    required this.responseMetadata,
    required this.text,
    required this.thinkingText,
    required this.usage,
    required this.totalUsage,
    required this.finishReason,
    required this.providerMetadata,
    required this.steps,
    required this.sources,
    required this.files,
    required this.finalResult,
    required this.done,
  });

  factory StreamTextResult.fromPartsStream(Stream<LLMStreamPart> upstream) {
    final controller = StreamController<LLMStreamPart>.broadcast(sync: true);

    final doneCompleter = Completer<void>();
    final warningsCompleter = Completer<List<Map<String, dynamic>>>();
    final responseMetadataCompleter = Completer<LLMResponseMetadataPart?>();
    final textCompleter = Completer<String>();
    final thinkingCompleter = Completer<String?>();
    final usageCompleter = Completer<UsageInfo?>();
    final totalUsageCompleter = Completer<UsageInfo?>();
    final finishReasonCompleter = Completer<LLMFinishReason?>();
    final providerMetadataCompleter = Completer<Map<String, dynamic>?>();
    final stepsCompleter = Completer<List<ToolLoopStep>>();
    final sourcesCompleter = Completer<List<LLMStreamPart>>();
    final filesCompleter = Completer<List<LLMFilePart>>();
    final finalResultCompleter = Completer<GenerateTextResult>();

    // Prevent unhandled asynchronous errors when callers choose to only consume
    // the stream (or only await a subset of futures).
    unawaited(warningsCompleter.future
        .catchError((_) => const <Map<String, dynamic>>[]));
    unawaited(responseMetadataCompleter.future.catchError((_) => null));
    unawaited(textCompleter.future.catchError((_) => ''));
    unawaited(thinkingCompleter.future.catchError((_) => null));
    unawaited(usageCompleter.future.catchError((_) => null));
    unawaited(totalUsageCompleter.future.catchError((_) => null));
    unawaited(finishReasonCompleter.future.catchError((_) => null));
    unawaited(providerMetadataCompleter.future.catchError((_) => null));
    unawaited(stepsCompleter.future.catchError((_) => const <ToolLoopStep>[]));
    unawaited(
        sourcesCompleter.future.catchError((_) => const <LLMStreamPart>[]));
    unawaited(filesCompleter.future.catchError((_) => const <LLMFilePart>[]));
    unawaited(finalResultCompleter.future.catchError(
      (_) => GenerateTextResult(
          rawResponse: const _UnhandledStreamErrorResponse()),
    ));

    final textBlocks = <String, StringBuffer>{};
    final thinkingBlocks = <String, StringBuffer>{};
    final textBlockOrder = <String>[];
    final thinkingBlockOrder = <String>[];

    final collectedSources = <LLMStreamPart>[];
    final collectedFiles = <LLMFilePart>[];
    final collectedSteps = <ToolLoopStep>[];
    UsageInfo? accumulatedUsage;

    LLMResponseMetadataPart? lastResponseMetadata;
    Map<String, dynamic>? lastProviderMetadata;
    LLMFinishPart? finishPart;
    LLMError? terminalError;

    void ensureOrder(List<String> order, String id) {
      if (!order.contains(id)) order.add(id);
    }

    String joinBlocks(List<String> order, Map<String, StringBuffer> blocks) {
      final out = StringBuffer();
      for (final id in order) {
        final buf = blocks[id];
        if (buf == null) continue;
        out.write(buf.toString());
      }
      return out.toString();
    }

    Future<void> pump() async {
      try {
        await for (final part in upstream) {
          controller.add(part);

          switch (part) {
            case LLMStreamStartPart(:final warnings):
              if (!warningsCompleter.isCompleted) {
                warningsCompleter.complete(warnings);
              }

            case LLMResponseMetadataPart():
              lastResponseMetadata = part;

            case LLMStepStartPart():
              // AI SDK semantics: `text`/`thinkingText`/`sources`/`files` are
              // derived from the *last step*.
              textBlocks.clear();
              thinkingBlocks.clear();
              textBlockOrder.clear();
              thinkingBlockOrder.clear();
              collectedSources.clear();
              collectedFiles.clear();
              lastResponseMetadata = null;
              lastProviderMetadata = null;

            case LLMTextDeltaPart(:final delta, blockId: final blockId):
              final id = (blockId == null || blockId.isEmpty) ? '1' : blockId;
              ensureOrder(textBlockOrder, id);
              (textBlocks[id] ??= StringBuffer()).write(delta);

            case LLMTextEndPart(:final text, blockId: final blockId):
              final id = (blockId == null || blockId.isEmpty) ? '1' : blockId;
              ensureOrder(textBlockOrder, id);
              final buf = (textBlocks[id] ??= StringBuffer());
              if (buf.isEmpty && text.isNotEmpty) {
                buf.write(text);
              }

            case LLMReasoningDeltaPart(:final delta, blockId: final blockId):
              final id = (blockId == null || blockId.isEmpty) ? '1' : blockId;
              ensureOrder(thinkingBlockOrder, id);
              (thinkingBlocks[id] ??= StringBuffer()).write(delta);

            case LLMReasoningEndPart(:final thinking, blockId: final blockId):
              final id = (blockId == null || blockId.isEmpty) ? '1' : blockId;
              ensureOrder(thinkingBlockOrder, id);
              final buf = (thinkingBlocks[id] ??= StringBuffer());
              if (buf.isEmpty && thinking.isNotEmpty) {
                buf.write(thinking);
              }

            case LLMSourceUrlPart():
            case LLMSourceDocumentPart():
              collectedSources.add(part);

            case LLMFilePart():
              collectedFiles.add(part);

            case LLMProviderMetadataPart(
                providerMetadata: final providerMetadata
              ):
              lastProviderMetadata = providerMetadata;

            case LLMStepFinishPart(
                stepIndex: final stepIndex,
                response: final response,
                usage: final stepUsageRaw,
                finishReason: final stepFinishReasonRaw,
                toolCalls: final toolCalls,
                toolResults: final toolResults,
              ):
              final stepUsage = stepUsageRaw ?? response.usage;
              final stepFinishReason = stepFinishReasonRaw ??
                  (response is ChatResponseWithFinishReason
                      ? response.finishReason
                      : null);

              collectedSteps.add(
                ToolLoopStep(
                  index: stepIndex,
                  result: GenerateTextResult(
                    rawResponse: response,
                    text: response.text,
                    thinking: response.thinking,
                    toolCalls: toolCalls,
                    usage: stepUsage,
                    finishReason: stepFinishReason,
                  ),
                  toolCalls: toolCalls,
                  toolResults: toolResults,
                ),
              );

              if (stepUsage != null) {
                accumulatedUsage =
                    (accumulatedUsage ?? const UsageInfo()) + stepUsage;
              }

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
        await controller.close();
        doneCompleter.complete();

        if (terminalError != null) {
          final err = terminalError!;
          if (!warningsCompleter.isCompleted) {
            warningsCompleter.completeError(err);
          }
          if (!responseMetadataCompleter.isCompleted) {
            responseMetadataCompleter.completeError(err);
          }
          if (!textCompleter.isCompleted) textCompleter.completeError(err);
          if (!thinkingCompleter.isCompleted)
            thinkingCompleter.completeError(err);
          if (!usageCompleter.isCompleted) usageCompleter.completeError(err);
          if (!totalUsageCompleter.isCompleted) {
            totalUsageCompleter.completeError(err);
          }
          if (!finishReasonCompleter.isCompleted) {
            finishReasonCompleter.completeError(err);
          }
          if (!providerMetadataCompleter.isCompleted) {
            providerMetadataCompleter.completeError(err);
          }
          if (!stepsCompleter.isCompleted) stepsCompleter.completeError(err);
          if (!sourcesCompleter.isCompleted)
            sourcesCompleter.completeError(err);
          if (!filesCompleter.isCompleted) filesCompleter.completeError(err);
          if (!finalResultCompleter.isCompleted) {
            finalResultCompleter.completeError(err);
          }
          return;
        }

        final aggregatedText = joinBlocks(textBlockOrder, textBlocks);
        final aggregatedThinking =
            joinBlocks(thinkingBlockOrder, thinkingBlocks);

        textCompleter.complete(aggregatedText);
        thinkingCompleter.complete(
          aggregatedThinking.trim().isEmpty ? null : aggregatedThinking,
        );

        sourcesCompleter
            .complete(List<LLMStreamPart>.unmodifiable(collectedSources));
        filesCompleter.complete(List<LLMFilePart>.unmodifiable(collectedFiles));

        final finish = finishPart;
        if (finish == null) {
          if (!warningsCompleter.isCompleted) {
            warningsCompleter.complete(const <Map<String, dynamic>>[]);
          }
          if (!responseMetadataCompleter.isCompleted) {
            responseMetadataCompleter.complete(lastResponseMetadata);
          }
          finalResultCompleter.completeError(
            const GenericError('Stream finished without a finish part.'),
          );
          usageCompleter.complete(null);
          totalUsageCompleter.complete(accumulatedUsage);
          finishReasonCompleter.complete(null);
          providerMetadataCompleter.complete(lastProviderMetadata);
          stepsCompleter
              .complete(List<ToolLoopStep>.unmodifiable(collectedSteps));
          return;
        }

        final response = finish.response;
        final usage = finish.usage ?? response.usage;
        final finishReason = finish.finishReason ??
            (response is ChatResponseWithFinishReason
                ? response.finishReason
                : null);

        if (!warningsCompleter.isCompleted) {
          warningsCompleter.complete(const <Map<String, dynamic>>[]);
        }
        if (!responseMetadataCompleter.isCompleted) {
          responseMetadataCompleter.complete(lastResponseMetadata);
        }

        usageCompleter.complete(usage);
        totalUsageCompleter.complete(accumulatedUsage ?? usage);
        finishReasonCompleter.complete(finishReason);

        providerMetadataCompleter.complete(
          response.providerMetadata ?? lastProviderMetadata,
        );

        if (collectedSteps.isEmpty) {
          final toolCalls = response.toolCalls ?? const <ToolCall>[];
          stepsCompleter.complete([
            ToolLoopStep(
              index: 0,
              result: GenerateTextResult(
                rawResponse: response,
                text: response.text ?? aggregatedText,
                thinking: response.thinking ??
                    (aggregatedThinking.isEmpty ? null : aggregatedThinking),
                toolCalls: toolCalls,
                usage: usage,
                finishReason: finishReason,
              ),
              toolCalls: toolCalls,
              toolResults: const [],
            ),
          ]);
        } else {
          stepsCompleter
              .complete(List<ToolLoopStep>.unmodifiable(collectedSteps));
        }

        finalResultCompleter.complete(
          GenerateTextResult(
            rawResponse: response,
            text: response.text ?? aggregatedText,
            thinking: response.thinking ??
                (aggregatedThinking.isEmpty ? null : aggregatedThinking),
            toolCalls: response.toolCalls,
            usage: usage,
            finishReason: finishReason,
          ),
        );
      }
    }

    // Start pumping in a microtask so callers can subscribe to `fullStream`
    // before the first events are forwarded (best-effort).
    scheduleMicrotask(() => unawaited(pump()));

    return StreamTextResult._(
      fullStream: controller.stream,
      warnings: warningsCompleter.future,
      responseMetadata: responseMetadataCompleter.future,
      text: textCompleter.future,
      thinkingText: thinkingCompleter.future,
      usage: usageCompleter.future,
      totalUsage: totalUsageCompleter.future,
      finishReason: finishReasonCompleter.future,
      providerMetadata: providerMetadataCompleter.future,
      steps: stepsCompleter.future,
      sources: sourcesCompleter.future,
      files: filesCompleter.future,
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

/// Stream text with optional local tool execution (AI SDK-inspired).
///
/// - If [toolSet] is provided, this runs a local tool loop and streams canonical
///   parts for the full run.
/// - Otherwise, this streams a single provider call via [streamChatParts].
///
/// This API is a convenience wrapper. The canonical streaming representation
/// remains `LLMStreamPart`.
StreamTextResult streamText({
  required ChatCapability model,
  String? system,
  String? prompt,
  List<ChatMessage>? messages,
  Prompt? promptIr,
  ToolSet? toolSet,
  List<Tool>? tools,
  ToolCallRepair? repairToolCall,
  ToolApprovalCheck? needsApproval,
  int maxSteps = 10,
  bool continueOnToolError = true,
  CancelToken? cancelToken,
}) {
  Stream<LLMStreamPart> upstream() async* {
    if (toolSet != null) {
      yield* streamToolLoopPartsWithToolSet(
        model: model,
        system: system,
        prompt: prompt,
        messages: messages,
        promptIr: promptIr,
        toolSet: toolSet,
        repairToolCall: repairToolCall,
        needsApproval: needsApproval,
        maxSteps: maxSteps,
        continueOnToolError: continueOnToolError,
        emitStepParts: true,
        cancelToken: cancelToken,
      );
      return;
    }

    final input = standardizePromptInput(
      system: system,
      prompt: prompt,
      messages: messages,
      promptIr: promptIr,
    );

    // Best-effort: avoid throwing when a model does not support parts-first streaming.
    if (input is StandardizedChatMessages &&
        model is! ChatStreamPartsCapability) {
      yield const LLMErrorPart(
        InvalidRequestError(
          'streamText requires parts-first streaming. Implement '
          '`ChatStreamPartsCapability.chatStreamParts()` (or use a provider that does).',
        ),
      );
      return;
    }

    if (input is StandardizedPromptIr &&
        model is! PromptChatStreamPartsCapability) {
      try {
        requirePromptCapabilityForFileReferenceParts(
          prompt: input.prompt,
          requiredCapabilityName: '`PromptChatStreamPartsCapability`',
        );
      } catch (e) {
        if (e is LLMError) {
          yield LLMErrorPart(e);
          return;
        }
        yield LLMErrorPart(GenericError('Invalid prompt: $e'));
        return;
      }
    }

    try {
      yield* streamChatParts(
        model: model,
        system: system,
        prompt: prompt,
        messages: messages,
        promptIr: promptIr,
        tools: tools,
        cancelToken: cancelToken,
      );
    } catch (e) {
      if (e is LLMError) {
        yield LLMErrorPart(e);
        return;
      }
      yield LLMErrorPart(GenericError('Unexpected error: $e'));
    }
  }

  return StreamTextResult.fromPartsStream(upstream());
}
