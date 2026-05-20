import 'prompt_tool_state_models.dart';

final class PromptToolStateTracker {
  final Map<String, PromptToolCallState> _seenToolCalls = {};
  final Map<String, PromptToolCallState> _pendingClientToolCalls = {};
  final Map<String, PromptApprovalState> _pendingApprovals = {};

  PromptToolCallState? seenToolCall(String toolCallId) {
    return _seenToolCalls[toolCallId];
  }

  PromptToolCallState? pendingClientToolCall(String toolCallId) {
    return _pendingClientToolCalls[toolCallId];
  }

  PromptApprovalState? pendingApproval(String approvalId) {
    return _pendingApprovals[approvalId];
  }

  void recordToolCall(PromptToolCallState state) {
    _seenToolCalls[state.toolCallId] = state;
    if (!state.providerExecuted) {
      _pendingClientToolCalls[state.toolCallId] = state;
    }
  }

  PromptToolCallState? consumePendingClientToolCall(String toolCallId) {
    return _pendingClientToolCalls.remove(toolCallId);
  }

  void recordApprovalRequest(PromptApprovalState state) {
    _pendingApprovals[state.approvalId] = state;
  }

  PromptApprovalState? consumeApprovalResponse(String approvalId) {
    return _pendingApprovals.remove(approvalId);
  }

  PromptToolCallState? get firstPendingClientToolCall {
    return _pendingClientToolCalls.values.firstOrNull;
  }

  PromptApprovalState? get firstPendingApproval {
    return _pendingApprovals.values.firstOrNull;
  }
}
