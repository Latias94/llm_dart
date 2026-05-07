part of 'anthropic_compat_support.dart';

final class _AnthropicCompatMessageConverter {
  static const _roleConverter = _AnthropicCompatMessageRoleConverter();

  const _AnthropicCompatMessageConverter();

  List<core.PromptMessage> convertMessages({
    required List<ChatMessage> messages,
    required String? systemPrompt,
    required List<core.PromptMessage> Function(ChatMessage message)
        convertTrackedMessage,
  }) {
    final prompt = <core.PromptMessage>[];
    final toolDescriptors = <String, _AnthropicCompatToolDescriptor>{};
    final hasSystemMessage =
        messages.any((message) => message.role == ChatRole.system);

    if (!hasSystemMessage && systemPrompt != null && systemPrompt.isNotEmpty) {
      prompt.add(core.SystemPromptMessage.text(systemPrompt));
    }

    for (var index = 0; index < messages.length; index++) {
      final message = messages[index];
      if (!message.extensions.containsKey('anthropic')) {
        prompt.addAll(
          _roleConverter.convertTrackedLegacyMessage(
            message,
            toolDescriptors: toolDescriptors,
            convertTrackedMessage: convertTrackedMessage,
          ),
        );
        continue;
      }

      prompt.addAll(
        _roleConverter.convertAnthropicLegacyMessage(
          message,
          messageIndex: index,
          toolDescriptors: toolDescriptors,
        ),
      );
    }

    return prompt;
  }
}
