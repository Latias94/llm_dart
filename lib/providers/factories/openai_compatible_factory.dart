import '../../core/capability.dart';
import '../../core/config.dart';
import '../../core/registry.dart';
import '../../src/compatibility/openai_compatible_provider_config.dart';
import '../../src/compatibility/providers/openai_family_compat_openrouter.dart';
import '../../src/compatibility/providers/openai_family_compat_openai_config.dart';
import '../../src/compatibility/openai_compatible_configs.dart';
import '../openai/openai.dart';
import 'base_factory.dart';

/// Factory for supported OpenAI-compatible provider presets.
///
/// Provider-owned services such as DeepSeek, Google, Groq, Phind, and xAI are
/// handled by their dedicated factories. This factory remains for OpenRouter's
/// compatibility bridge and for explicit generic OpenAI-family endpoints that
/// do not have a first-class provider facade.
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
      () => createLegacyOpenAICompatibleConfig(config),
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

  /// Check if this is an OpenRouter provider.
  bool _isOpenRouter() {
    return _config.providerId == 'openrouter';
  }

  /// Create factory instances for all pre-configured compatible presets.
  static List<OpenAICompatibleProviderFactory> createAllFactories() {
    return OpenAICompatibleConfigs.getAllConfigs()
        .map((config) => OpenAICompatibleProviderFactory(config))
        .toList();
  }

  /// Create a specific factory by provider ID.
  static OpenAICompatibleProviderFactory? createFactory(String providerId) {
    final config = OpenAICompatibleConfigs.getConfig(providerId);
    if (config == null) return null;

    return OpenAICompatibleProviderFactory(config);
  }
}

/// Helper class for registering OpenAI-compatible providers
class OpenAICompatibleProviderRegistrar {
  /// Register default OpenAI-compatible providers.
  static void registerAll() {
    final factories = _createDefaultOpenAICompatibleFactories();

    for (final factory in factories) {
      LLMProviderRegistry.registerOrReplace(factory);
    }
  }

  /// Register a specific OpenAI-compatible provider.
  static bool registerProvider(String providerId) {
    final factory = OpenAICompatibleProviderFactory.createFactory(providerId);
    if (factory == null) return false;

    LLMProviderRegistry.registerOrReplace(factory);
    return true;
  }

  /// Get list of available OpenAI-compatible provider IDs.
  static List<String> getAvailableProviders() {
    return OpenAICompatibleConfigs.getAllConfigs()
        .map((config) => config.providerId)
        .toList();
  }

  /// Provider IDs registered by the root package by default.
  ///
  /// Generic endpoints such as GitHub Copilot and Together AI remain available
  /// through [registerProvider], but are not part of the default registry
  /// surface. Dedicated providers carry their own options and compat bridges.
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
