import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'prompt_input.dart';
import 'prompt_message_converters.dart';
import 'provider_tool_approval_prompt.dart';
import 'types.dart';

Stream<LLMStreamPart> streamChatPartsWithProviderToolApprovals({
  required ChatCapability model,
  required StandardizedPromptInput input,
  required List<Tool>? tools,
  required LLMCallOptions callOptions,
  ProviderToolApprovalHandler? onApprovalRequests,
  int maxSteps = 10,
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
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  Prompt currentPrompt = toPrompt(input);
  var stepIndex = 0;

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
        yield LLMErrorPart(
          ProviderToolApprovalRequiredError(
            state: ProviderToolApprovalBlockedState(
              stepIndex: stepIndex,
              prompt: currentPrompt,
              approvalRequests:
                  List<LLMProviderToolApprovalRequestPart>.unmodifiable(
                approvalRequests,
              ),
              assistantText: assistantText.toString(),
              providerToolCalls:
                  List<LLMProviderToolCallPart>.unmodifiable(providerToolCalls),
            ),
          ),
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
      toolCalls: const <ToolCall>[],
      toolResults: const <ToolResult>[],
    );

    yield finishPart;
    return;
  }
}

Stream<LLMStreamPart> resumeChatPartsWithProviderToolApprovals({
  required ChatCapability model,
  required ProviderToolApprovalBlockedState blockedState,
  required List<ToolApprovalDecision> decisions,
  required List<Tool>? tools,
  required LLMCallOptions callOptions,
  ProviderToolApprovalHandler? onApprovalRequests,
  int maxSteps = 10,
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
    callOptions: callOptions,
    onApprovalRequests: onApprovalRequests,
    maxSteps: remainingSteps,
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
