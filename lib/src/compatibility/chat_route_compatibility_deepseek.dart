part of 'chat_route_compatibility.dart';

bool canUseDeepSeekChatBridge(
  LLMConfig config,
  List<ChatMessage> messages,
  List<Tool>? tools,
) {
  final effectiveTools = tools ?? config.tools;
  if (_hasNonFunctionTools(effectiveTools) ||
      _hasNamedMessages(messages) ||
      _hasMessageDecorators(messages) ||
      !_systemMessagesLead(messages)) {
    return false;
  }

  if (config.model != 'deepseek-chat') {
    return false;
  }

  if (config.stopSequences case final stopSequences?
      when stopSequences.isNotEmpty) {
    return false;
  }

  if (config.user != null || config.serviceTier != null) {
    return false;
  }

  if (config.systemPrompt != null &&
      config.systemPrompt!.isNotEmpty &&
      messages.any((message) => message.role == ChatRole.system)) {
    return false;
  }

  if (_hasUnsupportedExtensions(
    config: config,
    allowedKeys: _httpExtensionKeys,
    allowedProviderOptions: {
      LegacyProviderOptionNamespaces.deepseek: {
        LegacyExtensionKeys.logprobs,
        LegacyExtensionKeys.deepSeekTopLogprobs,
        LegacyExtensionKeys.deepSeekFrequencyPenalty,
        LegacyExtensionKeys.deepSeekPresencePenalty,
        LegacyExtensionKeys.deepSeekResponseFormat,
      },
    },
  )) {
    return false;
  }

  for (final message in messages) {
    switch (message.messageType) {
      case TextMessage():
        break;
      case ToolUseMessage():
        if (message.role != ChatRole.assistant) {
          return false;
        }
      case ToolResultMessage():
        if (message.role != ChatRole.user) {
          return false;
        }
      case ImageMessage():
      case ImageUrlMessage():
      case FileMessage():
        return false;
    }
  }

  return true;
}
