import '../../core/config.dart';
import '../../models/chat_models.dart';
import '../../models/tool_models.dart';
import '../../providers/openai/builtin_tools.dart';
import '../../providers/xai/config.dart';
import 'compat_value_utils.dart';
import 'config/legacy_config_keys.dart';
import 'config/legacy_google_options.dart';
import 'config/legacy_openai_options.dart';
import 'config/legacy_provider_options.dart';
import 'providers/openai_family_compat_xai_config.dart';
import 'anthropic_legacy_extensions.dart';

const Set<String> _httpExtensionKeys = legacyHttpExtensionKeys;
const _httpOnlyChatBridgeExtensionAllowlist = _ChatBridgeExtensionAllowlist(
  flatKeys: _httpExtensionKeys,
);

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

const _xaiChatBridgeFlatOptionKeys = {
  LegacyExtensionKeys.jsonSchema,
  LegacyExtensionKeys.xaiLiveSearch,
  LegacyExtensionKeys.xaiSearchParameters,
  LegacyExtensionKeys.webSearchEnabled,
  LegacyExtensionKeys.webSearchConfig,
};
const _xaiChatBridgeProviderOptionKeys = {
  ..._xaiChatBridgeFlatOptionKeys,
  LegacyExtensionKeys.embeddingEncodingFormat,
  LegacyExtensionKeys.embeddingDimensions,
};
const _xaiChatBridgeExtensionAllowlist = _ChatBridgeExtensionAllowlist(
  flatKeys: {
    ..._httpExtensionKeys,
    ..._xaiChatBridgeFlatOptionKeys,
  },
  providerOptions: {
    LegacyProviderOptionNamespaces.xai: _xaiChatBridgeProviderOptionKeys,
  },
);

final class _ChatBridgeExtensionAllowlist {
  final Set<String> flatKeys;
  final Map<String, Set<String>> providerOptions;

  const _ChatBridgeExtensionAllowlist({
    required this.flatKeys,
    this.providerOptions = const {},
  });
}

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

bool canUseXAIChatBridge(
  LLMConfig config,
  List<ChatMessage> messages,
  List<Tool>? tools,
) {
  if (_hasOpenAICompatibleTextShellConflict(
    config: config,
    messages: messages,
    tools: tools,
    allowlist: _xaiChatBridgeExtensionAllowlist,
  )) {
    return false;
  }

  final legacyConfig = createLegacyXAIConfig(config);
  if (!_canMapCompatXAILiveSearch(legacyConfig)) {
    return false;
  }

  return true;
}

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

bool _hasUnsupportedExtensions({
  required LLMConfig config,
  required _ChatBridgeExtensionAllowlist allowlist,
}) {
  for (final key in config.extensions.keys) {
    if (key == legacyProviderOptionsBagKey) {
      continue;
    }

    if (!allowlist.flatKeys.contains(key)) {
      return true;
    }
  }

  if (_hasUnsupportedProviderOptions(
    config: config,
    allowedProviderOptions: allowlist.providerOptions,
  )) {
    return true;
  }

  return false;
}

bool _hasUnsupportedProviderOptions({
  required LLMConfig config,
  required Map<String, Set<String>> allowedProviderOptions,
}) {
  if (!config.extensions.containsKey(legacyProviderOptionsBagKey)) {
    return false;
  }

  final providerOptions = legacyProviderOptionsBagOrNull(config);
  if (providerOptions == null) {
    return true;
  }

  for (final entry in providerOptions.entries) {
    final allowedKeys = allowedProviderOptions[entry.key];
    final namespaceOptions = legacyProviderOptionsNamespaceOrNull(
      config,
      entry.key,
    );

    if (allowedKeys == null || namespaceOptions == null) {
      return true;
    }

    for (final key in namespaceOptions.keys) {
      if (!allowedKeys.contains(key)) {
        return true;
      }
    }
  }

  return false;
}

bool _hasNonFunctionTools(List<Tool>? tools) {
  if (tools == null) {
    return false;
  }

  return tools.any((tool) => tool.toolType != 'function');
}

bool _canMapOpenAIBuiltInTools(List<OpenAIBuiltInTool>? tools) {
  if (tools == null) {
    return true;
  }

  return tools.every(
    (tool) =>
        tool is OpenAIWebSearchTool ||
        tool is OpenAIFileSearchTool ||
        tool is OpenAIComputerUseTool,
  );
}

bool _hasMessageDecorators(List<ChatMessage> messages) {
  return messages.any(
    (message) => message.name != null || message.extensions.isNotEmpty,
  );
}

bool _hasNamedMessages(List<ChatMessage> messages) {
  return messages.any((message) => message.name != null);
}

bool _hasOpenAICompatibleShellRequestConflict(
  LLMConfig config,
  List<ChatMessage> messages,
) {
  if (config.stopSequences case final stopSequences?
      when stopSequences.isNotEmpty) {
    return true;
  }

  if (config.user != null || config.serviceTier != null) {
    return true;
  }

  if (config.systemPrompt != null &&
      config.systemPrompt!.isNotEmpty &&
      messages.any((message) => message.role == ChatRole.system)) {
    return true;
  }

  return false;
}

bool _hasOpenAICompatibleTextShellConflict({
  required LLMConfig config,
  required List<ChatMessage> messages,
  required List<Tool>? tools,
  required _ChatBridgeExtensionAllowlist allowlist,
  bool allowFunctionTools = true,
  bool allowTextToolReplayMessages = false,
}) {
  final effectiveTools = tools ?? config.tools;
  final hasUnsupportedTools = allowFunctionTools
      ? _hasNonFunctionTools(effectiveTools)
      : effectiveTools != null && effectiveTools.isNotEmpty;

  if (hasUnsupportedTools ||
      _hasMessageDecorators(messages) ||
      !_systemMessagesLead(messages)) {
    return true;
  }

  if (_hasOpenAICompatibleShellRequestConflict(config, messages)) {
    return true;
  }

  if (_hasUnsupportedExtensions(
    config: config,
    allowlist: allowlist,
  )) {
    return true;
  }

  return allowTextToolReplayMessages
      ? _hasUnsupportedTextToolReplayMessages(messages)
      : _hasNonTextMessages(messages);
}

bool _hasNonTextMessages(List<ChatMessage> messages) {
  return messages.any((message) => message.messageType is! TextMessage);
}

bool _hasUnsupportedTextToolReplayMessages(List<ChatMessage> messages) {
  for (final message in messages) {
    switch (message.messageType) {
      case TextMessage():
        break;
      case ToolUseMessage():
        if (message.role != ChatRole.assistant) {
          return true;
        }
      case ToolResultMessage():
        if (message.role != ChatRole.user) {
          return true;
        }
      case ImageMessage():
      case ImageUrlMessage():
      case FileMessage():
        return true;
    }
  }

  return false;
}

bool _systemMessagesLead(List<ChatMessage> messages) {
  var sawConversationMessage = false;

  for (final message in messages) {
    if (message.role == ChatRole.system) {
      if (sawConversationMessage) {
        return false;
      }
      continue;
    }

    sawConversationMessage = true;
  }

  return true;
}

bool _hasAnthropicParallelToolOverride(ToolChoice? toolChoice) {
  return switch (toolChoice) {
    AnyToolChoice(:final disableParallelToolUse) =>
      disableParallelToolUse == true,
    AutoToolChoice(:final disableParallelToolUse) =>
      disableParallelToolUse == true,
    SpecificToolChoice(:final disableParallelToolUse) =>
      disableParallelToolUse == true,
    _ => false,
  };
}

bool _isOpenAICompatiblePhindBaseUrl(String baseUrl) {
  final uri = Uri.tryParse(baseUrl);
  return uri?.host == 'api.phind.com';
}

bool _canMapCompatXAILiveSearch(XAIConfig config) {
  final searchParameters = config.searchParameters;
  if (searchParameters == null) {
    return true;
  }

  if (!_isSupportedCompatXAISearchMode(searchParameters.mode)) {
    return false;
  }

  if (!_hasSupportedCompatXAISources(searchParameters.sources)) {
    return false;
  }

  if (searchParameters.maxSearchResults case final maxResults?
      when maxResults < 1 || maxResults > 50) {
    return false;
  }

  final fromDate = parseCompatUtcDate(searchParameters.fromDate);
  if (searchParameters.fromDate != null && fromDate == null) {
    return false;
  }

  final toDate = parseCompatUtcDate(searchParameters.toDate);
  if (searchParameters.toDate != null && toDate == null) {
    return false;
  }

  if (fromDate != null && toDate != null && toDate.isBefore(fromDate)) {
    return false;
  }

  return true;
}

bool _isSupportedCompatXAISearchMode(String? mode) {
  return switch (mode) {
    null || 'auto' || 'always' || 'never' || 'on' || 'off' => true,
    _ => false,
  };
}

bool _hasSupportedCompatXAISources(List<SearchSource>? sources) {
  if (sources == null || sources.isEmpty) {
    return true;
  }

  return sources.every(
    (source) => source.sourceType == 'web' || source.sourceType == 'news',
  );
}
