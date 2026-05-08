part of 'chat_route_compatibility.dart';

bool canUseOpenAIChatBridge(
  LLMConfig config,
  List<ChatMessage> messages,
  List<Tool>? tools,
) {
  final effectiveTools = tools ?? config.tools;
  if (_hasNonFunctionTools(effectiveTools) ||
      !_canMapOpenAIBuiltInTools(
        getLegacyProviderOption<List<OpenAIBuiltInTool>>(
          config,
          LegacyProviderOptionNamespaces.openai,
          LegacyExtensionKeys.builtInTools,
        ),
      )) {
    return false;
  }

  if (_hasMessageDecorators(messages) || !_systemMessagesLead(messages)) {
    return false;
  }

  if (_hasUnsupportedExtensions(
    config: config,
    allowedKeys: {
      ..._httpExtensionKeys,
      LegacyExtensionKeys.useResponsesApi,
      LegacyExtensionKeys.previousResponseId,
      LegacyExtensionKeys.parallelToolCalls,
      LegacyExtensionKeys.verbosity,
      LegacyExtensionKeys.reasoningEffort,
      LegacyExtensionKeys.jsonSchema,
      LegacyExtensionKeys.builtInTools,
    },
    allowedProviderOptions: {
      LegacyProviderOptionNamespaces.openai: {
        LegacyExtensionKeys.useResponsesApi,
        LegacyExtensionKeys.previousResponseId,
        LegacyExtensionKeys.parallelToolCalls,
        LegacyExtensionKeys.verbosity,
        LegacyExtensionKeys.reasoningEffort,
        LegacyExtensionKeys.jsonSchema,
        LegacyExtensionKeys.builtInTools,
      },
    },
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
