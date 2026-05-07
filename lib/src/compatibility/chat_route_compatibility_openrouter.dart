part of 'chat_route_compatibility.dart';

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
    allowedKeys: {
      ..._httpExtensionKeys,
      LegacyExtensionKeys.parallelToolCalls,
      LegacyExtensionKeys.verbosity,
      LegacyExtensionKeys.jsonSchema,
      LegacyExtensionKeys.webSearchEnabled,
      LegacyExtensionKeys.webSearchConfig,
    },
    allowedProviderOptions: {
      LegacyProviderOptionNamespaces.openrouter: {
        LegacyExtensionKeys.parallelToolCalls,
        LegacyExtensionKeys.verbosity,
        LegacyExtensionKeys.webSearchConfig,
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
