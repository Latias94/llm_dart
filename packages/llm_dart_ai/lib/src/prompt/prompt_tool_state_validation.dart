import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'prompt_tool_state_models.dart';
import 'prompt_validation_error.dart';

final class PromptToolStateValidator {
  final String context;
  final Map<String, PromptToolCallState> _seenToolCalls = {};
  final Map<String, PromptToolCallState> _pendingClientToolCalls = {};
  final Map<String, PromptApprovalState> _pendingApprovals = {};

  PromptToolStateValidator(this.context);

  void recordToolCall(
    ToolCallPromptPart part, {
    required int messageIndex,
    required int partIndex,
  }) {
    requireNonEmptyPromptField(
      part.toolCallId,
      'toolCallId',
      context: context,
      messageIndex: messageIndex,
      partIndex: partIndex,
    );
    requireNonEmptyPromptField(
      part.toolName,
      'toolName',
      context: context,
      messageIndex: messageIndex,
      partIndex: partIndex,
    );

    if (_pendingClientToolCalls.containsKey(part.toolCallId)) {
      throwPromptValidationError(
        context: context,
        messageIndex: messageIndex,
        partIndex: partIndex,
        message:
            'tool call "${part.toolCallId}" is already waiting for a tool result.',
      );
    }

    final state = PromptToolCallState(
      toolCallId: part.toolCallId,
      toolName: part.toolName,
      providerExecuted: part.providerExecuted,
      messageIndex: messageIndex,
      partIndex: partIndex,
    );
    _seenToolCalls[part.toolCallId] = state;

    if (!part.providerExecuted) {
      _pendingClientToolCalls[part.toolCallId] = state;
    }
  }

  void recordApprovalRequest(
    ToolApprovalRequestPromptPart part, {
    required int messageIndex,
    required int partIndex,
  }) {
    requireNonEmptyPromptField(
      part.approvalId,
      'approvalId',
      context: context,
      messageIndex: messageIndex,
      partIndex: partIndex,
    );
    requireNonEmptyPromptField(
      part.toolCallId,
      'toolCallId',
      context: context,
      messageIndex: messageIndex,
      partIndex: partIndex,
    );

    final toolCall = _seenToolCalls[part.toolCallId];
    if (toolCall == null) {
      throwPromptValidationError(
        context: context,
        messageIndex: messageIndex,
        partIndex: partIndex,
        message:
            'approval request "${part.approvalId}" references missing tool call '
            '"${part.toolCallId}".',
      );
    }

    if (!toolCall.providerExecuted) {
      throwPromptValidationError(
        context: context,
        messageIndex: messageIndex,
        partIndex: partIndex,
        message:
            'approval request "${part.approvalId}" references client-executed '
            'tool call "${part.toolCallId}".',
      );
    }

    if (_pendingApprovals.containsKey(part.approvalId)) {
      throwPromptValidationError(
        context: context,
        messageIndex: messageIndex,
        partIndex: partIndex,
        message:
            'approval request "${part.approvalId}" is already waiting for a '
            'response.',
      );
    }

    _pendingApprovals[part.approvalId] = PromptApprovalState(
      approvalId: part.approvalId,
      toolCallId: part.toolCallId,
      messageIndex: messageIndex,
      partIndex: partIndex,
    );
  }

  void validateAssistantToolResult(
    ToolResultPromptPart part, {
    required int messageIndex,
    required int partIndex,
  }) {
    requireNonEmptyPromptField(
      part.toolCallId,
      'toolCallId',
      context: context,
      messageIndex: messageIndex,
      partIndex: partIndex,
    );
    requireNonEmptyPromptField(
      part.toolName,
      'toolName',
      context: context,
      messageIndex: messageIndex,
      partIndex: partIndex,
    );

    final toolCall = _seenToolCalls[part.toolCallId];
    if (toolCall == null || !toolCall.providerExecuted) {
      throwPromptValidationError(
        context: context,
        messageIndex: messageIndex,
        partIndex: partIndex,
        message:
            'assistant tool results are only valid for provider-executed tool '
            'calls. Client tool results must be placed in a tool message.',
      );
    }

    requireMatchingPromptToolName(
      expected: toolCall.toolName,
      actual: part.toolName,
      context: context,
      messageIndex: messageIndex,
      partIndex: partIndex,
    );
  }

  void consumeToolResult(
    ToolResultPromptPart part, {
    required String messageToolName,
    required int messageIndex,
    required int partIndex,
  }) {
    requireNonEmptyPromptField(
      part.toolCallId,
      'toolCallId',
      context: context,
      messageIndex: messageIndex,
      partIndex: partIndex,
    );
    requireNonEmptyPromptField(
      part.toolName,
      'toolName',
      context: context,
      messageIndex: messageIndex,
      partIndex: partIndex,
    );
    requireMatchingPromptToolName(
      expected: messageToolName,
      actual: part.toolName,
      context: context,
      messageIndex: messageIndex,
      partIndex: partIndex,
    );

    final pending = _pendingClientToolCalls.remove(part.toolCallId);
    if (pending != null) {
      requireMatchingPromptToolName(
        expected: pending.toolName,
        actual: part.toolName,
        context: context,
        messageIndex: messageIndex,
        partIndex: partIndex,
      );
      return;
    }

    final toolCall = _seenToolCalls[part.toolCallId];
    if (toolCall != null && toolCall.providerExecuted) {
      requireMatchingPromptToolName(
        expected: toolCall.toolName,
        actual: part.toolName,
        context: context,
        messageIndex: messageIndex,
        partIndex: partIndex,
      );
      return;
    }

    throwPromptValidationError(
      context: context,
      messageIndex: messageIndex,
      partIndex: partIndex,
      message:
          'tool result "${part.toolCallId}" has no matching assistant tool call.',
    );
  }

  void consumeApprovalResponse(
    ToolApprovalResponsePromptPart part, {
    required int messageIndex,
    required int partIndex,
  }) {
    requireNonEmptyPromptField(
      part.approvalId,
      'approvalId',
      context: context,
      messageIndex: messageIndex,
      partIndex: partIndex,
    );
    requireNonEmptyPromptField(
      part.toolCallId,
      'toolCallId',
      context: context,
      messageIndex: messageIndex,
      partIndex: partIndex,
    );

    final pending = _pendingApprovals.remove(part.approvalId);
    if (pending == null) {
      throwPromptValidationError(
        context: context,
        messageIndex: messageIndex,
        partIndex: partIndex,
        message:
            'approval response "${part.approvalId}" has no matching assistant '
            'approval request.',
      );
    }

    if (pending.toolCallId != part.toolCallId) {
      throwPromptValidationError(
        context: context,
        messageIndex: messageIndex,
        partIndex: partIndex,
        message: 'approval response "${part.approvalId}" references tool call '
            '"${part.toolCallId}" but the request referenced '
            '"${pending.toolCallId}".',
      );
    }
  }

  void requireNoPendingBeforeNextConversationMessage(
    int messageIndex,
    String nextMessageName,
  ) {
    if (_pendingClientToolCalls.isNotEmpty) {
      final pending = _pendingClientToolCalls.values.first;
      throwPromptValidationError(
        context: context,
        messageIndex: messageIndex,
        partIndex: null,
        message:
            '$nextMessageName cannot appear before a tool message returns a '
            'result for client tool call "${pending.toolCallId}".',
      );
    }

    if (_pendingApprovals.isNotEmpty) {
      final pending = _pendingApprovals.values.first;
      throwPromptValidationError(
        context: context,
        messageIndex: messageIndex,
        partIndex: null,
        message:
            '$nextMessageName cannot appear before a tool message responds to '
            'approval request "${pending.approvalId}".',
      );
    }
  }

  void requireNoPendingAtEnd() {
    if (_pendingClientToolCalls.isNotEmpty) {
      final pending = _pendingClientToolCalls.values.first;
      throwPromptValidationError(
        context: context,
        messageIndex: pending.messageIndex,
        partIndex: pending.partIndex,
        message:
            'client tool call "${pending.toolCallId}" is missing a tool result.',
      );
    }

    if (_pendingApprovals.isNotEmpty) {
      final pending = _pendingApprovals.values.first;
      throwPromptValidationError(
        context: context,
        messageIndex: pending.messageIndex,
        partIndex: pending.partIndex,
        message:
            'approval request "${pending.approvalId}" is missing an approval '
            'response.',
      );
    }
  }
}
