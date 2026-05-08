part of 'chat_route_compatibility.dart';

bool canUseGroqChatBridge(
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
