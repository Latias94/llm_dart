part of 'chat_route_compatibility.dart';

bool canUseGroqChatBridge(
  LLMConfig config,
  List<ChatMessage> messages,
  List<Tool>? tools,
) {
  if (_hasOpenAICompatibleTextShellConflict(
    config: config,
    messages: messages,
    tools: tools,
    allowlist: _httpOnlyChatBridgeExtensionAllowlist,
  )) {
    return false;
  }

  return true;
}
