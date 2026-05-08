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
    allowlist: _httpOnlyChatBridgeExtensionAllowlist,
  )) {
    return false;
  }

  for (final message in messages) {
    if (message.messageType is! TextMessage) {
      return false;
    }
  }

  return true;
}
