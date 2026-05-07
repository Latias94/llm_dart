part of 'chat_route_compatibility.dart';

bool canUsePhindChatBridge(
  LLMConfig config,
  List<ChatMessage> messages,
  List<Tool>? tools,
) {
  final effectiveTools = tools ?? config.tools;
  if (effectiveTools != null && effectiveTools.isNotEmpty ||
      _hasNamedMessages(messages) ||
      _hasMessageDecorators(messages) ||
      !_systemMessagesLead(messages)) {
    return false;
  }

  if (!_isOpenAICompatiblePhindBaseUrl(config.baseUrl)) {
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
  )) {
    return false;
  }

  for (final message in messages) {
    switch (message.messageType) {
      case TextMessage():
        break;
      case ToolUseMessage():
        return false;
      case ToolResultMessage():
        return false;
      case ImageMessage():
      case ImageUrlMessage():
      case FileMessage():
        return false;
    }
  }

  return true;
}

bool _isOpenAICompatiblePhindBaseUrl(String baseUrl) {
  final uri = Uri.tryParse(baseUrl);
  return uri?.host == 'api.phind.com';
}
