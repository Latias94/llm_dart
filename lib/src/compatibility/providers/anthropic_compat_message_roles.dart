part of 'anthropic_compat_support.dart';

final class _AnthropicCompatMessageRoleConverter {
  static const _promptParts = _AnthropicCompatPromptPartConverter();
  static const _toolResults = _AnthropicCompatToolResultConverter();

  const _AnthropicCompatMessageRoleConverter();

  List<core.PromptMessage> convertAnthropicLegacyMessage(
    ChatMessage message, {
    required int messageIndex,
    required Map<String, _AnthropicCompatToolDescriptor> toolDescriptors,
  }) {
    final analysis = analyzeAnthropicLegacyMessage(
      message,
      messageIndex: messageIndex,
    );

    final blocks = <AnthropicLegacyPromptBlock>[
      ...analysis.promptBlocks,
      if (message.content.isNotEmpty)
        AnthropicLegacyTextBlock(
          text: message.content,
          cacheControl: analysis.cacheControl,
        ),
    ];

    return switch (message.role) {
      ChatRole.system => _convertSystemMessage(blocks),
      ChatRole.assistant => _convertAssistantMessage(
          blocks,
          toolDescriptors: toolDescriptors,
        ),
      ChatRole.user => _convertUserMessage(
          blocks,
          toolDescriptors: toolDescriptors,
        ),
    };
  }

  List<core.PromptMessage> convertTrackedLegacyMessage(
    ChatMessage message, {
    required Map<String, _AnthropicCompatToolDescriptor> toolDescriptors,
    required List<core.PromptMessage> Function(ChatMessage message)
        convertTrackedMessage,
  }) {
    final converted = convertTrackedMessage(message);

    if (message.messageType case ToolUseMessage(:final toolCalls)) {
      for (final toolCall in toolCalls) {
        toolDescriptors[toolCall.id] = _AnthropicCompatToolDescriptor(
          toolName: toolCall.function.name,
        );
      }
    }

    return converted;
  }

  List<core.PromptMessage> _convertSystemMessage(
    List<AnthropicLegacyPromptBlock> blocks,
  ) {
    if (blocks.isEmpty) {
      return const [];
    }

    return [
      core.SystemPromptMessage(
        parts: [
          for (final block in blocks) _promptParts.convertPromptPart(block),
        ],
      ),
    ];
  }

  List<core.PromptMessage> _convertAssistantMessage(
    List<AnthropicLegacyPromptBlock> blocks, {
    required Map<String, _AnthropicCompatToolDescriptor> toolDescriptors,
  }) {
    if (blocks.isEmpty) {
      return const [];
    }

    final parts = <core.PromptPart>[
      for (final block in blocks)
        _promptParts.convertAssistantPromptPart(
          block,
          toolDescriptors: toolDescriptors,
        ),
    ];

    return [
      core.AssistantPromptMessage(parts: parts),
    ];
  }

  List<core.PromptMessage> _convertUserMessage(
    List<AnthropicLegacyPromptBlock> blocks, {
    required Map<String, _AnthropicCompatToolDescriptor> toolDescriptors,
  }) {
    if (blocks.isEmpty) {
      return const [];
    }

    final prompt = <core.PromptMessage>[];
    final userParts = <core.PromptPart>[];

    void flushUserParts() {
      if (userParts.isEmpty) {
        return;
      }

      prompt.add(
        core.UserPromptMessage(
          parts: List<core.PromptPart>.from(userParts),
        ),
      );
      userParts.clear();
    }

    for (final block in blocks) {
      if (block is AnthropicLegacyToolResultBlock) {
        flushUserParts();
        prompt.add(
          _toolResults.convertToolResultMessage(
            block,
            toolDescriptors: toolDescriptors,
          ),
        );
        continue;
      }

      userParts.add(_promptParts.convertPromptPart(block));
    }

    flushUserParts();
    return prompt;
  }
}
