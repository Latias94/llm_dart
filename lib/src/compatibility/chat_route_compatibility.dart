import '../../core/config.dart';
import '../../core/web_search.dart';
import '../../models/chat_models.dart';
import '../../models/tool_models.dart';
import '../../providers/openai/builtin_tools.dart';
import '../../providers/xai/config.dart';
import 'anthropic_legacy_extensions.dart';

const Set<String> _httpExtensionKeys = {
  'customHeaders',
  'connectionTimeout',
  'receiveTimeout',
  'sendTimeout',
  'enableHttpLogging',
  'httpProxy',
  'bypassSSLVerification',
  'sslCertificate',
  'customTransportClient',
  'customDio',
};

bool canUseOpenAIChatBridge(
  LLMConfig config,
  List<ChatMessage> messages,
  List<Tool>? tools,
) {
  final effectiveTools = tools ?? config.tools;
  if (_hasNonFunctionTools(effectiveTools) ||
      !_canMapOpenAIBuiltInTools(
        config.getExtension<List<OpenAIBuiltInTool>>('builtInTools'),
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
      'useResponsesAPI',
      'previousResponseId',
      'parallelToolCalls',
      'verbosity',
      'jsonSchema',
      'builtInTools',
    },
  )) {
    return false;
  }

  for (final message in messages) {
    final messageType = message.messageType;
    if (messageType is! TextMessage) {
      return false;
    }
  }

  return true;
}

bool canUseDeepSeekChatBridge(
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

  if (config.model != 'deepseek-chat') {
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
    allowedKeys: _httpExtensionKeys,
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
      'parallelToolCalls',
      'verbosity',
      'jsonSchema',
      'webSearchEnabled',
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
    allowedKeys: _httpExtensionKeys,
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

bool canUseXAIChatBridge(
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
    allowedKeys: {
      ..._httpExtensionKeys,
      'jsonSchema',
      'liveSearch',
      'searchParameters',
      'webSearchEnabled',
      'webSearchConfig',
    },
  )) {
    return false;
  }

  final legacyConfig = XAIConfig.fromLLMConfig(config);
  if (!_canMapCompatXAILiveSearch(legacyConfig)) {
    return false;
  }

  for (final message in messages) {
    if (message.messageType is! TextMessage) {
      return false;
    }
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
    allowedKeys: {
      ..._httpExtensionKeys,
      'jsonSchema',
      'reasoningEffort',
      'thinkingBudgetTokens',
      'includeThoughts',
      'enableImageGeneration',
      'responseModalities',
      'safetySettings',
      'candidateCount',
      'webSearchEnabled',
      'webSearchConfig',
    },
  )) {
    return false;
  }

  final responseModalities =
      config.getExtension<List<dynamic>>('responseModalities');
  if (responseModalities != null &&
      responseModalities.any(
        (value) => value != 'TEXT' && value != 'IMAGE',
      )) {
    return false;
  }

  if (_hasGoogleStructuredOutputConflict(config, responseModalities)) {
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
    allowedKeys: {
      ..._httpExtensionKeys,
      'reasoning',
      'thinkingBudgetTokens',
      'interleavedThinking',
      'metadata',
      'container',
      'mcpServers',
      'webSearchEnabled',
      'webSearchConfig',
    },
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
  required Set<String> allowedKeys,
}) {
  for (final key in config.extensions.keys) {
    if (!allowedKeys.contains(key)) {
      return true;
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

bool _hasGoogleStructuredOutputConflict(
  LLMConfig config,
  List<dynamic>? responseModalities,
) {
  final structuredOutput =
      config.getExtension<StructuredOutputFormat>('jsonSchema');
  if (structuredOutput == null) {
    return false;
  }

  if (config.getExtension<bool>('enableImageGeneration') == true) {
    return true;
  }

  if (responseModalities != null &&
      responseModalities
          .any((value) => value.toString().toUpperCase() != 'TEXT')) {
    return true;
  }

  return false;
}

bool _hasMessageDecorators(List<ChatMessage> messages) {
  return messages.any(
    (message) => message.name != null || message.extensions.isNotEmpty,
  );
}

bool _hasNamedMessages(List<ChatMessage> messages) {
  return messages.any((message) => message.name != null);
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

bool hasEnabledWebSearch(LLMConfig config) {
  return config.getExtension<bool>('webSearchEnabled') == true ||
      config.getExtension<WebSearchConfig>('webSearchConfig') != null;
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

  final fromDate = _parseCompatDate(searchParameters.fromDate);
  if (searchParameters.fromDate != null && fromDate == null) {
    return false;
  }

  final toDate = _parseCompatDate(searchParameters.toDate);
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

DateTime? _parseCompatDate(String? value) {
  if (value == null) {
    return null;
  }

  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) {
    return null;
  }

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);

  try {
    final parsed = DateTime.utc(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  } catch (_) {
    return null;
  }
}
