import 'package:llm_dart_core/llm_dart_core.dart';

import 'call_options_dispatch.dart';
import 'ensure_stream_start.dart';
import 'ensure_block_ids.dart';
import 'ensure_block_ends.dart';
import 'ensure_provider_metadata.dart';
import 'ensure_response_metadata.dart';
import 'ensure_single_finish.dart';
import 'prompt_input.dart';
import 'provider_tool_approval_loop.dart';
import 'types.dart';
import 'openai_tool_control.dart';

export 'package:llm_dart_core/core/stream_parts.dart';

/// Stream chat as provider-agnostic stream parts (Vercel-style).
///
/// This is a forward-compatible surface that adds block boundaries and allows
/// provider-native tools/metadata to be observed without forcing a "perfect"
/// abstraction.
Stream<LLMStreamPart> streamChatParts({
  required ChatCapability model,
  String? system,
  String? prompt,
  List<ChatMessage>? messages,
  Prompt? promptIr,
  List<Tool>? tools,
  List<ProviderTool>? providerTools,
  ToolChoice? toolChoice,
  bool? parallelToolCalls,
  ProviderToolApprovalHandler? onProviderToolApprovalRequests,
  bool stopOnProviderToolApprovalRequests = false,
  int providerToolApprovalMaxSteps = 10,
  bool waitForDeferredProviderToolResults = true,
  int maxAdditionalProviderToolResultSteps = 1,
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) async* {
  Stream<LLMStreamPart> raw() {
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

    final enableProviderToolApprovals =
        onProviderToolApprovalRequests != null ||
            stopOnProviderToolApprovalRequests;

    if (!enableProviderToolApprovals) {
      return chatStreamPartsBestEffort(
        model: model,
        input: input,
        tools: tools,
        providerTools: providerTools,
        callOptions: effectiveCallOptions,
        cancelToken: cancelToken,
      );
    }

    return streamChatPartsWithProviderToolApprovals(
      model: model,
      input: input,
      tools: tools,
      providerTools: providerTools,
      callOptions: effectiveCallOptions,
      onApprovalRequests: onProviderToolApprovalRequests,
      maxSteps: providerToolApprovalMaxSteps,
      waitForDeferredProviderToolResults: waitForDeferredProviderToolResults,
      maxAdditionalProviderToolResultSteps:
          maxAdditionalProviderToolResultSteps,
      cancelToken: cancelToken,
    );
  }

  yield* ensureStreamStartPart(
    ensureBlockEndsPart(
      ensureBlockIdsPart(
        ensureSingleFinishPart(
          ensureProviderMetadataPart(
            ensureResponseMetadataPart(
              _normalizeFinishParts(raw()),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Resume a provider tool-approval-blocked parts stream.
///
/// This is intended to pair with [ProviderToolApprovalRequiredError] emitted by
/// [streamChatParts] when `stopOnProviderToolApprovalRequests` is enabled.
Stream<LLMStreamPart> resumeChatPartsAfterProviderToolApprovalRequired({
  required ChatCapability model,
  required ProviderToolApprovalBlockedState blockedState,
  required List<ToolApprovalDecision> decisions,
  List<Tool>? tools,
  List<ProviderTool>? providerTools,
  ToolChoice? toolChoice,
  bool? parallelToolCalls,
  ProviderToolApprovalHandler? onProviderToolApprovalRequests,
  int providerToolApprovalMaxSteps = 10,
  bool waitForDeferredProviderToolResults = true,
  int maxAdditionalProviderToolResultSteps = 1,
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) async* {
  Stream<LLMStreamPart> raw() {
    final effectiveCallOptions = applyOpenAIToolControlsToCallOptions(
      callOptions,
      toolChoice: toolChoice,
      parallelToolCalls: parallelToolCalls,
    );
    return resumeChatPartsWithProviderToolApprovals(
      model: model,
      blockedState: blockedState,
      decisions: decisions,
      tools: tools,
      providerTools: providerTools,
      callOptions: effectiveCallOptions,
      onApprovalRequests: onProviderToolApprovalRequests,
      maxSteps: providerToolApprovalMaxSteps,
      waitForDeferredProviderToolResults: waitForDeferredProviderToolResults,
      maxAdditionalProviderToolResultSteps:
          maxAdditionalProviderToolResultSteps,
      cancelToken: cancelToken,
    );
  }

  yield* ensureStreamStartPart(
    ensureBlockEndsPart(
      ensureBlockIdsPart(
        ensureSingleFinishPart(
          ensureProviderMetadataPart(
            ensureResponseMetadataPart(
              _normalizeFinishParts(raw()),
            ),
          ),
        ),
      ),
    ),
  );
}

Stream<LLMStreamPart> _normalizeFinishParts(
    Stream<LLMStreamPart> upstream) async* {
  await for (final part in upstream) {
    switch (part) {
      case LLMFinishPart(
          response: final response,
          usage: final usage,
          finishReason: final finishReason,
        ):
        yield LLMFinishPart(
          response,
          usage: usage ?? response.usage,
          finishReason: finishReason ??
              (response is ChatResponseWithFinishReason
                  ? response.finishReason
                  : null),
        );
      default:
        yield part;
    }
  }
}
