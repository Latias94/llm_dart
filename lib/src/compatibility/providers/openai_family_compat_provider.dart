import 'package:llm_dart_core/llm_dart_core.dart' as core;
import 'package:llm_dart_openai/llm_dart_openai.dart' as modern_openai;

import '../../../core/capability.dart';
import '../../../core/config.dart';
import '../../../core/web_search.dart';
import '../../../models/chat_models.dart';
import '../../../models/tool_models.dart';
import '../../../providers/deepseek/config.dart';
import '../../../providers/deepseek/provider.dart';
import '../../../providers/groq/config.dart';
import '../../../providers/groq/provider.dart';
import '../../../providers/openai/builtin_tools.dart';
import '../../../providers/openai/config.dart';
import '../../../providers/xai/config.dart';
import '../../../providers/xai/provider.dart';
import '../../config/legacy_config_keys.dart';
import '../../config/legacy_provider_options.dart';
import '../chat_route_compatibility.dart';
import '../compat_transport.dart';
import '../legacy_chat_adapter.dart';
import 'compat_provider_support.dart';
import 'openai/bridge_support.dart';
import 'openai/provider_compat.dart';

ChatCapability buildCompatOpenAIProvider(LLMConfig config) {
  final legacyConfig = _toLegacyOpenAIConfig(config);

  return CompatOpenAIProvider(
    originalConfig: config,
    legacyConfig: legacyConfig,
    adapter: buildCompatOpenAIChatBridge(
      legacyConfig: legacyConfig,
      bridgeConfig: config,
    ),
  );
}

ChatCapability buildCompatDeepSeekProvider(LLMConfig config) {
  final legacyConfig = DeepSeekConfig.fromLLMConfig(config);
  final model = modern_openai.OpenAI(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    transport: createCompatTransport(config),
    profile: const modern_openai.DeepSeekProfile(),
  ).chatModel(config.model);

  return CompatDeepSeekProvider(
    originalConfig: config,
    legacyConfig: legacyConfig,
    adapter: LegacyChatCapabilityAdapter(
      model: model,
      config: config,
    ),
  );
}

ChatCapability buildCompatOpenRouterProvider(LLMConfig config) {
  final legacyConfig = _toLegacyOpenRouterConfig(config);
  final model = modern_openai.OpenAI(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    transport: createCompatTransport(config),
    profile: const modern_openai.OpenRouterProfile(),
  ).chatModel(
    config.model,
    settings: _buildCompatOpenRouterModelSettings(config),
  );

  return CompatOpenRouterProvider(
    originalConfig: config,
    legacyConfig: legacyConfig,
    adapter: LegacyChatCapabilityAdapter(
      model: model,
      config: config,
      providerOptions: modern_openai.OpenAIGenerateTextOptions(
        parallelToolCalls: getLegacyProviderOption<bool>(
          config,
          LegacyProviderOptionNamespaces.openrouter,
          LegacyExtensionKeys.parallelToolCalls,
        ),
        serviceTier: config.serviceTier?.value,
        verbosity: getLegacyProviderOption<String>(
          config,
          LegacyProviderOptionNamespaces.openrouter,
          LegacyExtensionKeys.verbosity,
        ),
      ),
    ),
  );
}

ChatCapability buildCompatGroqProvider(LLMConfig config) {
  final legacyConfig = GroqConfig.fromLLMConfig(config);
  final model = modern_openai.OpenAI(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    transport: createCompatTransport(config),
    profile: const modern_openai.GroqProfile(),
  ).chatModel(config.model);

  return CompatGroqProvider(
    originalConfig: config,
    legacyConfig: legacyConfig,
    adapter: LegacyChatCapabilityAdapter(
      model: model,
      config: config,
    ),
  );
}

ChatCapability buildCompatXAIProvider(LLMConfig config) {
  final legacyConfig = XAIConfig.fromLLMConfig(config);
  final model = modern_openai.OpenAI(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    transport: createCompatTransport(config),
    profile: const modern_openai.XAIProfile(),
  ).chatModel(config.model);

  return CompatXAIProvider(
    originalConfig: config,
    legacyConfig: legacyConfig,
    adapter: LegacyChatCapabilityAdapter(
      model: model,
      config: config,
      providerOptions: modern_openai.XAIGenerateTextOptions(
        common: const modern_openai.OpenAIGenerateTextOptions(),
        search: _buildCompatXAILiveSearchOptions(legacyConfig),
      ),
    ),
  );
}

final class CompatOpenAIProvider extends OpenAIProvider {
  final LLMConfig _originalConfig;
  final LegacyChatCapabilityAdapter _adapter;

  CompatOpenAIProvider({
    required LLMConfig originalConfig,
    required OpenAIConfig legacyConfig,
    required LegacyChatCapabilityAdapter adapter,
  })  : _originalConfig = originalConfig,
        _adapter = adapter,
        super(legacyConfig);

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    TransportCancellation? cancelToken,
  }) {
    return chatWithTools(messages, null, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) {
    return executeCompatChat(
      originalConfig: _originalConfig,
      messages: messages,
      tools: tools,
      canUseBridge: canUseOpenAIChatBridge,
      bridge: () => _adapter.chatWithTools(
        messages,
        tools,
        cancelToken: cancelToken,
      ),
      fallback: () => super.chatWithTools(
        messages,
        tools,
        cancelToken: cancelToken,
      ),
    );
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) {
    return executeCompatChatStream(
      originalConfig: _originalConfig,
      messages: messages,
      tools: tools,
      canUseBridge: canUseOpenAIChatBridge,
      bridge: () => _adapter.chatStream(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      ),
      fallback: () => super.chatStream(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      ),
    );
  }
}

final class CompatDeepSeekProvider extends DeepSeekProvider {
  final LLMConfig _originalConfig;
  final LegacyChatCapabilityAdapter _adapter;

  CompatDeepSeekProvider({
    required LLMConfig originalConfig,
    required DeepSeekConfig legacyConfig,
    required LegacyChatCapabilityAdapter adapter,
  })  : _originalConfig = originalConfig,
        _adapter = adapter,
        super(legacyConfig);

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    TransportCancellation? cancelToken,
  }) {
    return chatWithTools(messages, null, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) {
    return executeCompatChat(
      originalConfig: _originalConfig,
      messages: messages,
      tools: tools,
      canUseBridge: canUseDeepSeekChatBridge,
      bridge: () => _adapter.chatWithTools(
        messages,
        tools,
        cancelToken: cancelToken,
      ),
      fallback: () => super.chatWithTools(
        messages,
        tools,
        cancelToken: cancelToken,
      ),
    );
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) {
    return executeCompatChatStream(
      originalConfig: _originalConfig,
      messages: messages,
      tools: tools,
      canUseBridge: canUseDeepSeekChatBridge,
      bridge: () => _adapter.chatStream(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      ),
      fallback: () => super.chatStream(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      ),
    );
  }
}

final class CompatOpenRouterProvider extends OpenAIProvider {
  final LLMConfig _originalConfig;
  final LegacyChatCapabilityAdapter _adapter;

  CompatOpenRouterProvider({
    required LLMConfig originalConfig,
    required OpenAIConfig legacyConfig,
    required LegacyChatCapabilityAdapter adapter,
  })  : _originalConfig = originalConfig,
        _adapter = adapter,
        super(legacyConfig);

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    TransportCancellation? cancelToken,
  }) {
    return chatWithTools(messages, null, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) {
    return executeCompatChat(
      originalConfig: _originalConfig,
      messages: messages,
      tools: tools,
      canUseBridge: canUseOpenRouterChatBridge,
      bridge: () => _adapter.chatWithTools(
        messages,
        tools,
        cancelToken: cancelToken,
      ),
      fallback: () => super.chatWithTools(
        messages,
        tools,
        cancelToken: cancelToken,
      ),
    );
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) {
    return executeCompatChatStream(
      originalConfig: _originalConfig,
      messages: messages,
      tools: tools,
      canUseBridge: canUseOpenRouterChatBridge,
      bridge: () => _adapter.chatStream(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      ),
      fallback: () => super.chatStream(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      ),
    );
  }
}

final class CompatGroqProvider extends GroqProvider {
  final LLMConfig _originalConfig;
  final LegacyChatCapabilityAdapter _adapter;

  CompatGroqProvider({
    required LLMConfig originalConfig,
    required GroqConfig legacyConfig,
    required LegacyChatCapabilityAdapter adapter,
  })  : _originalConfig = originalConfig,
        _adapter = adapter,
        super(legacyConfig);

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    TransportCancellation? cancelToken,
  }) {
    return chatWithTools(messages, null, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) {
    return executeCompatChat(
      originalConfig: _originalConfig,
      messages: messages,
      tools: tools,
      canUseBridge: canUseGroqChatBridge,
      bridge: () => _adapter.chatWithTools(
        messages,
        tools,
        cancelToken: cancelToken,
      ),
      fallback: () => super.chatWithTools(
        messages,
        tools,
        cancelToken: cancelToken,
      ),
    );
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) {
    return executeCompatChatStream(
      originalConfig: _originalConfig,
      messages: messages,
      tools: tools,
      canUseBridge: canUseGroqChatBridge,
      bridge: () => _adapter.chatStream(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      ),
      fallback: () => super.chatStream(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      ),
    );
  }
}

final class CompatXAIProvider extends XAIProvider {
  final LLMConfig _originalConfig;
  final LegacyChatCapabilityAdapter _adapter;

  CompatXAIProvider({
    required LLMConfig originalConfig,
    required XAIConfig legacyConfig,
    required LegacyChatCapabilityAdapter adapter,
  })  : _originalConfig = originalConfig,
        _adapter = adapter,
        super(legacyConfig);

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    TransportCancellation? cancelToken,
  }) {
    return chatWithTools(messages, null, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) {
    return executeCompatChat(
      originalConfig: _originalConfig,
      messages: messages,
      tools: tools,
      canUseBridge: canUseXAIChatBridge,
      bridge: () => _adapter.chatWithTools(
        messages,
        tools,
        cancelToken: cancelToken,
      ),
      fallback: () => super.chatWithTools(
        messages,
        tools,
        cancelToken: cancelToken,
      ),
    );
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) {
    return executeCompatChatStream(
      originalConfig: _originalConfig,
      messages: messages,
      tools: tools,
      canUseBridge: canUseXAIChatBridge,
      bridge: () => _adapter.chatStream(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      ),
      fallback: () => super.chatStream(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      ),
    );
  }
}

OpenAIConfig _toLegacyOpenAIConfig(LLMConfig config) {
  var model = config.model;
  final webSearchEnabled =
      config.getExtension<bool>(LegacyExtensionKeys.webSearchEnabled) == true;
  final webSearchConfig = getLegacyProviderOption<WebSearchConfig>(
    config,
    LegacyProviderOptionNamespaces.openai,
    LegacyExtensionKeys.webSearchConfig,
  );
  if ((webSearchEnabled || webSearchConfig != null) &&
      !_isOpenAISearchModel(model)) {
    model = _openAISearchModelFor(model);
  }

  return OpenAIConfig(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    model: model,
    maxTokens: config.maxTokens,
    temperature: config.temperature,
    systemPrompt: config.systemPrompt,
    timeout: config.timeout,
    topP: config.topP,
    topK: config.topK,
    tools: config.tools,
    toolChoice: config.toolChoice,
    reasoningEffort: ReasoningEffort.fromString(
      compatStringValue(config.extensions['reasoningEffort']),
    ),
    jsonSchema: config.getExtension<StructuredOutputFormat>('jsonSchema'),
    voice: config.getExtension<String>('voice'),
    embeddingEncodingFormat:
        config.getExtension<String>('embeddingEncodingFormat'),
    embeddingDimensions: config.getExtension<int>('embeddingDimensions'),
    stopSequences: config.stopSequences,
    user: config.user,
    serviceTier: config.serviceTier,
    useResponsesAPI: getLegacyProviderOption<bool>(
          config,
          LegacyProviderOptionNamespaces.openai,
          LegacyExtensionKeys.useResponsesApi,
        ) ??
        false,
    previousResponseId: getLegacyProviderOption<String>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.previousResponseId,
    ),
    builtInTools: getLegacyProviderOption<List<OpenAIBuiltInTool>>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.builtInTools,
    ),
    originalConfig: config,
  );
}

OpenAIConfig _toLegacyOpenRouterConfig(LLMConfig config) {
  var model = config.model;
  final webSearchEnabled =
      config.getExtension<bool>(LegacyExtensionKeys.webSearchEnabled) == true;
  final webSearchConfig = getLegacyProviderOption<WebSearchConfig>(
    config,
    LegacyProviderOptionNamespaces.openrouter,
    LegacyExtensionKeys.webSearchConfig,
  );
  if ((webSearchEnabled || webSearchConfig != null) &&
      !model.endsWith(':online')) {
    model = '$model:online';
  }

  return OpenAIConfig(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    model: model,
    maxTokens: config.maxTokens,
    temperature: config.temperature,
    systemPrompt: config.systemPrompt,
    timeout: config.timeout,
    topP: config.topP,
    topK: config.topK,
    tools: config.tools,
    toolChoice: config.toolChoice,
    jsonSchema: config.getExtension<StructuredOutputFormat>('jsonSchema'),
    stopSequences: config.stopSequences,
    user: config.user,
    serviceTier: config.serviceTier,
    useResponsesAPI: getLegacyProviderOption<bool>(
          config,
          LegacyProviderOptionNamespaces.openrouter,
          LegacyExtensionKeys.useResponsesApi,
        ) ??
        false,
    previousResponseId: getLegacyProviderOption<String>(
      config,
      LegacyProviderOptionNamespaces.openrouter,
      LegacyExtensionKeys.previousResponseId,
    ),
    builtInTools: getLegacyProviderOption<List<OpenAIBuiltInTool>>(
      config,
      LegacyProviderOptionNamespaces.openrouter,
      LegacyExtensionKeys.builtInTools,
    ),
    originalConfig: config,
  );
}

core.ProviderModelOptions _buildCompatOpenRouterModelSettings(
  LLMConfig config,
) {
  final webSearchEnabled =
      config.getExtension<bool>(LegacyExtensionKeys.webSearchEnabled) == true;
  final webSearchConfig = getLegacyProviderOption<WebSearchConfig>(
    config,
    LegacyProviderOptionNamespaces.openrouter,
    LegacyExtensionKeys.webSearchConfig,
  );
  if ((webSearchEnabled || webSearchConfig != null) &&
      !config.model.endsWith(':online')) {
    return const modern_openai.OpenRouterChatModelSettings(
      search: modern_openai.OpenRouterSearchOptions.onlineModel(),
    );
  }

  return const modern_openai.OpenAIChatModelSettings();
}

modern_openai.XAILiveSearchOptions? _buildCompatXAILiveSearchOptions(
  XAIConfig config,
) {
  final searchParameters = _normalizeCompatXAISearchParameters(config);
  if (searchParameters == null) {
    return null;
  }

  final mode = _mapCompatXAISearchMode(searchParameters.mode);
  final sources = _mapCompatXAISearchSources(searchParameters.sources);
  final fromDate = parseCompatUtcDate(searchParameters.fromDate);
  final toDate = parseCompatUtcDate(searchParameters.toDate);
  final maxSearchResults = searchParameters.maxSearchResults;

  if (mode == null ||
      sources == null ||
      (searchParameters.fromDate != null && fromDate == null) ||
      (searchParameters.toDate != null && toDate == null) ||
      (maxSearchResults != null &&
          (maxSearchResults < 1 || maxSearchResults > 50)) ||
      (fromDate != null && toDate != null && toDate.isBefore(fromDate))) {
    return null;
  }

  return modern_openai.XAILiveSearchOptions(
    mode: mode,
    fromDate: fromDate,
    toDate: toDate,
    maxSearchResults: maxSearchResults,
    sources: sources,
  );
}

SearchParameters? _normalizeCompatXAISearchParameters(XAIConfig config) {
  final searchParameters = config.searchParameters;
  if (searchParameters == null) {
    return config.liveSearch == true ? SearchParameters.webSearch() : null;
  }

  final sources = searchParameters.sources?.isNotEmpty == true
      ? searchParameters.sources
      : [const SearchSource(sourceType: 'web')];

  return SearchParameters(
    mode: searchParameters.mode ?? 'auto',
    sources: sources,
    maxSearchResults: searchParameters.maxSearchResults,
    fromDate: searchParameters.fromDate,
    toDate: searchParameters.toDate,
  );
}

modern_openai.XAISearchMode? _mapCompatXAISearchMode(String? mode) {
  return switch (mode) {
    null || 'auto' => modern_openai.XAISearchMode.auto,
    'always' || 'on' => modern_openai.XAISearchMode.on,
    'never' || 'off' => modern_openai.XAISearchMode.off,
    _ => null,
  };
}

List<modern_openai.XAISearchSource>? _mapCompatXAISearchSources(
  List<SearchSource>? sources,
) {
  if (sources == null || sources.isEmpty) {
    return const [modern_openai.XAIWebSearchSource()];
  }

  final mapped = <modern_openai.XAISearchSource>[];
  for (final source in sources) {
    switch (source.sourceType) {
      case 'web':
        mapped.add(
          modern_openai.XAIWebSearchSource(
            excludedWebsites: source.excludedWebsites ?? const [],
          ),
        );
        break;
      case 'news':
        mapped.add(
          modern_openai.XAINewsSearchSource(
            excludedWebsites: source.excludedWebsites ?? const [],
          ),
        );
        break;
      default:
        return null;
    }
  }

  return mapped;
}

bool _isOpenAISearchModel(String model) {
  return model.contains('search-preview') || model.contains('search');
}

String _openAISearchModelFor(String model) {
  if (model.startsWith('gpt-4o-mini')) {
    return 'gpt-4o-mini-search-preview';
  }

  if (model.startsWith('gpt-4o')) {
    return 'gpt-4o-search-preview';
  }

  return 'gpt-4o-search-preview';
}
