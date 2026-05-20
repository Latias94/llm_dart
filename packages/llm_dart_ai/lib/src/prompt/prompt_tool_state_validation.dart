import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'prompt_tool_approval_validation.dart';
import 'prompt_tool_result_validation.dart';
import 'prompt_tool_state_tracker.dart';

final class PromptToolStateValidator {
  final String context;
  final PromptToolStateTracker _tracker;
  late final PromptToolResultValidator _toolResults =
      PromptToolResultValidator(context: context, tracker: _tracker);
  late final PromptToolApprovalValidator _approvals =
      PromptToolApprovalValidator(context: context, tracker: _tracker);

  PromptToolStateValidator(this.context) : _tracker = PromptToolStateTracker();

  void recordToolCall(
    ToolCallPromptPart part, {
    required int messageIndex,
    required int partIndex,
  }) {
    _toolResults.recordToolCall(
      part,
      messageIndex: messageIndex,
      partIndex: partIndex,
    );
  }

  void recordApprovalRequest(
    ToolApprovalRequestPromptPart part, {
    required int messageIndex,
    required int partIndex,
  }) {
    _approvals.recordApprovalRequest(
      part,
      messageIndex: messageIndex,
      partIndex: partIndex,
    );
  }

  void validateAssistantToolResult(
    ToolResultPromptPart part, {
    required int messageIndex,
    required int partIndex,
  }) {
    _toolResults.validateAssistantToolResult(
      part,
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
    _toolResults.consumeToolResult(
      part,
      messageToolName: messageToolName,
      messageIndex: messageIndex,
      partIndex: partIndex,
    );
  }

  void consumeApprovalResponse(
    ToolApprovalResponsePromptPart part, {
    required int messageIndex,
    required int partIndex,
  }) {
    _approvals.consumeApprovalResponse(
      part,
      messageIndex: messageIndex,
      partIndex: partIndex,
    );
  }

  void requireNoPendingBeforeNextConversationMessage(
    int messageIndex,
    String nextMessageName,
  ) {
    _toolResults.requireNoPendingClientToolCallBeforeNextConversationMessage(
      messageIndex,
      nextMessageName,
    );
    _approvals.requireNoPendingApprovalBeforeNextConversationMessage(
      messageIndex,
      nextMessageName,
    );
  }

  void requireNoPendingAtEnd() {
    _toolResults.requireNoPendingClientToolCallAtEnd();
    _approvals.requireNoPendingApprovalAtEnd();
  }
}
