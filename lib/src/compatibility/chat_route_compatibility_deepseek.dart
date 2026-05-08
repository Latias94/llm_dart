part of 'chat_route_compatibility.dart';

const _deepSeekChatBridgeProviderOptionKeys = {
  LegacyExtensionKeys.logprobs,
  LegacyExtensionKeys.deepSeekTopLogprobs,
  LegacyExtensionKeys.deepSeekFrequencyPenalty,
  LegacyExtensionKeys.deepSeekPresencePenalty,
  LegacyExtensionKeys.deepSeekResponseFormat,
};
const _deepSeekChatBridgeExtensionAllowlist = _ChatBridgeExtensionAllowlist(
  flatKeys: _httpExtensionKeys,
  providerOptions: {
    LegacyProviderOptionNamespaces.deepseek:
        _deepSeekChatBridgeProviderOptionKeys,
  },
);

bool canUseDeepSeekChatBridge(
  LLMConfig config,
  List<ChatMessage> messages,
  List<Tool>? tools,
) {
  if (config.model != 'deepseek-chat') {
    return false;
  }

  if (_hasOpenAICompatibleTextShellConflict(
    config: config,
    messages: messages,
    tools: tools,
    allowlist: _deepSeekChatBridgeExtensionAllowlist,
    allowTextToolReplayMessages: true,
  )) {
    return false;
  }

  return true;
}
