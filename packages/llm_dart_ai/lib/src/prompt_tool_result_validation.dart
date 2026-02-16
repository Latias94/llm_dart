import 'package:llm_dart_core/llm_dart_core.dart';

import 'ai_errors.dart';

/// Validates that every client-executed tool call has a corresponding tool result.
///
/// This mirrors Vercel AI SDK's `MissingToolResultsError` validation logic in
/// `convertToLanguageModelPrompt`.
///
/// Rules (AI SDK-inspired):
/// - Track `ToolCallPart`s in assistant messages where `providerExecuted != true`.
/// - Remove ids when a matching `ToolResultPart` appears in a tool message.
/// - Tool approval responses can "ack" a pending tool call; once approved/denied,
///   the tool call id is removed from validation (best-effort parity).
/// - Before any non-tool message (user/system), no pending tool-call ids may remain.
///
/// Throws [MissingToolResultsError] when missing tool results are detected.
void validateNoMissingToolResults(Prompt prompt) {
  if (prompt.messages.isEmpty) return;

  final approvalIdToToolCallId = <String, String>{};
  for (final message in prompt.messages) {
    if (message.role != PromptRole.assistant) continue;
    for (final part in message.parts) {
      if (part is ToolApprovalRequestPart) {
        final approvalId = part.approvalId.trim();
        final toolCallId = part.toolCallId.trim();
        if (approvalId.isEmpty || toolCallId.isEmpty) continue;
        approvalIdToToolCallId[approvalId] = toolCallId;
      }
    }
  }

  final approvedToolCallIds = <String>{};
  for (final message in prompt.messages) {
    if (message.role != PromptRole.tool) continue;
    for (final part in message.parts) {
      if (part is ToolApprovalResponsePart) {
        final approvalId = part.approvalId.trim();
        if (approvalId.isEmpty) continue;
        final toolCallId = approvalIdToToolCallId[approvalId];
        if (toolCallId != null && toolCallId.isNotEmpty) {
          approvedToolCallIds.add(toolCallId);
        }
      }
    }
  }

  final pendingToolCallIds = <String>{};

  void removeApproved() {
    if (approvedToolCallIds.isEmpty || pendingToolCallIds.isEmpty) return;
    pendingToolCallIds.removeAll(approvedToolCallIds);
  }

  void throwIfPending() {
    removeApproved();
    if (pendingToolCallIds.isEmpty) return;
    throw MissingToolResultsError(
      toolCallIds: pendingToolCallIds.toList(growable: false),
    );
  }

  for (final message in prompt.messages) {
    switch (message.role) {
      case PromptRole.assistant:
        for (final part in message.parts) {
          if (part is! ToolCallPart) continue;
          if (part.providerExecuted == true) continue;
          final id = part.toolCallId.trim();
          if (id.isEmpty) continue;
          pendingToolCallIds.add(id);
        }
        break;

      case PromptRole.tool:
        for (final part in message.parts) {
          if (part is ToolResultPart) {
            final id = part.toolCallId.trim();
            if (id.isNotEmpty) {
              pendingToolCallIds.remove(id);
            }
          }
        }
        break;

      case PromptRole.user:
      case PromptRole.system:
        throwIfPending();
        break;
    }
  }

  throwIfPending();
}
