import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'chat_prompt_tool_part_projection.dart';

List<ChatUiMessage> visibleMessagesFromPrompt(
  List<PromptMessage> prompt,
) {
  return prompt
      .asMap()
      .entries
      .map(
        (entry) => promptMessageToChatUiMessage(
          entry.value,
          id: 'seed-${entry.key}',
        ),
      )
      .toList(growable: false);
}

ChatUiMessage promptMessageToChatUiMessage(
  PromptMessage message, {
  required String id,
}) {
  final parts = <ChatUiPart>[];
  final toolProjector = ChatPromptToolPartProjector(
    parts: parts,
    fallbackToolName: message is ToolPromptMessage ? message.toolName : 'tool',
  );

  for (final part in message.parts) {
    switch (part) {
      case TextPromptPart(:final text, :final providerOptions):
        parts.add(
          TextUiPart(
            text: text,
            providerMetadata: providerReplayMetadataFromOptions(
              providerOptions,
            ),
          ),
        );
      case ReasoningPromptPart(:final text, :final providerOptions):
        parts.add(
          ReasoningUiPart(
            text: text,
            providerMetadata: providerReplayMetadataFromOptions(
              providerOptions,
            ),
          ),
        );
      case FilePromptPart(
          :final mediaType,
          :final filename,
          :final data,
          :final providerOptions,
        ):
        parts.add(
          FileUiPart(
            GeneratedFile(
              mediaType: mediaType,
              filename: filename,
              data: data,
            ),
            providerMetadata: providerReplayMetadataFromOptions(
              providerOptions,
            ),
          ),
        );
      case ReasoningFilePromptPart(
          :final mediaType,
          :final filename,
          :final data,
          :final providerOptions,
        ):
        parts.add(
          ReasoningFileUiPart(
            GeneratedFile(
              mediaType: mediaType,
              filename: filename,
              data: data,
            ),
            providerMetadata: providerReplayMetadataFromOptions(
              providerOptions,
            ),
          ),
        );
      case ImagePromptPart(
          :final mediaType,
          :final data,
          :final providerOptions,
        ):
        parts.add(
          FileUiPart(
            GeneratedFile(
              mediaType: mediaType,
              data: data,
            ),
            providerMetadata: providerReplayMetadataFromOptions(
              providerOptions,
            ),
          ),
        );
      case CustomPromptPart(
          :final kind,
          :final data,
          :final providerOptions,
        ):
        parts.add(
          CustomUiPart(
            kind: kind,
            data: data,
            providerMetadata: providerReplayMetadataFromOptions(
              providerOptions,
            ),
          ),
        );
      case ToolCallPromptPart toolCall:
        toolProjector.applyToolCall(toolCall);
      case ToolApprovalRequestPromptPart approvalRequest:
        toolProjector.applyApprovalRequest(approvalRequest);
      case ToolResultPromptPart toolResult:
        toolProjector.applyToolResult(toolResult);
      case ToolApprovalResponsePromptPart approvalResponse:
        toolProjector.applyApprovalResponse(approvalResponse);
    }
  }

  return ChatUiMessage(
    id: id,
    role: switch (message.role) {
      PromptRole.system => ChatUiRole.system,
      PromptRole.user => ChatUiRole.user,
      PromptRole.assistant || PromptRole.tool => ChatUiRole.assistant,
    },
    parts: parts,
  );
}
