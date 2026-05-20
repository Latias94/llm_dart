import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'chat_prompt_replay_options.dart';

final class ChatAssistantToolReplay {
  final List<PromptPart> assistantParts;
  final ToolPromptMessage? toolMessage;
  final bool flushAssistantParts;

  const ChatAssistantToolReplay({
    this.assistantParts = const [],
    this.toolMessage,
    this.flushAssistantParts = false,
  });
}

ChatAssistantToolReplay? projectAssistantToolPartForPromptReplay(
  ToolUiPart part, {
  required Set<String> replayedToolResultIds,
}) {
  switch (part.state) {
    case ToolUiPartState.outputAvailable:
    case ToolUiPartState.outputError:
      return _projectCompletedToolPart(
        part,
        replayedToolResultIds: replayedToolResultIds,
      );
    case ToolUiPartState.outputDenied:
      return null;
    case ToolUiPartState.inputStreaming:
    case ToolUiPartState.inputAvailable:
    case ToolUiPartState.approvalRequested:
    case ToolUiPartState.approvalResponded:
      return _projectPendingToolPart(part);
  }
}

ChatAssistantToolReplay _projectPendingToolPart(ToolUiPart part) {
  final parts = <PromptPart>[
    _toolCallPromptPart(part),
  ];
  final approval = part.approval;
  if (approval != null) {
    parts.add(
      ToolApprovalRequestPromptPart(
        approvalId: approval.approvalId,
        toolCallId: part.toolCallId,
        providerOptions: replayProviderOptions(part.callProviderMetadata),
      ),
    );
  }

  return ChatAssistantToolReplay(assistantParts: parts);
}

ChatAssistantToolReplay? _projectCompletedToolPart(
  ToolUiPart part, {
  required Set<String> replayedToolResultIds,
}) {
  if (!part.providerExecuted) {
    return null;
  }

  final assistantParts = <PromptPart>[
    _toolCallPromptPart(part),
  ];

  if (replayedToolResultIds.contains(part.toolCallId)) {
    return ChatAssistantToolReplay(
      assistantParts: assistantParts,
      flushAssistantParts: true,
    );
  }

  return ChatAssistantToolReplay(
    assistantParts: assistantParts,
    flushAssistantParts: true,
    toolMessage: ToolPromptMessage(
      toolName: part.toolName,
      parts: [
        ToolResultPromptPart(
          toolCallId: part.toolCallId,
          toolName: part.toolName,
          output: part.output,
          toolOutput: part.toolOutput,
          isError: part.state == ToolUiPartState.outputError,
          providerOptions: replayProviderOptions(part.resultProviderMetadata),
        ),
      ],
    ),
  );
}

ToolCallPromptPart _toolCallPromptPart(ToolUiPart part) {
  return ToolCallPromptPart(
    toolCallId: part.toolCallId,
    toolName: part.toolName,
    input: part.input,
    providerExecuted: part.providerExecuted,
    isDynamic: part.isDynamic,
    title: part.title,
    providerOptions: replayProviderOptions(part.callProviderMetadata),
  );
}
