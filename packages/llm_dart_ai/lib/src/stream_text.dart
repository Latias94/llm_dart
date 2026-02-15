import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'content_part.dart';
import 'prompt_input.dart';
import 'stream_parts.dart';
import 'tool_loop.dart';
import 'tool_types.dart';
import 'tool_set.dart';
import 'response_messages.dart';
import 'metadata_fallbacks.dart';
import 'types.dart';

typedef StreamTextOnStepFinishCallback = FutureOr<void> Function(
  ToolLoopStep step,
);

class StreamTextFinishEvent {
  final GenerateTextResult result;
  final List<ToolLoopStep> steps;
  final UsageInfo? totalUsage;

  const StreamTextFinishEvent({
    required this.result,
    required this.steps,
    required this.totalUsage,
  });
}

typedef StreamTextOnFinishCallback = FutureOr<void> Function(
  StreamTextFinishEvent event,
);

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

  /// Content parts produced in the last step (AI SDK-style).
  ///
  /// Automatically consumes the stream.
  final Future<List<ContentPart>> content;

  /// Text-only stream (AI SDK-style).
  ///
  /// This yields the deltas from `text-delta` parts.
  Stream<String> get textStream => fullStream
      .where((part) => part is LLMTextDeltaPart)
      .cast<LLMTextDeltaPart>()
      .map((p) => p.delta);

  /// Reasoning-only stream (AI SDK-style).
  ///
  /// This yields the deltas from `reasoning-delta` parts.
  Stream<String> get reasoningStream => fullStream
      .where((part) => part is LLMReasoningDeltaPart)
      .cast<LLMReasoningDeltaPart>()
      .map((p) => p.delta);

  /// Warnings from the model provider (e.g. unsupported settings).
  ///
  /// This is best-effort and is typically derived from the stream-start part.
  final Future<List<Map<String, dynamic>>> warnings;

  /// Stable response metadata emitted during streaming (best-effort).
  ///
  /// This is derived from [LLMResponseMetadataPart]. When step boundaries are
  /// available, this is taken from the last step.
  final Future<LLMResponseMetadataPart?> responseMetadata;

  /// Request metadata (best-effort).
  ///
  /// This is derived from [LLMRequestMetadataPart]. When step boundaries are
  /// available, this is taken from the last step.
  final Future<LLMRequestMetadataPart?> requestMetadata;

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

  /// Resolves to the tool-loop blocked state when local tool approval is needed.
  ///
  /// This is best-effort and is populated when the upstream stream emits
  /// an [LLMToolLoopBlockedPart].
  final Future<ToolLoopBlockedState?> toolLoopBlockedState;

  /// Resolves to the provider tool-approval blocked state when provider-executed
  /// tools require explicit approval and streaming stops early.
  ///
  /// This is best-effort and is populated when the upstream stream emits
  /// an [LLMProviderToolApprovalBlockedPart].
  final Future<ProviderToolApprovalBlockedState?>
      providerToolApprovalBlockedState;

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
    required this.content,
    required this.warnings,
    required this.responseMetadata,
    required this.requestMetadata,
    required this.text,
    required this.thinkingText,
    required this.usage,
    required this.totalUsage,
    required this.finishReason,
    required this.providerMetadata,
    required this.steps,
    required this.toolLoopBlockedState,
    required this.providerToolApprovalBlockedState,
    required this.sources,
    required this.files,
    required this.finalResult,
    required this.done,
  });

  factory StreamTextResult.fromPartsStream(
    Stream<LLMStreamPart> upstream, {
    String? defaultModelId,
    StreamTextOnStepFinishCallback? onStepFinish,
    StreamTextOnFinishCallback? onFinish,
  }) {
    final startedAt = DateTime.now().toUtc();
    var currentStepStartedAt = startedAt;
    var contentCollector = _StepContentCollector();
    final controller = StreamController<LLMStreamPart>.broadcast(sync: true);

    final doneCompleter = Completer<void>();
    final warningsCompleter = Completer<List<Map<String, dynamic>>>();
    final responseMetadataCompleter = Completer<LLMResponseMetadataPart?>();
    final requestMetadataCompleter = Completer<LLMRequestMetadataPart?>();
    final textCompleter = Completer<String>();
    final thinkingCompleter = Completer<String?>();
    final usageCompleter = Completer<UsageInfo?>();
    final totalUsageCompleter = Completer<UsageInfo?>();
    final finishReasonCompleter = Completer<LLMFinishReason?>();
    final providerMetadataCompleter = Completer<Map<String, dynamic>?>();
    final stepsCompleter = Completer<List<ToolLoopStep>>();
    final toolLoopBlockedStateCompleter = Completer<ToolLoopBlockedState?>();
    final providerToolApprovalBlockedStateCompleter =
        Completer<ProviderToolApprovalBlockedState?>();
    final sourcesCompleter = Completer<List<LLMStreamPart>>();
    final filesCompleter = Completer<List<LLMFilePart>>();
    final finalResultCompleter = Completer<GenerateTextResult>();

    // Prevent unhandled asynchronous errors when callers choose to only consume
    // the stream (or only await a subset of futures).
    final contentFuture = finalResultCompleter.future.then((r) => r.content);
    unawaited(contentFuture.catchError((_) => const <ContentPart>[]));
    unawaited(warningsCompleter.future
        .catchError((_) => const <Map<String, dynamic>>[]));
    unawaited(responseMetadataCompleter.future.catchError((_) => null));
    unawaited(requestMetadataCompleter.future.catchError((_) => null));
    unawaited(textCompleter.future.catchError((_) => ''));
    unawaited(thinkingCompleter.future.catchError((_) => null));
    unawaited(usageCompleter.future.catchError((_) => null));
    unawaited(totalUsageCompleter.future.catchError((_) => null));
    unawaited(finishReasonCompleter.future.catchError((_) => null));
    unawaited(providerMetadataCompleter.future.catchError((_) => null));
    unawaited(stepsCompleter.future.catchError((_) => const <ToolLoopStep>[]));
    unawaited(toolLoopBlockedStateCompleter.future.catchError((_) => null));
    unawaited(
      providerToolApprovalBlockedStateCompleter.future.catchError((_) => null),
    );
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
    List<ContentPart>? lastStepContent;

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
    ToolApprovalRequiredError? approvalRequired;
    ProviderToolApprovalRequiredError? providerApprovalRequired;
    ToolLoopBlockedState? toolLoopBlockedState;
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
          if (part is LLMStepStartPart) {
            // AI SDK semantics: `content` is derived from the last step.
            contentCollector = _StepContentCollector();
          }
          contentCollector.onPart(part);
          final isInternalBlockedPart = part is LLMToolLoopBlockedPart ||
              part is LLMProviderToolApprovalBlockedPart;
          if (!isInternalBlockedPart) controller.add(part);

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
              // AI SDK semantics: `text`/`thinkingText`/`sources`/`files` are
              // derived from the *last step*.
              currentStepStartedAt = DateTime.now().toUtc();
              textBlocks.clear();
              thinkingBlocks.clear();
              textBlockOrder.clear();
              thinkingBlockOrder.clear();
              collectedSources.clear();
              collectedFiles.clear();
              currentResponseMetadata = responseMetadataWithDefaults(
                null,
                currentStepStartedAt,
                defaultModelId: defaultModelId,
              );
              lastRequestMetadata = null;
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
              final stepContent = contentCollector.finalize(
                toolCalls: toolCalls,
                toolResults: toolResults,
                fallbackText: response.text,
                fallbackReasoning: response.thinking,
              );
              lastStepContent = stepContent;

              final stepUsage = stepUsageRaw ?? response.usage;
              final stepFinishReason = stepFinishReasonRaw ??
                  (response is ChatResponseWithFinishReason
                      ? response.finishReason
                      : null);
              final stepResponseMetadata = currentResponseMetadata;
              final stepAssistantPromptMessages =
                  buildResponsePromptMessagesBestEffort(response);
              final stepResponsePromptMessages = toolResults.isNotEmpty
                  ? [
                      ...stepAssistantPromptMessages,
                      buildToolResultPromptMessageBestEffort(
                        toolCalls: toolCalls,
                        toolResults: toolResults,
                      ),
                    ]
                  : stepAssistantPromptMessages;

              collectedSteps.add(
                ToolLoopStep(
                  index: stepIndex,
                  result: GenerateTextResult(
                    rawResponse: response,
                    content: stepContent,
                    text: response.text,
                    thinking: response.thinking,
                    toolCalls: toolCalls,
                    toolResults: toolResults,
                    usage: stepUsage,
                    finishReason: stepFinishReason,
                    requestMetadata: lastRequestMetadata,
                    responseMetadata: stepResponseMetadata,
                    responseMessages: buildResponseMessagesBestEffort(response),
                    responsePromptMessages: stepAssistantPromptMessages,
                    sources: List<LLMStreamPart>.unmodifiable(collectedSources),
                    files: List<LLMFilePart>.unmodifiable(collectedFiles),
                  ),
                  toolCalls: toolCalls,
                  toolResults: toolResults,
                  responseMetadata: stepResponseMetadata,
                  requestMetadata: lastRequestMetadata,
                  responsePromptMessages: stepResponsePromptMessages,
                ),
              );

              final stepFinishCallback = onStepFinish;
              if (stepFinishCallback != null) {
                final step = collectedSteps.last;
                unawaited(
                  Future.sync(() => stepFinishCallback(step))
                      .catchError((_) {}),
                );
              }

              if (stepUsage != null) {
                accumulatedUsage =
                    (accumulatedUsage ?? const UsageInfo()) + stepUsage;
              }

            case LLMFinishPart():
              finishPart = part;

            case LLMErrorPart(error: final error):
              if (error is ToolApprovalRequiredError) {
                approvalRequired ??= error;
              } else if (error is ProviderToolApprovalRequiredError) {
                providerApprovalRequired ??= error;
              } else {
                terminalError ??= error;
              }

            case LLMToolLoopBlockedPart(:final state):
              if (state is ToolLoopBlockedState) {
                toolLoopBlockedState ??= state;
              }

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
          if (!requestMetadataCompleter.isCompleted) {
            requestMetadataCompleter.completeError(err);
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
          if (!toolLoopBlockedStateCompleter.isCompleted) {
            toolLoopBlockedStateCompleter.completeError(err);
          }
          if (!providerToolApprovalBlockedStateCompleter.isCompleted) {
            providerToolApprovalBlockedStateCompleter.completeError(err);
          }
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
            responseMetadataCompleter.complete(currentResponseMetadata);
          }
          if (!requestMetadataCompleter.isCompleted) {
            requestMetadataCompleter.complete(lastRequestMetadata);
          }
          final blocked = approvalRequired;
          final providerBlocked = providerApprovalRequired;
          if (blocked != null) {
            // Tool approval required: treat as a structured blocked outcome
            // rather than a hard error, similar to AI SDK tool approval requests.
            finalResultCompleter.complete(blocked.state.stepResult);
            if (!toolLoopBlockedStateCompleter.isCompleted) {
              toolLoopBlockedStateCompleter.complete(blocked.state);
            }
            if (!providerToolApprovalBlockedStateCompleter.isCompleted) {
              providerToolApprovalBlockedStateCompleter.complete(null);
            }
          } else if (providerBlocked != null) {
            // Provider tool approval required: treat as a structured blocked
            // outcome (no finish part is available).
            final partialThinking =
                aggregatedThinking.trim().isEmpty ? null : aggregatedThinking;
            final partialResponse = _PartialStreamResponse(
              text: aggregatedText,
              thinking: partialThinking,
              providerMetadata: lastProviderMetadata,
            );
            final partialContent = contentCollector.finalize(
              toolCalls: const <ToolCall>[],
              toolResults: const <ToolResult>[],
              fallbackText: aggregatedText,
              fallbackReasoning:
                  aggregatedThinking.trim().isEmpty ? null : aggregatedThinking,
            );
            finalResultCompleter.complete(
              GenerateTextResult(
                rawResponse: partialResponse,
                content: partialContent,
                text: aggregatedText,
                thinking: partialThinking,
                toolCalls: null,
                usage: null,
                finishReason: null,
                requestMetadata: lastRequestMetadata,
                responseMetadata: currentResponseMetadata,
                responseMessages:
                    buildResponseMessagesBestEffort(partialResponse),
                responsePromptMessages:
                    buildResponsePromptMessagesBestEffort(partialResponse),
                sources: List<LLMStreamPart>.unmodifiable(collectedSources),
                files: List<LLMFilePart>.unmodifiable(collectedFiles),
              ),
            );
            if (!toolLoopBlockedStateCompleter.isCompleted) {
              toolLoopBlockedStateCompleter.complete(null);
            }
            if (!providerToolApprovalBlockedStateCompleter.isCompleted) {
              providerToolApprovalBlockedStateCompleter
                  .complete(providerBlocked.state);
            }
          } else {
            finalResultCompleter.completeError(
              const GenericError('Stream finished without a finish part.'),
            );
            if (!toolLoopBlockedStateCompleter.isCompleted) {
              toolLoopBlockedStateCompleter.complete(toolLoopBlockedState);
            }
            if (!providerToolApprovalBlockedStateCompleter.isCompleted) {
              providerToolApprovalBlockedStateCompleter
                  .complete(providerToolApprovalBlockedState);
            }
          }
          usageCompleter.complete(null);
          totalUsageCompleter.complete(accumulatedUsage);
          finishReasonCompleter.complete(null);
          providerMetadataCompleter.complete(lastProviderMetadata);
          stepsCompleter
              .complete(List<ToolLoopStep>.unmodifiable(collectedSteps));
          if (!toolLoopBlockedStateCompleter.isCompleted) {
            toolLoopBlockedStateCompleter.complete(toolLoopBlockedState);
          }
          if (!providerToolApprovalBlockedStateCompleter.isCompleted) {
            providerToolApprovalBlockedStateCompleter
                .complete(providerToolApprovalBlockedState);
          }
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
          responseMetadataCompleter.complete(currentResponseMetadata);
        }
        if (!requestMetadataCompleter.isCompleted) {
          requestMetadataCompleter.complete(lastRequestMetadata);
        }

        usageCompleter.complete(usage);
        totalUsageCompleter.complete(accumulatedUsage ?? usage);
        finishReasonCompleter.complete(finishReason);

        providerMetadataCompleter.complete(
          response.providerMetadata ?? lastProviderMetadata,
        );

        late final List<ToolLoopStep> stepsSnapshot;
        if (collectedSteps.isEmpty) {
          final toolCalls = response.toolCalls ?? const <ToolCall>[];
          final responseMetadata = currentResponseMetadata;
          final content = contentCollector.finalize(
            toolCalls: toolCalls,
            toolResults: const <ToolResult>[],
            fallbackText: response.text ?? aggregatedText,
            fallbackReasoning: response.thinking ??
                (aggregatedThinking.isEmpty ? null : aggregatedThinking),
          );
          lastStepContent = content;
          stepsSnapshot = List<ToolLoopStep>.unmodifiable([
            ToolLoopStep(
              index: 0,
              result: GenerateTextResult(
                rawResponse: response,
                content: content,
                text: response.text ?? aggregatedText,
                thinking: response.thinking ??
                    (aggregatedThinking.isEmpty ? null : aggregatedThinking),
                toolCalls: toolCalls,
                toolResults: const <ToolResult>[],
                usage: usage,
                finishReason: finishReason,
                requestMetadata: lastRequestMetadata,
                responseMetadata: responseMetadata,
                responseMessages: buildResponseMessagesBestEffort(response),
                responsePromptMessages:
                    buildResponsePromptMessagesBestEffort(response),
                sources: List<LLMStreamPart>.unmodifiable(collectedSources),
                files: List<LLMFilePart>.unmodifiable(collectedFiles),
              ),
              toolCalls: toolCalls,
              toolResults: const [],
              responseMetadata: responseMetadata,
              requestMetadata: lastRequestMetadata,
              responsePromptMessages:
                  buildResponsePromptMessagesBestEffort(response),
            ),
          ]);
          stepsCompleter.complete(stepsSnapshot);
        } else {
          stepsSnapshot = List<ToolLoopStep>.unmodifiable(collectedSteps);
          stepsCompleter.complete(stepsSnapshot);
        }

        if (!toolLoopBlockedStateCompleter.isCompleted) {
          toolLoopBlockedStateCompleter.complete(toolLoopBlockedState);
        }
        if (!providerToolApprovalBlockedStateCompleter.isCompleted) {
          providerToolApprovalBlockedStateCompleter
              .complete(providerToolApprovalBlockedState);
        }

        final totalUsage = accumulatedUsage ?? usage;
        final lastToolResults = stepsSnapshot.isEmpty
            ? const <ToolResult>[]
            : stepsSnapshot.last.toolResults;
        final content = lastStepContent ??
            contentCollector.finalize(
              toolCalls: response.toolCalls ?? const <ToolCall>[],
              toolResults: lastToolResults,
              fallbackText: response.text ?? aggregatedText,
              fallbackReasoning: response.thinking ??
                  (aggregatedThinking.isEmpty ? null : aggregatedThinking),
            );

        final finalResult = GenerateTextResult(
          rawResponse: response,
          content: content,
          text: response.text ?? aggregatedText,
          thinking: response.thinking ??
              (aggregatedThinking.isEmpty ? null : aggregatedThinking),
          toolCalls: response.toolCalls,
          toolResults: lastToolResults,
          usage: usage,
          totalUsage: totalUsage,
          finishReason: finishReason,
          requestMetadata: lastRequestMetadata,
          responseMetadata: currentResponseMetadata,
          responseMessages: buildResponseMessagesBestEffort(response),
          responsePromptMessages: buildResponsePromptMessagesBestEffort(
            response,
          ),
          steps: stepsSnapshot,
          sources: List<LLMStreamPart>.unmodifiable(collectedSources),
          files: List<LLMFilePart>.unmodifiable(collectedFiles),
        );
        finalResultCompleter.complete(finalResult);

        final finishCallback = onFinish;
        if (finishCallback != null) {
          final event = StreamTextFinishEvent(
            result: finalResult,
            steps: stepsSnapshot,
            totalUsage: totalUsage,
          );
          unawaited(
            Future.sync(() => finishCallback(event)).catchError((_) {}),
          );
        }
      }
    }

    // Start pumping in a microtask so callers can subscribe to `fullStream`
    // before the first events are forwarded (best-effort).
    scheduleMicrotask(() => unawaited(pump()));

    return StreamTextResult._(
      fullStream: controller.stream,
      content: contentFuture,
      warnings: warningsCompleter.future,
      responseMetadata: responseMetadataCompleter.future,
      requestMetadata: requestMetadataCompleter.future,
      text: textCompleter.future,
      thinkingText: thinkingCompleter.future,
      usage: usageCompleter.future,
      totalUsage: totalUsageCompleter.future,
      finishReason: finishReasonCompleter.future,
      providerMetadata: providerMetadataCompleter.future,
      steps: stepsCompleter.future,
      toolLoopBlockedState: toolLoopBlockedStateCompleter.future,
      providerToolApprovalBlockedState:
          providerToolApprovalBlockedStateCompleter.future,
      sources: sourcesCompleter.future,
      files: filesCompleter.future,
      finalResult: finalResultCompleter.future,
      done: doneCompleter.future,
    );
  }
}

class _StepContentCollector {
  final List<ContentPart> _parts = <ContentPart>[];

  final ToolCallAggregator _toolCallAggregator = ToolCallAggregator();
  final Map<String, ToolCall> _toolCallsById = <String, ToolCall>{};
  final Set<String> _emittedToolCallIds = <String>{};

  final Map<String, StringBuffer> _textBlocks = <String, StringBuffer>{};
  final List<String> _textOrder = <String>[];
  final Map<String, StringBuffer> _reasoningBlocks = <String, StringBuffer>{};
  final List<String> _reasoningOrder = <String>[];

  final Set<String> _providerToolCallIds = <String>{};

  void _ensureOrder(List<String> order, String id) {
    if (!order.contains(id)) order.add(id);
  }

  String _blockId(String? id) => (id == null || id.isEmpty) ? '1' : id;

  String _joinBlocks(List<String> order, Map<String, StringBuffer> blocks) {
    final out = StringBuffer();
    for (final id in order) {
      final buf = blocks[id];
      if (buf == null) continue;
      out.write(buf.toString());
    }
    return out.toString();
  }

  bool _hasTextPart(List<ContentPart> parts) =>
      parts.any((p) => p is TextContentPart);

  bool _hasReasoningPart(List<ContentPart> parts) =>
      parts.any((p) => p is ReasoningContentPart);

  void onPart(LLMStreamPart part) {
    switch (part) {
      case LLMTextDeltaPart(:final delta, blockId: final blockId):
        final id = _blockId(blockId);
        _ensureOrder(_textOrder, id);
        (_textBlocks[id] ??= StringBuffer()).write(delta);
        return;

      case LLMTextEndPart(
          :final text,
          blockId: final blockId,
          :final providerMetadata,
        ):
        // Track best-effort text even when providers don't emit deltas.
        final id = _blockId(blockId);
        _ensureOrder(_textOrder, id);
        final buf = (_textBlocks[id] ??= StringBuffer());
        if (buf.isEmpty && text.isNotEmpty) buf.write(text);
        _parts.add(TextContentPart(text, providerMetadata: providerMetadata));
        return;

      case LLMReasoningDeltaPart(:final delta, blockId: final blockId):
        final id = _blockId(blockId);
        _ensureOrder(_reasoningOrder, id);
        (_reasoningBlocks[id] ??= StringBuffer()).write(delta);
        return;

      case LLMReasoningEndPart(
          :final thinking,
          blockId: final blockId,
          :final providerMetadata,
        ):
        final id = _blockId(blockId);
        _ensureOrder(_reasoningOrder, id);
        final buf = (_reasoningBlocks[id] ??= StringBuffer());
        if (buf.isEmpty && thinking.isNotEmpty) buf.write(thinking);
        _parts.add(
          ReasoningContentPart(thinking, providerMetadata: providerMetadata),
        );
        return;

      case LLMSourceUrlPart():
        _parts.add(
          SourceUrlContentPart(
            sourceId: part.sourceId,
            url: part.url,
            title: part.title,
            providerMetadata: part.providerMetadata,
          ),
        );
        return;

      case LLMSourceDocumentPart():
        _parts.add(
          SourceDocumentContentPart(
            sourceId: part.sourceId,
            mediaType: part.mediaType,
            title: part.title,
            filename: part.filename,
            providerMetadata: part.providerMetadata,
          ),
        );
        return;

      case LLMFilePart():
        _parts.add(FileContentPart(part));
        return;

      case LLMToolCallStartPart(:final toolCall):
      case LLMToolCallDeltaPart(:final toolCall):
        final merged = _toolCallAggregator.addDelta(toolCall);
        _toolCallsById[merged.id] = merged;
        return;

      case LLMToolCallEndPart(:final toolCallId):
        _emitToolCallIfPossible(toolCallId);
        return;

      case LLMToolResultPart(:final result):
        _parts.add(
          result.isError
              ? ToolErrorContentPart(result)
              : ToolResultContentPart(result),
        );
        return;

      case LLMProviderToolCallPart(
          :final toolCallId,
          :final toolName,
          :final input,
          :final providerExecuted,
          :final isDynamic,
          :final providerMetadata,
        ):
        _providerToolCallIds.add(toolCallId);
        _parts.add(
          ProviderToolCallContentPart(
            toolCallId: toolCallId,
            toolName: toolName,
            input: input,
            providerExecuted: providerExecuted,
            isDynamic: isDynamic,
            providerMetadata: providerMetadata,
          ),
        );
        return;

      case LLMProviderToolResultPart(
          :final toolCallId,
          :final toolName,
          :final result,
          :final isError,
          :final preliminary,
          :final isDynamic,
          :final providerMetadata,
        ):
        if (!_providerToolCallIds.contains(toolCallId)) {
          _providerToolCallIds.add(toolCallId);
          _parts.add(
            ProviderToolCallContentPart(
              toolCallId: toolCallId,
              toolName: toolName,
              input: null,
              providerExecuted: true,
              isDynamic: isDynamic,
              providerMetadata: null,
            ),
          );
        }
        if (isError == true) {
          _parts.add(
            ProviderToolErrorContentPart(
              toolCallId: toolCallId,
              toolName: toolName,
              error: result,
              preliminary: preliminary,
              isDynamic: isDynamic,
              providerMetadata: providerMetadata,
            ),
          );
        } else {
          _parts.add(
            ProviderToolResultContentPart(
              toolCallId: toolCallId,
              toolName: toolName,
              result: result,
              preliminary: preliminary,
              isDynamic: isDynamic,
              providerMetadata: providerMetadata,
            ),
          );
        }
        return;

      case LLMProviderToolDeltaPart(
          :final toolCallId,
          :final toolName,
          :final status,
          :final data,
          :final providerMetadata,
        ):
        _providerToolCallIds.add(toolCallId);
        _parts.add(
          ProviderToolDeltaContentPart(
            toolCallId: toolCallId,
            toolName: toolName,
            status: status,
            data: data,
            providerMetadata: providerMetadata,
          ),
        );
        return;

      case LLMProviderToolApprovalRequestPart(
          :final approvalId,
          :final toolCallId,
          :final toolName,
          :final input,
          :final providerMetadata,
        ):
        _providerToolCallIds.add(toolCallId);
        final localToolCall = _toolCallsById[toolCallId];
        if (localToolCall != null &&
            localToolCall.callType.trim().toLowerCase() == 'function' &&
            localToolCall.function.name.trim().isNotEmpty) {
          _parts.add(
            ToolApprovalRequestContentPart(
              approvalId: approvalId,
              toolCall: localToolCall,
            ),
          );
        } else {
          _parts.add(
            ProviderToolApprovalRequestContentPart(
              approvalId: approvalId,
              toolCallId: toolCallId,
              toolName: toolName,
              input: input,
              providerMetadata: providerMetadata,
            ),
          );
        }
        return;

      default:
        return;
    }
  }

  void _emitToolCallIfPossible(String toolCallId) {
    final id = toolCallId.trim();
    if (id.isEmpty) return;
    if (_emittedToolCallIds.contains(id)) return;

    final call = _toolCallsById[id];
    if (call == null) return;
    if (call.function.name.trim().isEmpty) return;

    _emittedToolCallIds.add(id);
    _parts.add(ToolCallContentPart(call));
  }

  bool _hasToolCallPart(List<ContentPart> parts, String toolCallId) {
    for (final p in parts) {
      if (p is ToolCallContentPart && p.toolCall.id == toolCallId) return true;
    }
    return false;
  }

  int _indexOfToolResultPart(List<ContentPart> parts, String toolCallId) {
    for (var i = 0; i < parts.length; i++) {
      final p = parts[i];
      if (p is ToolResultContentPart && p.toolResult.toolCallId == toolCallId) {
        return i;
      }
      if (p is ToolErrorContentPart && p.toolResult.toolCallId == toolCallId) {
        return i;
      }
    }
    return -1;
  }

  bool _hasToolResultPart(List<ContentPart> parts, String toolCallId) {
    return _indexOfToolResultPart(parts, toolCallId) != -1;
  }

  /// Finalize the current step content, ensuring tool calls/results exist.
  ///
  /// This is used for both single-step streams (no step boundary parts) and for
  /// tool-loop steps (using [LLMStepFinishPart.toolCalls]/[toolResults]).
  List<ContentPart> finalize({
    required List<ToolCall> toolCalls,
    List<ToolResult> toolResults = const <ToolResult>[],
    String? fallbackText,
    String? fallbackReasoning,
  }) {
    final out = List<ContentPart>.from(_parts);

    if (!_hasReasoningPart(out)) {
      final reasoning = _joinBlocks(_reasoningOrder, _reasoningBlocks);
      final effectiveReasoning =
          reasoning.trim().isNotEmpty ? reasoning : (fallbackReasoning ?? '');
      if (effectiveReasoning.trim().isNotEmpty) {
        out.insert(0, ReasoningContentPart(effectiveReasoning));
      }
    }

    if (!_hasTextPart(out)) {
      final text = _joinBlocks(_textOrder, _textBlocks);
      final effectiveText = text.isNotEmpty ? text : (fallbackText ?? '');
      if (effectiveText.isNotEmpty) {
        final insertAt =
            out.isNotEmpty && out.first is ReasoningContentPart ? 1 : 0;
        out.insert(insertAt, TextContentPart(effectiveText));
      }
    }

    for (final r in toolResults) {
      if (_hasToolResultPart(out, r.toolCallId)) continue;
      out.add(r.isError ? ToolErrorContentPart(r) : ToolResultContentPart(r));
    }

    for (final c in toolCalls) {
      if (_hasToolCallPart(out, c.id)) continue;
      final idx = _indexOfToolResultPart(out, c.id);
      final callPart = ToolCallContentPart(c);
      if (idx == -1) {
        out.add(callPart);
      } else {
        out.insert(idx, callPart);
      }
    }

    return List<ContentPart>.unmodifiable(out);
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
  final String? thinking;

  @override
  final List<ToolCall>? toolCalls;

  @override
  final UsageInfo? usage;

  @override
  final Map<String, dynamic>? providerMetadata;

  const _PartialStreamResponse({
    this.text,
    this.thinking,
    this.toolCalls,
    this.usage,
    this.providerMetadata,
  });
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
  ProviderToolApprovalHandler? onProviderToolApprovalRequests,
  bool stopOnProviderToolApprovalRequests = false,
  int providerToolApprovalMaxSteps = 10,
  bool waitForDeferredProviderToolResults = true,
  int maxAdditionalProviderToolResultSteps = 1,
  int maxSteps = 10,
  bool continueOnToolError = true,
  bool includeRawChunks = false,
  StreamTextOnStepFinishCallback? onStepFinish,
  StreamTextOnFinishCallback? onFinish,
  IncludeOptions include = const IncludeOptions(),
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) {
  final effectiveCallOptions = defaultCallOptions.mergedWith(callOptions);

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
        include: include,
        callOptions: effectiveCallOptions,
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
    if (input is StandardizedChatMessages) {
      final supportsStreaming = (onProviderToolApprovalRequests != null ||
              stopOnProviderToolApprovalRequests)
          ? (effectiveCallOptions.isEmpty
              ? model is PromptChatStreamPartsCapability
              : model is PromptChatStreamPartsCallOptionsCapability)
          : (effectiveCallOptions.isEmpty
              ? model is ChatStreamPartsCapability
              : model is ChatStreamPartsCallOptionsCapability);
      if (!supportsStreaming) {
        yield LLMErrorPart(
          InvalidRequestError(
            onProviderToolApprovalRequests != null
                ? (effectiveCallOptions.isEmpty
                    ? 'streamText with provider tool approvals requires prompt-native parts-first streaming. '
                        'Implement `PromptChatStreamPartsCapability.chatPromptStreamParts()` (or use a provider that does).'
                    : 'streamText with provider tool approvals requires prompt-native parts-first streaming with call-level overrides. '
                        'Implement `PromptChatStreamPartsCallOptionsCapability.chatPromptStreamPartsWithCallOptions()` (or use a provider that does).')
                : (effectiveCallOptions.isEmpty
                    ? 'streamText requires parts-first streaming. Implement '
                        '`ChatStreamPartsCapability.chatStreamParts()` (or use a provider that does).'
                    : 'streamText requires parts-first streaming with call-level overrides. Implement '
                        '`ChatStreamPartsCallOptionsCapability.chatStreamPartsWithCallOptions()` (or use a provider that does).'),
          ),
        );
        return;
      }
    }

    if (input is StandardizedPromptIr &&
        (effectiveCallOptions.isEmpty
            ? model is! PromptChatStreamPartsCapability
            : model is! PromptChatStreamPartsCallOptionsCapability)) {
      try {
        requirePromptCapabilityForFileReferenceParts(
          prompt: input.prompt,
          requiredCapabilityName: effectiveCallOptions.isEmpty
              ? '`PromptChatStreamPartsCapability`'
              : '`PromptChatStreamPartsCallOptionsCapability`',
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
      yield* streamPartsWithInclude(
        streamChatParts(
          model: model,
          system: system,
          prompt: prompt,
          messages: messages,
          promptIr: promptIr,
          tools: tools,
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
    }
  }

  final defaultModelId = model is ModelIdentityCapability
      ? (model as ModelIdentityCapability).modelId
      : null;

  Stream<LLMStreamPart> filteredUpstream() {
    if (includeRawChunks) return upstream();
    return upstream().where((part) => part is! LLMRawPart);
  }

  return StreamTextResult.fromPartsStream(
    filteredUpstream(),
    defaultModelId: defaultModelId,
    onStepFinish: onStepFinish,
    onFinish: onFinish,
  );
}

/// Resume a tool-loop `streamText` run that finished because tool approval was required.
///
/// This executes locally executable tool calls according to [approvals], then
/// continues streaming from the updated message/prompt history.
Future<StreamTextResult> resumeStreamTextAfterToolApprovalBlocked({
  required ChatCapability model,
  required ToolLoopBlockedState blockedState,
  required List<ToolApprovalDecision> approvals,
  required ToolSet toolSet,
  ToolCallRepair? repairToolCall,
  ToolApprovalCheck? needsApproval,
  ProviderToolApprovalHandler? onProviderToolApprovalRequests,
  bool stopOnProviderToolApprovalRequests = false,
  int providerToolApprovalMaxSteps = 10,
  bool waitForDeferredProviderToolResults = true,
  int maxAdditionalProviderToolResultSteps = 1,
  int maxSteps = 10,
  bool continueOnToolError = true,
  bool includeRawChunks = false,
  StreamTextOnStepFinishCallback? onStepFinish,
  StreamTextOnFinishCallback? onFinish,
  IncludeOptions include = const IncludeOptions(),
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) async {
  final applied = await applyToolApprovalsToBlockedState(
    blockedState: blockedState,
    approvals: approvals,
    tools: toolSet.tools,
    toolHandlers: toolSet.handlers,
    repairToolCall: repairToolCall,
    continueOnToolError: continueOnToolError,
    cancelToken: cancelToken,
  );

  final Prompt? promptIr = applied.prompt;
  final List<ChatMessage> messages = applied.messages;

  return streamText(
    model: model,
    messages: promptIr == null ? messages : null,
    promptIr: promptIr,
    toolSet: toolSet,
    repairToolCall: repairToolCall,
    needsApproval: needsApproval,
    onProviderToolApprovalRequests: onProviderToolApprovalRequests,
    stopOnProviderToolApprovalRequests: stopOnProviderToolApprovalRequests,
    providerToolApprovalMaxSteps: providerToolApprovalMaxSteps,
    waitForDeferredProviderToolResults: waitForDeferredProviderToolResults,
    maxAdditionalProviderToolResultSteps: maxAdditionalProviderToolResultSteps,
    maxSteps: maxSteps,
    continueOnToolError: continueOnToolError,
    includeRawChunks: includeRawChunks,
    onStepFinish: onStepFinish,
    onFinish: onFinish,
    include: include,
    defaultCallOptions: defaultCallOptions,
    callOptions: callOptions,
    cancelToken: cancelToken,
  );
}

/// Resume a `streamText` run that finished because a provider-executed tool
/// required explicit approval.
///
/// This is intended to pair with [StreamTextResult.providerToolApprovalBlockedState]
/// when `stopOnProviderToolApprovalRequests` was enabled.
StreamTextResult resumeStreamTextAfterProviderToolApprovalBlocked({
  required ChatCapability model,
  required ProviderToolApprovalBlockedState blockedState,
  required List<ToolApprovalDecision> decisions,
  List<Tool>? tools,
  ProviderToolApprovalHandler? onProviderToolApprovalRequests,
  int providerToolApprovalMaxSteps = 10,
  bool waitForDeferredProviderToolResults = true,
  int maxAdditionalProviderToolResultSteps = 1,
  bool includeRawChunks = false,
  StreamTextOnStepFinishCallback? onStepFinish,
  StreamTextOnFinishCallback? onFinish,
  IncludeOptions include = const IncludeOptions(),
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) {
  final effectiveCallOptions = defaultCallOptions.mergedWith(callOptions);

  Stream<LLMStreamPart> upstream() async* {
    try {
      yield* streamPartsWithInclude(
        resumeChatPartsAfterProviderToolApprovalRequired(
          model: model,
          blockedState: blockedState,
          decisions: decisions,
          tools: tools,
          onProviderToolApprovalRequests: onProviderToolApprovalRequests,
          providerToolApprovalMaxSteps: providerToolApprovalMaxSteps,
          waitForDeferredProviderToolResults: waitForDeferredProviderToolResults,
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
    }
  }

  final defaultModelId = model is ModelIdentityCapability
      ? (model as ModelIdentityCapability).modelId
      : null;

  Stream<LLMStreamPart> filteredUpstream() {
    if (includeRawChunks) return upstream();
    return upstream().where((part) => part is! LLMRawPart);
  }

  return StreamTextResult.fromPartsStream(
    filteredUpstream(),
    defaultModelId: defaultModelId,
    onStepFinish: onStepFinish,
    onFinish: onFinish,
  );
}
