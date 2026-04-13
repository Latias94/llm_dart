import 'package:llm_dart_core/llm_dart_core.dart';

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
      case TextPromptPart(
          :final text,
          :final providerMetadata,
        ):
        parts.add(
          TextUiPart(
            text: text,
            providerMetadata: providerMetadata,
          ),
        );
      case ReasoningPromptPart(
          :final text,
          :final providerMetadata,
        ):
        parts.add(
          ReasoningUiPart(
            text: text,
            providerMetadata: providerMetadata,
          ),
        );
      case FilePromptPart(
          :final mediaType,
          :final filename,
          :final uri,
          :final bytes,
          :final providerMetadata,
        ):
        parts.add(
          FileUiPart(
            GeneratedFile(
              mediaType: mediaType,
              filename: filename,
              uri: uri,
              bytes: bytes,
            ),
            providerMetadata: providerMetadata,
          ),
        );
      case ReasoningFilePromptPart(
          :final mediaType,
          :final filename,
          :final uri,
          :final bytes,
          :final providerMetadata,
        ):
        parts.add(
          ReasoningFileUiPart(
            GeneratedFile(
              mediaType: mediaType,
              filename: filename,
              uri: uri,
              bytes: bytes,
            ),
            providerMetadata: providerMetadata,
          ),
        );
      case ImagePromptPart(
          :final mediaType,
          :final uri,
          :final bytes,
          :final providerMetadata,
        ):
        parts.add(
          FileUiPart(
            GeneratedFile(
              mediaType: mediaType,
              uri: uri,
              bytes: bytes,
            ),
            providerMetadata: providerMetadata,
          ),
        );
      case CustomPromptPart(
          :final kind,
          :final data,
          :final providerMetadata,
        ):
        parts.add(
          CustomUiPart(
            kind: kind,
            data: data,
            providerMetadata: providerMetadata,
          ),
        );
      case ToolCallPromptPart(
          :final toolCallId,
          :final toolName,
          :final input,
          :final providerExecuted,
          :final isDynamic,
          :final title,
          :final providerMetadata,
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
            errorText: current?.errorText,
            providerExecuted:
                providerExecuted || current?.providerExecuted == true,
            isDynamic: isDynamic || current?.isDynamic == true,
            preliminary: current?.preliminary ?? false,
            title: title ?? current?.title,
            approval: current?.approval,
            callProviderMetadata: ProviderMetadata.mergeNullable(
              current?.callProviderMetadata,
              providerMetadata,
            ),
            resultProviderMetadata: current?.resultProviderMetadata,
          ),
        );
      case ToolApprovalRequestPromptPart(
          :final approvalId,
          :final toolCallId,
          :final providerMetadata,
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
              providerMetadata,
            ),
            resultProviderMetadata: current?.resultProviderMetadata,
          ),
        );
      case ToolResultPromptPart(
          :final toolCallId,
          :final toolName,
          :final output,
          :final isError,
          :final providerMetadata,
        ):
        upsertToolPart(
          toolCallId,
          (current) => ToolUiPart(
            toolCallId: toolCallId,
            toolName: toolName,
            state: isError
                ? ToolUiPartState.outputError
                : ToolUiPartState.outputAvailable,
            input: current?.input,
            inputText: current?.inputText,
            output: output,
            errorText: isError ? '$output' : null,
            providerExecuted: current?.providerExecuted ?? false,
            isDynamic: current?.isDynamic ?? false,
            preliminary: false,
            title: current?.title,
            approval: current?.approval,
            callProviderMetadata: current?.callProviderMetadata,
            resultProviderMetadata: ProviderMetadata.mergeNullable(
              current?.resultProviderMetadata,
              providerMetadata,
            ),
          ),
        );
      case ToolApprovalResponsePromptPart(
          :final approvalId,
          :final toolCallId,
          :final approved,
          :final reason,
          :final providerMetadata,
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
              providerMetadata,
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
            providerMetadata: providerMetadata,
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
            providerMetadata: providerMetadata,
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
            uri: file.uri,
            bytes: file.bytes,
            providerMetadata: providerMetadata,
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
            uri: file.uri,
            bytes: file.bytes,
            providerMetadata: providerMetadata,
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
                providerMetadata: providerMetadata,
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
            providerMetadata: providerMetadata,
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
            providerMetadata: callProviderMetadata,
          ),
        );
        if (approval != null) {
          assistantParts.add(
            ToolApprovalRequestPromptPart(
              approvalId: approval.approvalId,
              toolCallId: toolCallId,
              providerMetadata: callProviderMetadata,
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
            providerMetadata: callProviderMetadata,
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
                isError: state == ToolUiPartState.outputError,
                providerMetadata: resultProviderMetadata,
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
