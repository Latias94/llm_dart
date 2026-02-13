import 'package:llm_dart_core/llm_dart_core.dart';

class InvalidToolApprovalError extends LLMError {
  final String approvalId;

  const InvalidToolApprovalError({
    required this.approvalId,
    String message = 'Invalid tool approval response',
  }) : super(message);

  @override
  String toString() => 'Invalid tool approval response: $message';
}

class ToolCallNotFoundForApprovalError extends LLMError {
  final String toolCallId;
  final String approvalId;

  const ToolCallNotFoundForApprovalError({
    required this.toolCallId,
    required this.approvalId,
    String message = 'Tool call not found for approval request',
  }) : super(message);

  @override
  String toString() => 'Tool call not found for approval request: $message';
}

class CollectedToolApproval {
  final ToolApprovalRequestPart approvalRequest;
  final ToolApprovalResponsePart approvalResponse;
  final ToolCallPart toolCall;

  const CollectedToolApproval({
    required this.approvalRequest,
    required this.approvalResponse,
    required this.toolCall,
  });
}

/// Collect tool approvals from a prompt history (AI SDK-inspired).
///
/// Semantics:
/// - Only considers approval responses in the last `role=tool` message.
/// - Matches responses to prior assistant `ToolApprovalRequestPart`s (by approvalId).
/// - Matches requests to assistant `ToolCallPart`s (by toolCallId).
/// - If a tool result for the same toolCallId is already present in the last tool message,
///   the approval is considered processed and is skipped.
({List<CollectedToolApproval> approved, List<CollectedToolApproval> denied})
    collectToolApprovalsFromPrompt(Prompt prompt) {
  return collectToolApprovalsFromPromptMessages(prompt.messages);
}

({List<CollectedToolApproval> approved, List<CollectedToolApproval> denied})
    collectToolApprovalsFromPromptMessages(List<PromptMessage> messages) {
  if (messages.isEmpty || messages.last.role != PromptRole.tool) {
    return (approved: const [], denied: const []);
  }

  final toolCallsById = <String, ToolCallPart>{};
  for (final message in messages) {
    if (message.role != PromptRole.assistant) continue;
    for (final part in message.parts) {
      if (part is ToolCallPart) {
        toolCallsById[part.toolCallId] = part;
      }
    }
  }

  final requestsByApprovalId = <String, ToolApprovalRequestPart>{};
  for (final message in messages) {
    if (message.role != PromptRole.assistant) continue;
    for (final part in message.parts) {
      if (part is ToolApprovalRequestPart) {
        requestsByApprovalId[part.approvalId] = part;
      }
    }
  }

  final toolResultsByToolCallId = <String, ToolResultPart>{};
  for (final part in messages.last.parts) {
    if (part is ToolResultPart) {
      toolResultsByToolCallId[part.toolCallId] = part;
    }
  }

  final approved = <CollectedToolApproval>[];
  final denied = <CollectedToolApproval>[];

  for (final part in messages.last.parts) {
    if (part is! ToolApprovalResponsePart) continue;

    final request = requestsByApprovalId[part.approvalId];
    if (request == null) {
      throw InvalidToolApprovalError(approvalId: part.approvalId);
    }

    if (toolResultsByToolCallId.containsKey(request.toolCallId)) {
      continue;
    }

    final toolCall = toolCallsById[request.toolCallId];
    if (toolCall == null) {
      throw ToolCallNotFoundForApprovalError(
        toolCallId: request.toolCallId,
        approvalId: request.approvalId,
      );
    }

    final collected = CollectedToolApproval(
      approvalRequest: request,
      approvalResponse: part,
      toolCall: toolCall,
    );

    if (part.approved) {
      approved.add(collected);
    } else {
      denied.add(collected);
    }
  }

  return (
    approved: List<CollectedToolApproval>.unmodifiable(approved),
    denied: List<CollectedToolApproval>.unmodifiable(denied),
  );
}
