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
