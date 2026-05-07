import '../../core/capability.dart';
import '../../core/config.dart';
import '../../core/registry.dart';
import '../../src/compatibility/providers/openai_family_compat_openrouter.dart';
import '../../src/openai_compatible_configs.dart';
import '../../models/chat_models.dart';
import '../../src/config/legacy_config_extensions.dart';
import '../../src/compatibility/providers/community_provider_config_adapters.dart';
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
    return OpenAIConfig(
      apiKey: config.apiKey!,
      baseUrl: config.baseUrl,
      model: config.model,
      maxTokens: config.maxTokens,
      temperature: config.temperature,
      systemPrompt: config.systemPrompt,
      timeout: config.timeout,
      dioOverrides: createLegacyDioClientOverrides(config),
      transportClient: config.legacyTransportClient,
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
      useResponsesAPI:
          config.getExtension<bool>(LegacyExtensionKeys.useResponsesApi) ??
              false,
      previousResponseId:
          config.getExtension<String>(LegacyExtensionKeys.previousResponseId),
      builtInTools: config.getExtension<List<OpenAIBuiltInTool>>(
          LegacyExtensionKeys.builtInTools),
      frequencyPenalty:
          config.getExtension<double>(LegacyExtensionKeys.frequencyPenalty),
      presencePenalty:
          config.getExtension<double>(LegacyExtensionKeys.presencePenalty),
      logitBias: config.getExtension<Map<String, double>>(
        LegacyExtensionKeys.logitBias,
      ),
      seed: config.getExtension<int>(LegacyExtensionKeys.seed),
      parallelToolCalls:
          config.getExtension<bool>(LegacyExtensionKeys.parallelToolCalls),
      logprobs: config.getExtension<bool>(LegacyExtensionKeys.logprobs),
      topLogprobs: config.getExtension<int>(LegacyExtensionKeys.topLogprobs),
      verbosity: config.getExtension<String>(LegacyExtensionKeys.verbosity),
    );
  }

  /// Check if this is an OpenRouter provider
  bool _isOpenRouter() {
    return _config.providerId == 'openrouter';
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
    final factories = _createDefaultOpenAICompatibleFactories();

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

  /// Provider IDs registered by the root package by default.
  ///
  /// Legacy `*-openai` aliases remain available through [registerProvider],
  /// but are not part of the default registry surface because the dedicated
  /// provider IDs now carry their provider-owned options and compat bridges.
  static List<String> getDefaultProviders() {
    return _createDefaultOpenAICompatibleFactories()
        .map((factory) => factory.providerId)
        .toList();
  }
}

List<OpenAICompatibleProviderFactory>
    _createDefaultOpenAICompatibleFactories() {
  final openRouter = OpenAICompatibleProviderFactory.createFactory(
    'openrouter',
  );

  return [
    if (openRouter != null) openRouter,
  ];
}
