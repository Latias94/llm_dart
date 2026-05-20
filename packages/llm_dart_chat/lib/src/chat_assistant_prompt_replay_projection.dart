import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'chat_assistant_tool_replay_projection.dart';
import 'chat_prompt_replay_options.dart';
import 'chat_tool_replay_payload.dart';
export 'chat_prompt_replay_options.dart' show replayProviderOptions;
export 'chat_tool_replay_payload.dart'
    show
        parseChatToolReplayPayload,
        replayedToolResultIdsFromChatUiParts,
        toolReplayPayloadMap,
        toolReplayPayloadRole,
        toolReplayPayloadToolCallId,
        toolReplayPayloadToolName;

List<PromptMessage> assistantPromptMessagesFromChatUiMessage(
  ChatUiMessage message, {
  int startPartIndex = 0,
}) {
  final prompt = <PromptMessage>[];
  final assistantParts = <PromptPart>[];
  final replayParts = message.parts.skip(startPartIndex);
  final replayedToolResultIds =
      replayedToolResultIdsFromChatUiParts(replayParts);

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
      case ToolUiPart():
        final replay = projectAssistantToolPartForPromptReplay(
          part,
          replayedToolResultIds: replayedToolResultIds,
        );
        if (replay == null) {
          break;
        }

        assistantParts.addAll(replay.assistantParts);
        if (replay.flushAssistantParts) {
          flushAssistantParts();
        }
        if (replay.toolMessage case final toolMessage?) {
          prompt.add(toolMessage);
        }
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
