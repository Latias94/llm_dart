import '../../core/capability.dart';
import '../../core/config.dart';
import '../../core/registry.dart';
import '../../core/web_search.dart';
import '../../src/compatibility/providers/openai_family_compat_openrouter.dart';
import '../../src/openai_compatible_configs.dart';
import '../../models/chat_models.dart';
import '../../src/config/legacy_config_extensions.dart';
import '../../src/config/legacy_provider_options.dart';
import '../openai/openai.dart';
import 'base_factory.dart';

/// Generic factory for creating OpenAI-compatible provider instances
///
/// This factory can create providers for any service that offers an OpenAI-compatible API,
/// using pre-configured settings for popular providers like DeepSeek, Gemini, xAI, etc.
class OpenAICompatibleProviderFactory
    extends BaseProviderFactory<ChatCapability> {
  final OpenAICompatibleProviderConfig _config;

  OpenAICompatibleProviderFactory(this._config);

  @override
  String get providerId => _config.providerId;

  @override
  String get displayName => _config.displayName;

  @override
  String get description => _config.description;

  @override
  Set<LLMCapability> get supportedCapabilities => _config.supportedCapabilities;

  @override
  ChatCapability create(LLMConfig config) {
    if (_isOpenRouter()) {
      return createProviderSafely<LLMConfig>(
        config,
        () => config,
        buildCompatOpenRouterProvider,
      );
    }

    return createProviderSafely<OpenAIConfig>(
      config,
      () => _transformConfig(config),
      (openaiConfig) => OpenAIProvider(openaiConfig),
    );
  }

  @override
  Map<String, dynamic> getProviderDefaults() {
    return {
      'baseUrl': _config.defaultBaseUrl,
      'model': _config.defaultModel,
    };
  }

  /// Transform unified config to OpenAI-compatible config
  OpenAIConfig _transformConfig(LLMConfig config) {
    // Handle web search configuration for OpenRouter
    String? model = config.model;

    // Check for webSearchEnabled flag (for OpenRouter)
    final webSearchEnabled = config.legacyWebSearchEnabled;
    if (webSearchEnabled == true &&
        _isOpenRouter() &&
        !_hasOnlineSuffix(model)) {
      // Add :online suffix for OpenRouter web search
      model = _addOnlineSuffix(model);
    }

    // Check for webSearchConfig (for OpenRouter)
    final webSearchConfig = _isOpenRouter()
        ? getLegacyProviderOption<WebSearchConfig>(
            config,
            LegacyProviderOptionNamespaces.openrouter,
            LegacyExtensionKeys.webSearchConfig,
          )
        : config.legacyWebSearchConfig;
    if (webSearchConfig != null &&
        _isOpenRouter() &&
        !_hasOnlineSuffix(model)) {
      model = _addOnlineSuffix(model);
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
      // Common parameters
      stopSequences: config.stopSequences,
      user: config.user,
      serviceTier: config.serviceTier,
      // OpenAI-compatible extensions using safe access
      reasoningEffort:
          ReasoningEffort.fromString(config.legacyReasoningEffortValue),
      jsonSchema: config.legacyJsonSchema,
      voice: config.legacyVoice,
      embeddingEncodingFormat: config.legacyEmbeddingEncodingFormat,
      embeddingDimensions: config.legacyEmbeddingDimensions,
      // Responses API configuration (most OpenAI-compatible providers don't support this yet)
      useResponsesAPI: _getOpenAICompatibleProviderOption<bool>(
            config,
            LegacyExtensionKeys.useResponsesApi,
          ) ??
          false,
      previousResponseId: _getOpenAICompatibleProviderOption<String>(
        config,
        LegacyExtensionKeys.previousResponseId,
      ),
      builtInTools: _getOpenAICompatibleProviderOption<List<OpenAIBuiltInTool>>(
        config,
        LegacyExtensionKeys.builtInTools,
      ),
      originalConfig: config,
    );
  }

  /// Check if this is an OpenRouter provider
  bool _isOpenRouter() {
    return _config.providerId == 'openrouter';
  }

  /// Check if model already has :online suffix
  bool _hasOnlineSuffix(String? model) {
    if (model == null) return false;
    return model.endsWith(':online');
  }

  /// Add :online suffix to model for OpenRouter web search
  String _addOnlineSuffix(String? model) {
    if (model == null) return ':online';
    if (_hasOnlineSuffix(model)) return model;
    return '$model:online';
  }

  E? _getOpenAICompatibleProviderOption<E>(
    LLMConfig config,
    String key,
  ) {
    if (_isOpenRouter()) {
      return getLegacyProviderOption<E>(
        config,
        LegacyProviderOptionNamespaces.openrouter,
        key,
      );
    }

    return config.getExtension<E>(key);
  }

  /// Create factory instances for all pre-configured providers
  static List<OpenAICompatibleProviderFactory> createAllFactories() {
    return OpenAICompatibleConfigs.getAllConfigs()
        .map((config) => OpenAICompatibleProviderFactory(config))
        .toList();
  }

  /// Create a specific factory by provider ID
  static OpenAICompatibleProviderFactory? createFactory(String providerId) {
    final config = OpenAICompatibleConfigs.getConfig(providerId);
    if (config == null) return null;

    return OpenAICompatibleProviderFactory(config);
  }
}

/// Helper class for registering OpenAI-compatible providers
class OpenAICompatibleProviderRegistrar {
  /// Register all pre-configured OpenAI-compatible providers
  static void registerAll() {
    final factories = OpenAICompatibleProviderFactory.createAllFactories();

    for (final factory in factories) {
      LLMProviderRegistry.registerOrReplace(factory);
    }
  }

  /// Register a specific OpenAI-compatible provider
  static bool registerProvider(String providerId) {
    final factory = OpenAICompatibleProviderFactory.createFactory(providerId);
    if (factory == null) return false;

    LLMProviderRegistry.registerOrReplace(factory);
    return true;
  }

  /// Get list of available OpenAI-compatible provider IDs
  static List<String> getAvailableProviders() {
    return OpenAICompatibleConfigs.getAllConfigs()
        .map((config) => config.providerId)
        .toList();
  }
}
