part of 'chat_route_compatibility.dart';

const _googleChatBridgeOptionKeys = {
  LegacyExtensionKeys.jsonSchema,
  LegacyExtensionKeys.reasoningEffort,
  LegacyExtensionKeys.thinkingBudgetTokens,
  LegacyExtensionKeys.includeThoughts,
  LegacyExtensionKeys.enableImageGeneration,
  LegacyExtensionKeys.responseModalities,
  LegacyExtensionKeys.safetySettings,
  LegacyExtensionKeys.candidateCount,
  LegacyExtensionKeys.webSearchEnabled,
  LegacyExtensionKeys.webSearchConfig,
};
const _googleChatBridgeExtensionAllowlist = _ChatBridgeExtensionAllowlist(
  flatKeys: {
    ..._httpExtensionKeys,
    ..._googleChatBridgeOptionKeys,
  },
  providerOptions: {
    LegacyProviderOptionNamespaces.google: _googleChatBridgeOptionKeys,
  },
);

const _anthropicChatBridgeOptionKeys = {
  LegacyExtensionKeys.reasoning,
  LegacyExtensionKeys.thinkingBudgetTokens,
  LegacyExtensionKeys.interleavedThinking,
  LegacyExtensionKeys.metadata,
  LegacyExtensionKeys.container,
  LegacyExtensionKeys.mcpServers,
  LegacyExtensionKeys.webSearchEnabled,
  LegacyExtensionKeys.webSearchConfig,
};
const _anthropicChatBridgeExtensionAllowlist = _ChatBridgeExtensionAllowlist(
  flatKeys: {
    ..._httpExtensionKeys,
    ..._anthropicChatBridgeOptionKeys,
  },
  providerOptions: {
    LegacyProviderOptionNamespaces.anthropic: _anthropicChatBridgeOptionKeys,
  },
);

bool canUseGoogleChatBridge(
  LLMConfig config,
  List<ChatMessage> messages,
  List<Tool>? tools,
) {
  if (_hasMessageDecorators(messages) || !_systemMessagesLead(messages)) {
    return false;
  }

  if (_hasUnsupportedExtensions(
    config: config,
    allowlist: _googleChatBridgeExtensionAllowlist,
  )) {
    return false;
  }

  final options = legacyProviderOptionView(
    config,
    LegacyProviderOptionNamespaces.google,
  );
  final googleOptions = legacyGoogleOptions(options);
  if (!googleOptions.hasChatBridgeSupportedResponseModalities) {
    return false;
  }

  if (googleOptions.hasStructuredOutputChatBridgeConflict) {
    return false;
  }

  for (final message in messages) {
    switch (message.messageType) {
      case TextMessage():
        break;
      case ImageMessage():
      case ImageUrlMessage():
        if (message.role != ChatRole.user) {
          return false;
        }
      case FileMessage():
        if (message.role == ChatRole.system) {
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

bool canUseAnthropicChatBridge(
  LLMConfig config,
  List<ChatMessage> messages,
  List<Tool>? tools,
) {
  if (_hasNamedMessages(messages) || !_systemMessagesLead(messages)) {
    return false;
  }

  if (_hasUnsupportedExtensions(
    config: config,
    allowlist: _anthropicChatBridgeExtensionAllowlist,
  )) {
    return false;
  }

  if (_hasAnthropicParallelToolOverride(config.toolChoice)) {
    return false;
  }

  late final AnthropicLegacyExtensionAnalysis legacyExtensionAnalysis;
  try {
    legacyExtensionAnalysis = analyzeAnthropicLegacyMessageExtensions(messages);
  } catch (_) {
    return false;
  }

  final effectiveTools = <Tool>[
    ...legacyExtensionAnalysis.messageTools,
    ...?(tools ?? config.tools),
  ];
  if (effectiveTools.isNotEmpty &&
      legacyExtensionAnalysis.hasAmbiguousToolCacheControl) {
    return false;
  }

  for (final message in messages) {
    switch (message.messageType) {
      case TextMessage():
        break;
      case ImageMessage():
        if (message.role != ChatRole.user) {
          return false;
        }
      case ImageUrlMessage(:final url):
        if (message.role != ChatRole.user) {
          return false;
        }

        final uri = Uri.tryParse(url);
        if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
          return false;
        }
      case FileMessage(:final mime):
        if (message.role != ChatRole.user) {
          return false;
        }

        if (mime.mimeType != 'application/pdf' &&
            mime.mimeType != 'text/plain') {
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
