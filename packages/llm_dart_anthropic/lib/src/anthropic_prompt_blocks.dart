import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_content_encoder.dart';
import 'anthropic_prompt_beta_features.dart';
import 'anthropic_prompt_block_grouping.dart';
import 'anthropic_prompt_limitations.dart';
import 'anthropic_tool_replay_encoder.dart';

final class AnthropicEncodedPrompt {
  final List<Map<String, Object?>> system;
  final List<Map<String, Object?>> messages;
  final List<String> betaFeatures;

  AnthropicEncodedPrompt({
    required List<Map<String, Object?>> system,
    required List<Map<String, Object?>> messages,
    List<String> betaFeatures = const [],
  })  : system = List.unmodifiable(system),
        messages = List.unmodifiable(messages),
        betaFeatures = List.unmodifiable(betaFeatures);
}

final class AnthropicPromptBlockEncoder {
  final AnthropicContentEncoder contentEncoder;
  final AnthropicToolReplayEncoder toolReplayEncoder;

  const AnthropicPromptBlockEncoder({
    this.contentEncoder = const AnthropicContentEncoder(),
    this.toolReplayEncoder = const AnthropicToolReplayEncoder(),
  });

  AnthropicEncodedPrompt encode(
    List<PromptMessage> prompt, {
    required List<ModelWarning> warnings,
  }) {
    final blocks = groupAnthropicPromptBlocks(prompt);
    final system = <Map<String, Object?>>[];
    final messages = <Map<String, Object?>>[];
    var sawConversationBlock = false;

    for (var index = 0; index < blocks.length; index++) {
      final block = blocks[index];
      switch (block.type) {
        case AnthropicPromptBlockType.system:
          if (sawConversationBlock) {
            throw UnsupportedError(
              'Anthropic requests only support system messages before the first conversation block.',
            );
          }
          system.addAll(_encodeSystemBlock(block));
        case AnthropicPromptBlockType.user:
          sawConversationBlock = true;
          messages.add(_encodeUserBlock(block));
        case AnthropicPromptBlockType.assistant:
          sawConversationBlock = true;
          if (_encodeAssistantBlock(
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

    return AnthropicEncodedPrompt(
      system: system,
      messages: messages,
      betaFeatures: inferAnthropicPromptBetaFeatures(
        system: system,
        messages: messages,
      ),
    );
  }

  List<Map<String, Object?>> _encodeSystemBlock(
    AnthropicPromptBlock block,
  ) {
    final content = <Map<String, Object?>>[];

    for (final message in block.messages) {
      if (message is! SystemPromptMessage) {
        throw StateError('Expected a system prompt block.');
      }

      for (final part in message.parts) {
        if (part is! TextPromptPart) {
          throw unsupportedAnthropicPromptPart(role: 'system', part: part);
        }

        content.add(
          contentEncoder.encodeTextContent(
            part,
            path: 'system',
          ),
        );
      }
    }

    return content;
  }

  Map<String, Object?> _encodeUserBlock(
    AnthropicPromptBlock block,
  ) {
    final content = <Map<String, Object?>>[];

    for (final message in block.messages) {
      if (message case UserPromptMessage(:final parts)) {
        for (final part in parts) {
          content.add(contentEncoder.encodeUserPart(part));
        }
        continue;
      }

      if (message case ToolPromptMessage(:final parts)) {
        // Anthropic requires tool results to be replayed as user-role content.
        for (final part in parts) {
          content.addAll(toolReplayEncoder.encodeToolReplayParts(part));
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

  Map<String, Object?>? _encodeAssistantBlock(
    AnthropicPromptBlock block, {
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
            contentEncoder.encodeTextContent(
              part,
              path: 'assistant.text',
              text: text,
            ),
          );
          continue;
        }

        if (part is ToolCallPromptPart) {
          content.add(toolReplayEncoder.encodeAssistantToolCallPart(part));
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
          warnings.add(unsupportedAnthropicAssistantReplayPartWarning(part));
          continue;
        }

        throw unsupportedAnthropicPromptPart(role: 'assistant', part: part);
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
}
