part of 'chat_route_compatibility.dart';

const _openAIChatBridgeOptionKeys = {
  LegacyExtensionKeys.useResponsesApi,
  LegacyExtensionKeys.previousResponseId,
  LegacyExtensionKeys.parallelToolCalls,
  LegacyExtensionKeys.verbosity,
  LegacyExtensionKeys.reasoningEffort,
  LegacyExtensionKeys.jsonSchema,
  LegacyExtensionKeys.builtInTools,
};
const _openAIChatBridgeExtensionAllowlist = _ChatBridgeExtensionAllowlist(
  flatKeys: {
    ..._httpExtensionKeys,
    ..._openAIChatBridgeOptionKeys,
  },
  providerOptions: {
    LegacyProviderOptionNamespaces.openai: _openAIChatBridgeOptionKeys,
  },
);

bool canUseOpenAIChatBridge(
  LLMConfig config,
  List<ChatMessage> messages,
  List<Tool>? tools,
) {
  final effectiveTools = tools ?? config.tools;
  final options = legacyProviderOptionView(
    config,
    LegacyProviderOptionNamespaces.openai,
  );
  final familyOptions = legacyOpenAIFamilyOptions(options);
  if (_hasNonFunctionTools(effectiveTools) ||
      !_canMapOpenAIBuiltInTools(familyOptions.builtInTools)) {
    return false;
  }

  if (_hasMessageDecorators(messages) || !_systemMessagesLead(messages)) {
    return false;
  }

  if (_hasUnsupportedExtensions(
    config: config,
    allowlist: _openAIChatBridgeExtensionAllowlist,
  )) {
    return false;
  }

  for (final message in messages) {
    switch (message.messageType) {
      case TextMessage():
        break;
      case ImageMessage():
      case ImageUrlMessage():
      case FileMessage():
        if (message.role != ChatRole.user) {
          return false;
        }
      case ToolUseMessage():
        if (message.role != ChatRole.assistant) {
          return false;
        }
      case ToolResultMessage():
        if (message.role != ChatRole.user) {
          return false;
        }
    }
  }

  return true;
}
