part of 'anthropic_messages_codec.dart';

final class _AnthropicEncodedPrompt {
  final List<Map<String, Object?>> system;
  final List<Map<String, Object?>> messages;

  _AnthropicEncodedPrompt({
    required List<Map<String, Object?>> system,
    required List<Map<String, Object?>> messages,
  })  : system = List.unmodifiable(system),
        messages = List.unmodifiable(messages);
}

_AnthropicEncodedPrompt _encodeAnthropicPrompt(
  List<PromptMessage> prompt, {
  required List<ModelWarning> warnings,
}) {
  final blocks = _groupAnthropicPrompt(prompt);
  final system = <Map<String, Object?>>[];
  final messages = <Map<String, Object?>>[];
  var sawConversationBlock = false;

  for (var index = 0; index < blocks.length; index++) {
    final block = blocks[index];
    switch (block.type) {
      case _AnthropicPromptBlockType.system:
        if (sawConversationBlock) {
          throw UnsupportedError(
            'Anthropic requests only support system messages before the first conversation block.',
          );
        }
        system.addAll(_encodeAnthropicSystemBlock(block));
      case _AnthropicPromptBlockType.user:
        sawConversationBlock = true;
        messages.add(_encodeAnthropicUserBlock(block));
      case _AnthropicPromptBlockType.assistant:
        sawConversationBlock = true;
        if (_encodeAnthropicAssistantBlock(
          block,
          trimTrailingText: index == blocks.length - 1,
          warnings: warnings,
        )
            case final encodedAssistantBlock?) {
          messages.add(encodedAssistantBlock);
        }
    }
  }

  if (messages.isEmpty) {
    throw ArgumentError(
      'Anthropic requests require at least one non-system prompt message.',
    );
  }

  return _AnthropicEncodedPrompt(
    system: system,
    messages: messages,
  );
}

List<_AnthropicPromptBlock> _groupAnthropicPrompt(List<PromptMessage> prompt) {
  final blocks = <_AnthropicPromptBlock>[];
  _AnthropicPromptBlock? currentBlock;

  for (final message in prompt) {
    final type = switch (message) {
      SystemPromptMessage() => _AnthropicPromptBlockType.system,
      AssistantPromptMessage() => _AnthropicPromptBlockType.assistant,
      UserPromptMessage() ||
      ToolPromptMessage() =>
        _AnthropicPromptBlockType.user,
    };

    if (currentBlock?.type != type) {
      currentBlock = _AnthropicPromptBlock(type);
      blocks.add(currentBlock);
    }

    currentBlock!.messages.add(message);
  }

  return blocks;
}

List<Map<String, Object?>> _encodeAnthropicSystemBlock(
  _AnthropicPromptBlock block,
) {
  final content = <Map<String, Object?>>[];

  for (final message in block.messages) {
    if (message is! SystemPromptMessage) {
      throw StateError('Expected a system prompt block.');
    }

    for (final part in message.parts) {
      if (part is! TextPromptPart) {
        throw UnsupportedError(
          'Anthropic system prompt part ${part.runtimeType} is not supported yet.',
        );
      }

      content.add(
        _encodeAnthropicTextContent(
          part,
          path: 'system',
        ),
      );
    }
  }

  return content;
}

Map<String, Object?> _encodeAnthropicUserBlock(
  _AnthropicPromptBlock block,
) {
  final content = <Map<String, Object?>>[];

  for (final message in block.messages) {
    if (message case UserPromptMessage(:final parts)) {
      for (final part in parts) {
        content.add(_encodeAnthropicUserPart(part));
      }
      continue;
    }

    if (message case ToolPromptMessage(:final parts)) {
      // Anthropic requires tool results to be replayed as user-role content.
      for (final part in parts) {
        content.addAll(_encodeAnthropicToolReplayParts(part));
      }
      continue;
    }

    throw StateError('Expected a user/tool prompt block.');
  }

  if (content.isEmpty) {
    throw ArgumentError('Anthropic user messages cannot be empty.');
  }

  return {
    'role': 'user',
    'content': content,
  };
}

Map<String, Object?>? _encodeAnthropicAssistantBlock(
  _AnthropicPromptBlock block, {
  required bool trimTrailingText,
  required List<ModelWarning> warnings,
}) {
  final content = <Map<String, Object?>>[];

  for (var messageIndex = 0;
      messageIndex < block.messages.length;
      messageIndex++) {
    final message = block.messages[messageIndex];
    if (message is! AssistantPromptMessage) {
      throw StateError('Expected an assistant prompt block.');
    }

    for (var partIndex = 0; partIndex < message.parts.length; partIndex++) {
      final part = message.parts[partIndex];
      final isLastAssistantPart = trimTrailingText &&
          messageIndex == block.messages.length - 1 &&
          partIndex == message.parts.length - 1;

      if (part is TextPromptPart) {
        final text = isLastAssistantPart ? part.text.trimRight() : part.text;
        if (text.isEmpty) {
          continue;
        }

        content.add(
          _encodeAnthropicTextContent(
            part,
            path: 'assistant.text',
            text: text,
          ),
        );
        continue;
      }

      if (part is ToolCallPromptPart) {
        content.add(_encodeAnthropicAssistantToolCallPart(part));
        continue;
      }

      if (part is ToolApprovalRequestPromptPart) {
        continue;
      }

      if (part is ToolResultPromptPart) {
        continue;
      }

      if (part is ToolApprovalResponsePromptPart) {
        continue;
      }

      if (part is ReasoningPromptPart ||
          part is FilePromptPart ||
          part is ReasoningFilePromptPart ||
          part is CustomPromptPart) {
        warnings.add(
          ModelWarning(
            type: ModelWarningType.unsupported,
            field: switch (part) {
              ReasoningPromptPart() => 'assistant.reasoning',
              FilePromptPart() => 'assistant.file',
              ReasoningFilePromptPart() => 'assistant.reasoningFile',
              CustomPromptPart() => 'assistant.custom',
              _ => 'assistant.part',
            },
            message: switch (part) {
              ReasoningPromptPart() =>
                'Anthropic assistant replay does not support reasoning parts yet. The part has been dropped.',
              FilePromptPart() =>
                'Anthropic assistant replay does not support assistant file parts yet. The part has been dropped.',
              ReasoningFilePromptPart() =>
                'Anthropic assistant replay does not support reasoning file parts yet. The part has been dropped.',
              CustomPromptPart(:final kind) =>
                'Anthropic assistant replay does not support custom part "$kind" yet. The part has been dropped.',
              _ =>
                'Anthropic assistant replay does not support this part yet. The part has been dropped.',
            },
          ),
        );
        continue;
      }

      throw UnsupportedError(
        'Anthropic assistant prompt part ${part.runtimeType} is not supported yet.',
      );
    }
  }

  if (content.isEmpty) {
    return null;
  }

  return {
    'role': 'assistant',
    'content': content,
  };
}

enum _AnthropicPromptBlockType {
  system,
  user,
  assistant,
}

final class _AnthropicPromptBlock {
  final _AnthropicPromptBlockType type;
  final List<PromptMessage> messages = [];

  _AnthropicPromptBlock(this.type);
}
