import 'package:llm_dart_ai/llm_dart_ai.dart';

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
