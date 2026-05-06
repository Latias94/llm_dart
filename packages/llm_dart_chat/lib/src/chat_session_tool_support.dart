import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'chat_state.dart';

Iterable<ToolUiPart> chatPendingAutomaticToolParts(
  ChatUiMessage assistantMessage,
) sync* {
  for (final part in assistantMessage.parts.whereType<ToolUiPart>()) {
    if (part.providerExecuted) {
      continue;
    }

    if (part.state == ToolUiPartState.inputAvailable ||
        part.state == ToolUiPartState.approvalResponded) {
      yield part;
    }
  }
}

ToolUiPart chatRequirePendingApprovalToolPart(
  ChatUiMessage message,
  String approvalId,
) {
  for (final part in message.parts) {
    if (part is! ToolUiPart || part.approval?.approvalId != approvalId) {
      continue;
    }

    if (part.state != ToolUiPartState.approvalRequested) {
      throw StateError(
        'Approval "$approvalId" is not waiting for a response.',
      );
    }

    return part;
  }

  throw StateError('No tool approval with ID "$approvalId" was found.');
}

ChatStatus chatDeriveCompletionStatus(ChatUiMessage? assistantMessage) {
  if (assistantMessage == null) {
    return ChatStatus.ready;
  }

  final toolParts = assistantMessage.parts.whereType<ToolUiPart>().toList();
  if (toolParts
      .any((part) => part.state == ToolUiPartState.approvalRequested)) {
    return ChatStatus.awaitingApproval;
  }

  if (toolParts.any(
    (part) =>
        part.state == ToolUiPartState.inputAvailable ||
        part.state == ToolUiPartState.inputStreaming ||
        (!part.providerExecuted &&
            part.state == ToolUiPartState.approvalResponded),
  )) {
    return ChatStatus.awaitingTool;
  }

  return ChatStatus.ready;
}

bool chatHasApprovedProviderExecutedTool(ChatUiMessage assistantMessage) {
  return assistantMessage.parts.whereType<ToolUiPart>().any(
        (part) =>
            part.providerExecuted &&
            part.state == ToolUiPartState.approvalResponded &&
            part.approval?.approved == true,
      );
}

ChatUiMessage chatUpdateToolPartByCallId(
  ChatUiMessage message,
  String toolCallId,
  ToolUiPart Function(ToolUiPart part) transform, {
  bool requirePendingState = false,
}) {
  var found = false;

  final parts = message.parts.map((part) {
    if (part is! ToolUiPart || part.toolCallId != toolCallId) {
      return part;
    }

    if (requirePendingState &&
        part.state != ToolUiPartState.inputAvailable &&
        part.state != ToolUiPartState.inputStreaming &&
        !(part.state == ToolUiPartState.approvalResponded &&
            !part.providerExecuted)) {
      throw StateError(
        'Tool call "$toolCallId" is not waiting for client-side output.',
      );
    }

    found = true;
    return transform(part);
  }).toList(growable: false);

  if (!found) {
    throw StateError('No tool call with ID "$toolCallId" was found.');
  }

  return ChatUiMessage(
    id: message.id,
    role: message.role,
    parts: parts,
    metadata: message.metadata,
  );
}

ChatUiMessage chatUpdateToolPartByApprovalId(
  ChatUiMessage message,
  String approvalId,
  ToolUiPart Function(ToolUiPart part) transform,
) {
  var found = false;

  final parts = message.parts.map((part) {
    if (part is! ToolUiPart || part.approval?.approvalId != approvalId) {
      return part;
    }

    if (part.state != ToolUiPartState.approvalRequested) {
      throw StateError(
        'Approval "$approvalId" is not waiting for a response.',
      );
    }

    found = true;
    return transform(part);
  }).toList(growable: false);

  if (!found) {
    throw StateError('No tool approval with ID "$approvalId" was found.');
  }

  return ChatUiMessage(
    id: message.id,
    role: message.role,
    parts: parts,
    metadata: message.metadata,
  );
}
