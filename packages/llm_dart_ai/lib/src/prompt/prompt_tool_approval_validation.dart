import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'prompt_tool_state_models.dart';
import 'prompt_tool_state_tracker.dart';
import 'prompt_validation_error.dart';

final class PromptToolApprovalValidator {
  final String context;
  final PromptToolStateTracker tracker;

  const PromptToolApprovalValidator({
    required this.context,
    required this.tracker,
  });

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

    final toolCall = tracker.seenToolCall(part.toolCallId);
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

    if (tracker.pendingApproval(part.approvalId) != null) {
      throwPromptValidationError(
        context: context,
        messageIndex: messageIndex,
        partIndex: partIndex,
        message:
            'approval request "${part.approvalId}" is already waiting for a '
            'response.',
      );
    }

    tracker.recordApprovalRequest(
      PromptApprovalState(
        approvalId: part.approvalId,
        toolCallId: part.toolCallId,
        messageIndex: messageIndex,
        partIndex: partIndex,
      ),
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

    final pending = tracker.consumeApprovalResponse(part.approvalId);
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

  void requireNoPendingApprovalBeforeNextConversationMessage(
    int messageIndex,
    String nextMessageName,
  ) {
    final pendingApproval = tracker.firstPendingApproval;
    if (pendingApproval == null) {
      return;
    }

    throwPromptValidationError(
      context: context,
      messageIndex: messageIndex,
      partIndex: null,
      message:
          '$nextMessageName cannot appear before a tool message responds to '
          'approval request "${pendingApproval.approvalId}".',
    );
  }

  void requireNoPendingApprovalAtEnd() {
    final pendingApproval = tracker.firstPendingApproval;
    if (pendingApproval == null) {
      return;
    }

    throwPromptValidationError(
      context: context,
      messageIndex: pendingApproval.messageIndex,
      partIndex: pendingApproval.partIndex,
      message: 'approval request "${pendingApproval.approvalId}" is missing an '
          'approval response.',
    );
  }
}
