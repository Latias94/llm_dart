part of 'chat_route_compatibility.dart';

bool canUsePhindChatBridge(
  LLMConfig config,
  List<ChatMessage> messages,
  List<Tool>? tools,
) {
  if (!_isOpenAICompatiblePhindBaseUrl(config.baseUrl)) {
    return false;
  }

  if (_hasOpenAICompatibleTextShellConflict(
    config: config,
    messages: messages,
    tools: tools,
    allowlist: _httpOnlyChatBridgeExtensionAllowlist,
    allowFunctionTools: false,
  )) {
    return false;
  }

  return true;
}

bool _isOpenAICompatiblePhindBaseUrl(String baseUrl) {
  final uri = Uri.tryParse(baseUrl);
  return uri?.host == 'api.phind.com';
}
