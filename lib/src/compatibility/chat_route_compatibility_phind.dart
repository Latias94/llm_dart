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

  if (_hasOpenAICompatibleShellRequestConflict(config, messages)) {
    return false;
  }

  if (_hasUnsupportedExtensions(
    config: config,
    allowlist: _httpOnlyChatBridgeExtensionAllowlist,
  )) {
    return false;
  }

  if (_hasNonTextMessages(messages)) {
    return false;
  }

  return true;
}

bool _isOpenAICompatiblePhindBaseUrl(String baseUrl) {
  final uri = Uri.tryParse(baseUrl);
  return uri?.host == 'api.phind.com';
}
