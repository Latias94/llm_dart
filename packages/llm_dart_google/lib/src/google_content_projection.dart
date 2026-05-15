import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_prompt_message_encoder.dart';
import 'google_server_tool_replay.dart';
import 'google_shared.dart';

final class GooglePromptProjection {
  final List<Map<String, Object?>> systemInstructionParts;
  final List<Map<String, Object?>> contents;

  const GooglePromptProjection({
    required this.systemInstructionParts,
    required this.contents,
  });
}

final class GoogleContentProjectionCodec {
  static const GooglePromptMessageEncoder _messageEncoder =
      GooglePromptMessageEncoder();

  const GoogleContentProjectionCodec();

  GooglePromptProjection encodePrompt({
    required String modelId,
    required List<PromptMessage> prompt,
  }) {
    final systemInstructionParts = <Map<String, Object?>>[];
    final contents = <Map<String, Object?>>[];
    var sawConversationMessage = false;

    for (final message in prompt) {
      if (message is SystemPromptMessage) {
        if (sawConversationMessage) {
          throw UnsupportedError(
            'Google system messages are only supported before the first conversation message.',
          );
        }

        for (final part in message.parts) {
          if (part is! TextPromptPart) {
            throw UnsupportedError(
              'Google system prompt part ${part.runtimeType} is not supported yet.',
            );
          }

          systemInstructionParts.add({
            'text': part.text,
          });
        }
        continue;
      }

      sawConversationMessage = true;
      final encodedMessage = _messageEncoder.encodeMessage(
        message,
        modelId: modelId,
      );
      if (encodedMessage != null) {
        contents.add(encodedMessage);
      }
    }

    if (contents.isEmpty) {
      throw ArgumentError(
        'Google requests require at least one non-system prompt message.',
      );
    }

    final isGemmaModel = modelId.toLowerCase().startsWith('gemma-');
    if (systemInstructionParts.isNotEmpty && isGemmaModel) {
      final firstContent = contents.first;
      if (firstContent['role'] != 'user') {
        throw UnsupportedError(
          'Gemma system prompts require the first non-system message to be a user message.',
        );
      }

      final parts = List<Object?>.from(asList(firstContent['parts']));
      parts.insert(
        0,
        {
          'text':
              '${systemInstructionParts.map((part) => part['text']).join('\n\n')}\n\n',
        },
      );
      firstContent['parts'] = parts;
    }

    return GooglePromptProjection(
      systemInstructionParts: systemInstructionParts,
      contents: contents,
    );
  }

  bool promptRequiresServerToolReplay(List<PromptMessage> prompt) {
    for (final message in prompt) {
      final parts = switch (message) {
        UserPromptMessage(:final parts) => parts,
        AssistantPromptMessage(:final parts) => parts,
        ToolPromptMessage(:final parts) => parts,
        SystemPromptMessage(:final parts) => parts,
      };

      for (final part in parts) {
        if (part is! CustomPromptPart) {
          continue;
        }

        if (part.kind == GoogleToolCallReplay.kind ||
            part.kind == GoogleToolResponseReplay.kind) {
          return true;
        }
      }
    }

    return false;
  }
}
