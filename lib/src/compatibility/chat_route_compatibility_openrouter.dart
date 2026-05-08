part of 'chat_route_compatibility.dart';

const _openRouterChatBridgeOptionKeys = {
  LegacyExtensionKeys.parallelToolCalls,
  LegacyExtensionKeys.verbosity,
  LegacyExtensionKeys.jsonSchema,
  LegacyExtensionKeys.webSearchEnabled,
  LegacyExtensionKeys.webSearchConfig,
};
const _openRouterChatBridgeExtensionAllowlist = _ChatBridgeExtensionAllowlist(
  flatKeys: {
    ..._httpExtensionKeys,
    ..._openRouterChatBridgeOptionKeys,
  },
  providerOptions: {
    LegacyProviderOptionNamespaces.openrouter: _openRouterChatBridgeOptionKeys,
  },
);

bool canUseOpenRouterChatBridge(
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

  if (config.model.contains('deepseek-r1')) {
    return false;
  }

  if (config.user != null) {
    return false;
  }

  if (_hasUnsupportedExtensions(
    config: config,
    allowlist: _openRouterChatBridgeExtensionAllowlist,
  )) {
    return false;
  }

  if (_hasUnsupportedTextToolReplayMessages(messages)) {
    return false;
  }

  return true;
}
