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

List<PromptMessage> assistantPromptMessagesFromChatUiMessage(
  ChatUiMessage message, {
  int startPartIndex = 0,
}) {
  final prompt = <PromptMessage>[];
  final assistantParts = <PromptPart>[];
  final replayedToolResultIds = {
    for (final part in message.parts.skip(startPartIndex))
      if (part case CustomUiPart(:final data))
        if (toolReplayPayloadRole(data) == 'tool')
          if (toolReplayPayloadToolCallId(data) case final String toolCallId)
            toolCallId,
  };

  void flushAssistantParts() {
    if (assistantParts.isEmpty) {
      return;
    }

    prompt.add(
      AssistantPromptMessage(
        parts: List<PromptPart>.from(assistantParts),
      ),
    );
    assistantParts.clear();
  }

  for (final part in message.parts.skip(startPartIndex)) {
    switch (part) {
      case TextUiPart(
            :final text,
            :final providerMetadata,
          )
          when text.isNotEmpty || providerMetadata != null:
        assistantParts.add(
          TextPromptPart(
            text,
            providerOptions: replayProviderOptions(providerMetadata),
          ),
        );
      case ReasoningUiPart(
            :final text,
            :final providerMetadata,
          )
          when text.isNotEmpty || providerMetadata != null:
        assistantParts.add(
          ReasoningPromptPart(
            text,
            providerOptions: replayProviderOptions(providerMetadata),
          ),
        );
      case FileUiPart(
          :final file,
          :final providerMetadata,
        ):
        assistantParts.add(
          FilePromptPart(
            mediaType: file.mediaType,
            filename: file.filename,
            data: file.data,
            providerOptions: replayProviderOptions(providerMetadata),
          ),
        );
      case ReasoningFileUiPart(
          :final file,
          :final providerMetadata,
        ):
        assistantParts.add(
          ReasoningFilePromptPart(
            mediaType: file.mediaType,
            filename: file.filename,
            data: file.data,
            providerOptions: replayProviderOptions(providerMetadata),
          ),
        );
      case CustomUiPart(
            :final kind,
            :final data,
            :final providerMetadata,
          )
          when toolReplayPayloadRole(data) == 'tool':
        flushAssistantParts();
        prompt.add(
          ToolPromptMessage(
            toolName: toolReplayPayloadToolName(data) ?? 'tool',
            parts: [
              CustomPromptPart(
                kind: kind,
                data: data,
                providerOptions: replayProviderOptions(providerMetadata),
              ),
            ],
          ),
        );
      case CustomUiPart(
          :final kind,
          :final data,
          :final providerMetadata,
        ):
        assistantParts.add(
          CustomPromptPart(
            kind: kind,
            data: data,
            providerOptions: replayProviderOptions(providerMetadata),
          ),
        );
      case ToolUiPart(
            :final toolCallId,
            :final toolName,
            :final input,
            :final state,
            :final providerExecuted,
            :final isDynamic,
            :final title,
            :final approval,
            :final callProviderMetadata,
          )
          when state != ToolUiPartState.outputDenied &&
              state != ToolUiPartState.outputAvailable &&
              state != ToolUiPartState.outputError:
        assistantParts.add(
          ToolCallPromptPart(
            toolCallId: toolCallId,
            toolName: toolName,
            input: input,
            providerExecuted: providerExecuted,
            isDynamic: isDynamic,
            title: title,
            providerOptions: replayProviderOptions(callProviderMetadata),
          ),
        );
        if (approval != null) {
          assistantParts.add(
            ToolApprovalRequestPromptPart(
              approvalId: approval.approvalId,
              toolCallId: toolCallId,
              providerOptions: replayProviderOptions(callProviderMetadata),
            ),
          );
        }
      case ToolUiPart(
            :final toolCallId,
            :final toolName,
            :final input,
            :final state,
            :final providerExecuted,
            :final isDynamic,
            :final title,
            :final callProviderMetadata,
            :final output,
            :final toolOutput,
            :final resultProviderMetadata,
          )
          when state == ToolUiPartState.outputAvailable ||
              state == ToolUiPartState.outputError:
        if (!providerExecuted) {
          break;
        }

        assistantParts.add(
          ToolCallPromptPart(
            toolCallId: toolCallId,
            toolName: toolName,
            input: input,
            providerExecuted: providerExecuted,
            isDynamic: isDynamic,
            title: title,
            providerOptions: replayProviderOptions(callProviderMetadata),
          ),
        );
        flushAssistantParts();

        if (replayedToolResultIds.contains(toolCallId)) {
          break;
        }

        prompt.add(
          ToolPromptMessage(
            toolName: toolName,
            parts: [
              ToolResultPromptPart(
                toolCallId: toolCallId,
                toolName: toolName,
                output: output,
                toolOutput: toolOutput,
                isError: state == ToolUiPartState.outputError,
                providerOptions: replayProviderOptions(resultProviderMetadata),
              ),
            ],
          ),
        );
      case StepBoundaryUiPart():
      case SourceUiPart():
      case DataUiPart():
      default:
        break;
    }
  }

  flushAssistantParts();
  return prompt;
}

String? toolReplayPayloadRole(Object? data) {
  final payload = toolReplayPayloadMap(data);
  final role = payload?['replayRole'];
  return role is String && role.isNotEmpty ? role : null;
}

String? toolReplayPayloadToolCallId(Object? data) {
  final payload = toolReplayPayloadMap(data);
  final toolCallId = payload?['toolCallId'];
  return toolCallId is String && toolCallId.isNotEmpty ? toolCallId : null;
}

String? toolReplayPayloadToolName(Object? data) {
  final payload = toolReplayPayloadMap(data);
  final toolName = payload?['toolName'];
  return toolName is String && toolName.isNotEmpty ? toolName : null;
}

Map<String, Object?>? toolReplayPayloadMap(Object? data) {
  if (data is Map<String, Object?>) {
    return data;
  }

  if (data is Map) {
    final normalized = <String, Object?>{};
    for (final entry in data.entries) {
      if (entry.key is! String) {
        return null;
      }

      normalized[entry.key as String] = entry.value;
    }
    return normalized;
  }

  return null;
}

ProviderReplayPromptPartOptions? replayProviderOptions(
  ProviderMetadata? metadata,
) {
  return ProviderReplayPromptPartOptions.fromMetadata(metadata);
}
