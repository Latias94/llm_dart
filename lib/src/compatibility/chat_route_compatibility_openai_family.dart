part of 'chat_route_compatibility.dart';

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
      'webSearchConfig',
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
