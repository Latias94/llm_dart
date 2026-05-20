import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'chat_request_options.dart';
import 'chat_session.dart';
import 'chat_session_tool_support.dart';
import 'chat_state.dart';
import 'chat_tool_output_support.dart';
import 'chat_transport.dart';
import 'default_chat_session_transcript.dart';

final class DefaultChatSessionToolContinuation {
  final ChatTransportTrigger trigger;
  final ChatRequestOptions options;

  const DefaultChatSessionToolContinuation({
    required this.trigger,
    required this.options,
  });
}

final class DefaultChatSessionToolInteractionResult {
  final ChatUiMessage assistantMessage;
  final ChatStatus status;
  final DefaultChatSessionToolContinuation? continuation;
  final bool shouldScheduleAutomaticToolExecution;

  const DefaultChatSessionToolInteractionResult({
    required this.assistantMessage,
    required this.status,
    required this.continuation,
    required this.shouldScheduleAutomaticToolExecution,
  });
}

final class DefaultChatSessionToolInteractions {
  final DefaultChatSessionTranscript transcript;

  const DefaultChatSessionToolInteractions(this.transcript);

  DefaultChatSessionToolInteractionResult applyToolOutput({
    required List<ChatUiMessage> messages,
    required ToolOutputUpdate update,
  }) {
    final toolOutput = update.toolOutput;
    final assistantMessage = transcript.requireLatestAssistantMessage(messages);
    final updatedAssistantMessage = chatUpdateToolPartByCallId(
      assistantMessage,
      update.toolCallId,
      (part) => ToolUiPart(
        toolCallId: part.toolCallId,
        toolName: part.toolName,
        state: chatToolOutputState(toolOutput),
        input: part.input,
        inputText: part.inputText,
        output: update.output,
        toolOutput: toolOutput,
        errorText: toolOutput.isError
            ? chatStringifyToolOutputValue(toolOutput)
            : null,
        providerExecuted: part.providerExecuted,
        isDynamic: part.isDynamic,
        preliminary: false,
        title: part.title,
        approval: part.approval,
        callProviderMetadata: part.callProviderMetadata,
        resultProviderMetadata: part.resultProviderMetadata,
      ),
      requirePendingState: true,
    );

    transcript.appendToolOutput(update);

    final nextStatus = chatDeriveCompletionStatus(updatedAssistantMessage);
    if (nextStatus == ChatStatus.ready) {
      return DefaultChatSessionToolInteractionResult(
        assistantMessage: updatedAssistantMessage,
        status: ChatStatus.submitting,
        continuation: DefaultChatSessionToolContinuation(
          trigger: ChatTransportTrigger.toolOutput,
          options: update.options,
        ),
        shouldScheduleAutomaticToolExecution: false,
      );
    }

    return DefaultChatSessionToolInteractionResult(
      assistantMessage: updatedAssistantMessage,
      status: nextStatus,
      continuation: null,
      shouldScheduleAutomaticToolExecution: true,
    );
  }

  DefaultChatSessionToolInteractionResult applyToolApproval({
    required List<ChatUiMessage> messages,
    required ToolApprovalResponse response,
  }) {
    final assistantMessage = transcript.requireLatestAssistantMessage(messages);
    final pendingTool = chatRequirePendingApprovalToolPart(
      assistantMessage,
      response.approvalId,
    );
    final updatedAssistantMessage = chatUpdateToolPartByApprovalId(
      assistantMessage,
      response.approvalId,
      (part) => ToolUiPart(
        toolCallId: part.toolCallId,
        toolName: part.toolName,
        state: response.approved
            ? ToolUiPartState.approvalResponded
            : ToolUiPartState.outputDenied,
        input: part.input,
        inputText: part.inputText,
        output: part.output,
        toolOutput: response.approved
            ? part.toolOutput
            : ExecutionDeniedToolOutput(response.reason),
        errorText: part.errorText,
        providerExecuted: part.providerExecuted,
        isDynamic: part.isDynamic,
        preliminary: part.preliminary,
        title: part.title,
        approval: ToolApprovalUiState(
          approvalId: response.approvalId,
          approved: response.approved,
          reason: response.reason,
        ),
        callProviderMetadata: part.callProviderMetadata,
        resultProviderMetadata: part.resultProviderMetadata,
      ),
    );

    transcript.appendToolApprovalResponse(
      response: response,
      pendingTool: pendingTool,
    );

    final nextStatus = chatDeriveCompletionStatus(updatedAssistantMessage);
    if (nextStatus == ChatStatus.ready &&
        chatHasApprovedProviderExecutedTool(updatedAssistantMessage)) {
      return DefaultChatSessionToolInteractionResult(
        assistantMessage: updatedAssistantMessage,
        status: ChatStatus.submitting,
        continuation: DefaultChatSessionToolContinuation(
          trigger: ChatTransportTrigger.toolApproval,
          options: response.options,
        ),
        shouldScheduleAutomaticToolExecution: false,
      );
    }

    return DefaultChatSessionToolInteractionResult(
      assistantMessage: updatedAssistantMessage,
      status: nextStatus,
      continuation: null,
      shouldScheduleAutomaticToolExecution: true,
    );
  }
}
