final class PromptToolCallState {
  final String toolCallId;
  final String toolName;
  final bool providerExecuted;
  final int messageIndex;
  final int partIndex;

  const PromptToolCallState({
    required this.toolCallId,
    required this.toolName,
    required this.providerExecuted,
    required this.messageIndex,
    required this.partIndex,
  });
}

final class PromptApprovalState {
  final String approvalId;
  final String toolCallId;
  final int messageIndex;
  final int partIndex;

  const PromptApprovalState({
    required this.approvalId,
    required this.toolCallId,
    required this.messageIndex,
    required this.partIndex,
  });
}
