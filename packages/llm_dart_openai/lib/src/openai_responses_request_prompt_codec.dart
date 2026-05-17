import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_options.dart';
import 'openai_responses_assistant_prompt_projection.dart';
import 'openai_responses_replay_policy.dart';
import 'openai_responses_tool_prompt_projection.dart';
import 'openai_responses_user_part_encoder.dart';
import 'openai_responses_request_tool_codec.dart';

final class OpenAIResponsesPromptCodec {
  final OpenAIResponsesRequestToolCodec toolCodec;
  final OpenAIResponsesUserPartEncoder userPartEncoder;
  final OpenAIResponsesAssistantPromptProjection assistantProjection;

  const OpenAIResponsesPromptCodec({
    this.toolCodec = const OpenAIResponsesRequestToolCodec(),
    this.userPartEncoder = const OpenAIResponsesUserPartEncoder(),
    this.assistantProjection = const OpenAIResponsesAssistantPromptProjection(),
  });

  List<Object?> encodePromptMessage(
    PromptMessage message,
    List<ModelWarning> warnings, {
    required OpenAISystemMessageMode systemMessageMode,
    required bool store,
    required bool hasConversation,
  }) {
    if (message is SystemPromptMessage) {
      if (systemMessageMode == OpenAISystemMessageMode.remove) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.other,
            field: 'prompt.system',
            message: 'system messages are removed for this model',
          ),
        );
        return const [];
      }

      return [
        {
          'role': systemMessageMode.value,
          'content': _joinTextParts(
            role: 'system',
            parts: message.parts,
          ),
        },
      ];
    }

    if (message is UserPromptMessage) {
      return [
        {
          'role': 'user',
          'content': [
            for (var index = 0; index < message.parts.length; index++)
              userPartEncoder.encode(message.parts[index], index: index),
          ],
        },
      ];
    }

    final replayPolicy = OpenAIResponsesReplayPolicy(
      store: store,
      hasConversation: hasConversation,
    );

    if (message is AssistantPromptMessage) {
      return assistantProjection.encode(
        message,
        warnings,
        replayPolicy: replayPolicy,
      );
    }

    if (message is ToolPromptMessage) {
      return OpenAIResponsesToolPromptProjection(
        toolCodec: toolCodec,
      ).encode(
        message,
        replayPolicy: replayPolicy,
      );
    }

    throw UnsupportedError(
      'Unsupported prompt message type: ${message.runtimeType}',
    );
  }

  String _joinTextParts({
    required String role,
    required List<PromptPart> parts,
  }) {
    final buffer = <String>[];

    for (final part in parts) {
      if (part is! TextPromptPart) {
        throw UnsupportedError(
          '$role prompt part ${part.runtimeType} is not supported by the migrated Responses codec yet.',
        );
      }

      buffer.add(part.text);
    }

    return buffer.join('\n\n');
  }
}
