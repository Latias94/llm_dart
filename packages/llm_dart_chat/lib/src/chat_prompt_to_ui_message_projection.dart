import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'chat_tool_output_support.dart';

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

  void upsertToolPart(
    String toolCallId,
    ToolUiPart Function(ToolUiPart? current) build,
  ) {
    final index = parts.lastIndexWhere(
      (part) => part is ToolUiPart && part.toolCallId == toolCallId,
    );
    final current = index == -1 ? null : parts[index] as ToolUiPart;
    final next = build(current);

    if (index == -1) {
      parts.add(next);
    } else {
      parts[index] = next;
    }
  }

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
      case ToolCallPromptPart(
          :final toolCallId,
          :final toolName,
          :final input,
          :final providerExecuted,
          :final isDynamic,
          :final title,
          :final providerOptions,
        ):
        upsertToolPart(
          toolCallId,
          (current) => ToolUiPart(
            toolCallId: toolCallId,
            toolName: toolName,
            state: current?.approval != null
                ? ToolUiPartState.approvalRequested
                : ToolUiPartState.inputAvailable,
            input: input,
            inputText: current?.inputText,
            output: current?.output,
            toolOutput: current?.toolOutput,
            errorText: current?.errorText,
            providerExecuted:
                providerExecuted || current?.providerExecuted == true,
            isDynamic: isDynamic || current?.isDynamic == true,
            preliminary: current?.preliminary ?? false,
            title: title ?? current?.title,
            approval: current?.approval,
            callProviderMetadata: ProviderMetadata.mergeNullable(
              current?.callProviderMetadata,
              providerReplayMetadataFromOptions(providerOptions),
            ),
            resultProviderMetadata: current?.resultProviderMetadata,
          ),
        );
      case ToolApprovalRequestPromptPart(
          :final approvalId,
          :final toolCallId,
          :final providerOptions,
        ):
        upsertToolPart(
          toolCallId,
          (current) => ToolUiPart(
            toolCallId: toolCallId,
            toolName: current?.toolName ??
                (message is ToolPromptMessage ? message.toolName : 'tool'),
            state: ToolUiPartState.approvalRequested,
            input: current?.input,
            inputText: current?.inputText,
            output: current?.output,
            toolOutput: current?.toolOutput,
            errorText: current?.errorText,
            providerExecuted: current?.providerExecuted ?? false,
            isDynamic: current?.isDynamic ?? false,
            preliminary: current?.preliminary ?? false,
            title: current?.title,
            approval: ToolApprovalUiState(
              approvalId: approvalId,
            ),
            callProviderMetadata: ProviderMetadata.mergeNullable(
              current?.callProviderMetadata,
              providerReplayMetadataFromOptions(providerOptions),
            ),
            resultProviderMetadata: current?.resultProviderMetadata,
          ),
        );
      case ToolResultPromptPart(
          :final toolCallId,
          :final toolName,
          :final output,
          :final isError,
          :final toolOutput,
          :final providerOptions,
        ):
        upsertToolPart(
          toolCallId,
          (current) => ToolUiPart(
            toolCallId: toolCallId,
            toolName: toolName,
            state: chatToolOutputState(toolOutput),
            input: current?.input,
            inputText: current?.inputText,
            output: output,
            toolOutput: toolOutput,
            errorText:
                isError ? chatStringifyToolOutputValue(toolOutput) : null,
            providerExecuted: current?.providerExecuted ?? false,
            isDynamic: current?.isDynamic ?? false,
            preliminary: false,
            title: current?.title,
            approval: current?.approval,
            callProviderMetadata: current?.callProviderMetadata,
            resultProviderMetadata: ProviderMetadata.mergeNullable(
              current?.resultProviderMetadata,
              providerReplayMetadataFromOptions(providerOptions),
            ),
          ),
        );
      case ToolApprovalResponsePromptPart(
          :final approvalId,
          :final toolCallId,
          :final approved,
          :final reason,
          :final providerOptions,
        ):
        upsertToolPart(
          toolCallId,
          (current) => ToolUiPart(
            toolCallId: toolCallId,
            toolName: current?.toolName ??
                (message is ToolPromptMessage ? message.toolName : 'tool'),
            state: approved
                ? ToolUiPartState.approvalResponded
                : ToolUiPartState.outputDenied,
            input: current?.input,
            inputText: current?.inputText,
            output: current?.output,
            toolOutput: approved
                ? current?.toolOutput
                : ExecutionDeniedToolOutput(reason),
            errorText: current?.errorText,
            providerExecuted: current?.providerExecuted ?? false,
            isDynamic: current?.isDynamic ?? false,
            preliminary: current?.preliminary ?? false,
            title: current?.title,
            approval: ToolApprovalUiState(
              approvalId: approvalId,
              approved: approved,
              reason: reason,
            ),
            callProviderMetadata: ProviderMetadata.mergeNullable(
              current?.callProviderMetadata,
              providerReplayMetadataFromOptions(providerOptions),
            ),
            resultProviderMetadata: current?.resultProviderMetadata,
          ),
        );
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
