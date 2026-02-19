import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'prompt_input.dart';
import 'prompt_message_converters.dart';
import 'provider_tool_approval_prompt.dart';
import 'types.dart';

class _ProviderToolApprovalBlockedResponse extends ChatResponse {
  @override
  final String? text;

  _ProviderToolApprovalBlockedResponse({this.text});

  @override
  String? get thinking => null;

  @override
  List<ToolCall>? get toolCalls => null;

  @override
  UsageInfo? get usage => null;

  @override
  Map<String, dynamic>? get providerMetadata => null;
}

Stream<LLMStreamPart> streamChatPartsWithProviderToolApprovals({
  required ChatCapability model,
  required StandardizedPromptInput input,
  required List<Tool>? tools,
  List<ProviderTool>? providerTools,
  required LLMCallOptions callOptions,
  ProviderToolApprovalHandler? onApprovalRequests,
  int maxSteps = 10,
  bool waitForDeferredProviderToolResults = true,
  int maxAdditionalProviderToolResultSteps = 1,
  CancelToken? cancelToken,
}) async* {
  if (maxSteps < 1) {
    throw const InvalidRequestError('maxSteps must be >= 1.');
  }

  Prompt toPrompt(StandardizedPromptInput i) {
    return switch (i) {
      StandardizedPromptIr(:final prompt) => prompt,
      StandardizedChatMessages(:final messages) => promptFromChatMessages(
          messages,
        ),
    };
  }

  Stream<LLMStreamPart> promptStream(Prompt prompt) {
    if (callOptions.isEmpty) {
      if (model is! PromptChatStreamPartsCapability) {
        throw const InvalidRequestError(
          'Provider tool approvals require prompt-native streaming. '
          'Implement `PromptChatStreamPartsCapability` (or use a provider that does).',
        );
      }
      return (model as PromptChatStreamPartsCapability).chatPromptStreamParts(
        prompt,
        tools: tools,
        providerTools: providerTools,
        cancelToken: cancelToken,
      );
    }

    if (model is! PromptChatStreamPartsCallOptionsCapability) {
      throw const InvalidRequestError(
        'Provider tool approvals require prompt-native streaming with call-level overrides. '
        'Implement `PromptChatStreamPartsCallOptionsCapability` (or use a provider that does).',
      );
    }

    return (model as PromptChatStreamPartsCallOptionsCapability)
        .chatPromptStreamPartsWithCallOptions(
      prompt,
      tools: tools,
      providerTools: providerTools,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  Prompt currentPrompt = toPrompt(input);
  var stepIndex = 0;
  final pendingProviderToolCallFirstStep = <String, int>{};

  while (true) {
    if (cancelToken?.isCancelled == true) {
      throw CancelledError(
          cancelToken?.reason?.toString() ?? 'Request cancelled');
    }

    if (stepIndex >= maxSteps) {
      throw InvalidRequestError('Exceeded maxSteps ($maxSteps).');
    }

    yield LLMStepStartPart(stepIndex);

    final approvalRequests = <LLMProviderToolApprovalRequestPart>[];
    final assistantText = StringBuffer();
    final providerToolCalls = <LLMProviderToolCallPart>[];
    final providerToolResults = <LLMProviderToolResultPart>[];

    LLMFinishPart? finishPart;
    var blocked = false;

    final iterator = StreamIterator(promptStream(currentPrompt));
    try {
      while (await iterator.moveNext()) {
        final part = iterator.current;

        switch (part) {
          case LLMStreamStartPart():
            continue;

          case LLMProviderToolCallPart():
            providerToolCalls.add(part);
            if (waitForDeferredProviderToolResults &&
                part.toolCallId.trim().isNotEmpty &&
                part.providerExecuted != false &&
                part.supportsDeferredResults == true) {
              pendingProviderToolCallFirstStep.putIfAbsent(
                part.toolCallId,
                () => stepIndex,
              );
            }
            yield part;
            continue;

          case LLMProviderToolResultPart(:final toolCallId, :final preliminary):
            providerToolResults.add(part);
            if (toolCallId.trim().isNotEmpty && preliminary != true) {
              pendingProviderToolCallFirstStep.remove(toolCallId);
            }
            yield part;
            continue;

          case LLMProviderToolApprovalRequestPart():
            approvalRequests.add(part);
            yield part;
            blocked = true;
            // Collect any immediately following approval requests before stopping.
            while (await iterator.moveNext()) {
              final next = iterator.current;
              if (next is LLMProviderToolApprovalRequestPart) {
                approvalRequests.add(next);
                yield next;
                continue;
              }
              if (next is LLMFinishPart) {
                finishPart = next;
              }
              break;
            }
            break;

          case LLMTextDeltaPart(:final delta):
            assistantText.write(delta);
            yield part;
            continue;

          case LLMFinishPart():
            finishPart = part;
            break;

          default:
            yield part;
            continue;
        }

        break;
      }
    } finally {
      await iterator.cancel();
    }

    if (blocked) {
      if (onApprovalRequests == null) {
        final blockedState = ProviderToolApprovalBlockedState(
          stepIndex: stepIndex,
          prompt: currentPrompt,
          approvalRequests:
              List<LLMProviderToolApprovalRequestPart>.unmodifiable(
            approvalRequests,
          ),
          assistantText: assistantText.toString(),
          providerToolCalls:
              List<LLMProviderToolCallPart>.unmodifiable(providerToolCalls),
        );

        // AI SDK parity: treat tool approval as a structured finish rather than
        // a terminal error when stopOnProviderToolApprovalRequests is enabled.
        yield LLMProviderToolApprovalBlockedPart(blockedState);

        final response = finishPart?.response ??
            _ProviderToolApprovalBlockedResponse(
                text: assistantText.toString());
        final usage = finishPart?.usage ?? response.usage;
        final toolCallsReason = const LLMFinishReason(
          unified: LLMUnifiedFinishReason.toolCalls,
          raw: null,
        );

        yield LLMStepFinishPart(
          stepIndex: stepIndex,
          response: response,
          usage: usage,
          finishReason: toolCallsReason,
          toolCalls: const <V3ToolCall>[],
          toolResults: const <ToolResult>[],
        );

        yield LLMFinishPart(
          response,
          usage: usage,
          finishReason: toolCallsReason,
        );
        return;
      }

      final decisions = await onApprovalRequests(
        List<LLMProviderToolApprovalRequestPart>.unmodifiable(approvalRequests),
      );

      final byId = <String, ToolApprovalDecision>{};
      for (final d in decisions) {
        byId[d.approvalId] = d;
      }

      for (final req in approvalRequests) {
        if (!byId.containsKey(req.approvalId)) {
          throw InvalidRequestError(
            'Missing ToolApprovalDecision for approvalId="${req.approvalId}".',
          );
        }
      }

      currentPrompt = _appendProviderApprovalStepToPrompt(
        currentPrompt,
        assistantText: assistantText.toString(),
        providerToolCalls: providerToolCalls,
        approvalRequests: approvalRequests,
        decisions: approvalRequests.map((r) => byId[r.approvalId]!).toList(
              growable: false,
            ),
      );

      stepIndex++;
      continue;
    }

    if (finishPart == null) {
      throw const GenericError(
        'Provider stream ended without finish and without tool approval request.',
      );
    }

    final response = finishPart.response;
    yield LLMStepFinishPart(
      stepIndex: stepIndex,
      response: response,
      usage: finishPart.usage ?? response.usage,
      finishReason: finishPart.finishReason ??
          (response is ChatResponseWithFinishReason
              ? response.finishReason
              : null),
      toolCalls: const <V3ToolCall>[],
      toolResults: const <ToolResult>[],
    );

    if (waitForDeferredProviderToolResults &&
        pendingProviderToolCallFirstStep.isNotEmpty &&
        maxAdditionalProviderToolResultSteps > 0) {
      pendingProviderToolCallFirstStep.removeWhere(
        (_, firstStep) =>
            (stepIndex - firstStep) >= maxAdditionalProviderToolResultSteps,
      );

      if (pendingProviderToolCallFirstStep.isNotEmpty) {
        currentPrompt = appendProviderToolStepToPrompt(
          currentPrompt,
          assistantText: assistantText.toString(),
          providerToolCalls: providerToolCalls,
          providerToolResults: providerToolResults,
        );
        stepIndex++;
        continue;
      }
    }

    yield finishPart;
    return;
  }
}

Stream<LLMStreamPart> resumeChatPartsWithProviderToolApprovals({
  required ChatCapability model,
  required ProviderToolApprovalBlockedState blockedState,
  required List<ToolApprovalDecision> decisions,
  required List<Tool>? tools,
  List<ProviderTool>? providerTools,
  required LLMCallOptions callOptions,
  ProviderToolApprovalHandler? onApprovalRequests,
  int maxSteps = 10,
  bool waitForDeferredProviderToolResults = true,
  int maxAdditionalProviderToolResultSteps = 1,
  CancelToken? cancelToken,
}) async* {
  final remainingSteps = maxSteps - (blockedState.stepIndex + 1);
  if (remainingSteps < 1) {
    throw InvalidRequestError(
      'Cannot resume provider tool approvals at stepIndex=${blockedState.stepIndex} '
      'because maxSteps ($maxSteps) would be exceeded.',
    );
  }

  final byId = <String, ToolApprovalDecision>{};
  for (final d in decisions) {
    byId[d.approvalId] = d;
  }

  for (final req in blockedState.approvalRequests) {
    if (!byId.containsKey(req.approvalId)) {
      throw InvalidRequestError(
        'Missing ToolApprovalDecision for approvalId="${req.approvalId}".',
      );
    }
  }

  final nextPrompt = _appendProviderApprovalStepToPrompt(
    blockedState.prompt,
    assistantText: blockedState.assistantText,
    providerToolCalls: blockedState.providerToolCalls,
    approvalRequests: blockedState.approvalRequests,
    decisions: blockedState.approvalRequests
        .map((r) => byId[r.approvalId]!)
        .toList(growable: false),
  );

  final input = StandardizedPromptIr(nextPrompt);
  yield* streamChatPartsWithProviderToolApprovals(
    model: model,
    input: input,
    tools: tools,
    providerTools: providerTools,
    callOptions: callOptions,
    onApprovalRequests: onApprovalRequests,
    maxSteps: remainingSteps,
    waitForDeferredProviderToolResults: waitForDeferredProviderToolResults,
    maxAdditionalProviderToolResultSteps: maxAdditionalProviderToolResultSteps,
    cancelToken: cancelToken,
  ).map((part) {
    // Ensure step numbering continues from the blocked step.
    if (part is LLMStepStartPart) {
      return LLMStepStartPart(blockedState.stepIndex + part.stepIndex + 1);
    }
    if (part is LLMStepFinishPart) {
      return LLMStepFinishPart(
        stepIndex: blockedState.stepIndex + part.stepIndex + 1,
        response: part.response,
        usage: part.usage,
        finishReason: part.finishReason,
        toolCalls: part.toolCalls,
        toolResults: part.toolResults,
      );
    }
    if (part is LLMErrorPart &&
        part.error is ProviderToolApprovalRequiredError) {
      final err = part.error as ProviderToolApprovalRequiredError;
      final state = err.state;
      return LLMErrorPart(
        ProviderToolApprovalRequiredError(
          state: ProviderToolApprovalBlockedState(
            stepIndex: blockedState.stepIndex + state.stepIndex + 1,
            prompt: state.prompt,
            approvalRequests: state.approvalRequests,
            assistantText: state.assistantText,
            providerToolCalls: state.providerToolCalls,
          ),
          message: err.message,
        ),
      );
    }
    return part;
  });
}

Prompt _appendProviderApprovalStepToPrompt(
  Prompt base, {
  required String assistantText,
  required List<LLMProviderToolCallPart> providerToolCalls,
  required List<LLMProviderToolApprovalRequestPart> approvalRequests,
  required List<ToolApprovalDecision> decisions,
}) =>
    appendProviderToolApprovalsToPrompt(
      base,
      assistantText: assistantText,
      providerToolCalls: providerToolCalls,
      approvalRequests: approvalRequests,
      decisions: decisions,
    );
