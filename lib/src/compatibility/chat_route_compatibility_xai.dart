part of 'chat_route_compatibility.dart';

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

  if (_hasOpenAICompatibleShellRequestConflict(config, messages)) {
    return false;
  }

  if (_hasUnsupportedExtensions(
    config: config,
    allowlist: _xaiChatBridgeExtensionAllowlist,
  )) {
    return false;
  }

  final legacyConfig = createLegacyXAIConfig(config);
  if (!_canMapCompatXAILiveSearch(legacyConfig)) {
    return false;
  }

  if (_hasNonTextMessages(messages)) {
    return false;
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
