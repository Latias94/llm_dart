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
  required ProviderToolApprovalHandler onApprovalRequests,
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

Prompt _appendProviderApprovalStepToPrompt(
  Prompt base, {
  required String assistantText,
  required List<LLMProviderToolCallPart> providerToolCalls,
  required List<ToolApprovalDecision> decisions,
}) =>
    appendProviderToolApprovalsToPrompt(
      base,
      assistantText: assistantText,
      providerToolCalls: providerToolCalls,
      decisions: decisions,
    );
