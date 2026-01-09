import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import 'openai_compatible_configs.dart';
import 'openai_compatible_config.dart';
import 'openai_compatible_provider_config.dart';
import 'client.dart';
import 'provider.dart';

/// Register all pre-configured OpenAI-compatible providers.
///
/// - If [replace] is false (default), registration is idempotent and will not
///   override existing registrations for the same provider id.
/// - If [replace] is true, existing registrations are replaced.
void registerOpenAICompatibleProviders({bool replace = false}) {
  for (final factory in OpenAICompatibleProviderFactory.createAllFactories()) {
    if (!replace && LLMProviderRegistry.isRegistered(factory.providerId)) {
      continue;
    }
    if (replace) {
      LLMProviderRegistry.registerOrReplace(factory);
    } else {
      LLMProviderRegistry.register(factory);
    }
  }
}

/// Register a specific OpenAI-compatible provider by id.
///
/// Returns true if a matching config exists.
bool registerOpenAICompatibleProvider(
  String providerId, {
  bool replace = false,
}) {
  final factory = OpenAICompatibleProviderFactory.createFactory(providerId);
  if (factory == null) return false;

  if (!replace && LLMProviderRegistry.isRegistered(factory.providerId)) {
    return true;
  }
  if (replace) {
    LLMProviderRegistry.registerOrReplace(factory);
  } else {
    LLMProviderRegistry.register(factory);
  }
  return true;
}

/// Register a custom OpenAI-compatible provider configuration.
///
/// This mirrors Vercel AI SDK's `createOpenAICompatible({ name, baseURL, ... })`
/// idea: callers can supply their own base URL, headers, and query params via
/// [LLMConfig] + `providerOptions`, without requiring this package to ship a
/// pre-defined preset.
void registerCustomOpenAICompatibleProvider(
  OpenAICompatibleProviderConfig config, {
  bool replace = false,
}) {
  final factory = OpenAICompatibleProviderFactory(config);
  if (!replace && LLMProviderRegistry.isRegistered(factory.providerId)) return;

  if (replace) {
    LLMProviderRegistry.registerOrReplace(factory);
  } else {
    LLMProviderRegistry.register(factory);
  }
}

/// Generic factory for creating OpenAI-compatible provider instances
///
/// This factory can create providers for any service that offers an OpenAI-compatible API,
/// using pre-configured settings for popular providers like DeepSeek, Gemini, xAI, etc.
class OpenAICompatibleProviderFactory
    extends BaseProviderFactory<ChatCapability> {
  final OpenAICompatibleProviderConfig _config;

  OpenAICompatibleProviderFactory(this._config);

  static const Set<LLMCapability> _bestEffortCapabilities = {
    LLMCapability.chat,
    LLMCapability.streaming,
    LLMCapability.toolCalling,
    LLMCapability.embedding,
  };

  @override
  String get providerId => _config.providerId;

  @override
  String get displayName => _config.displayName;

  @override
  String get description => _config.description;

  @override
  Set<LLMCapability> get supportedCapabilities => _bestEffortCapabilities;

  @override
  bool get requiresApiKey => false;

  @override
  ChatCapability create(LLMConfig config) {
    return createProviderSafely<OpenAICompatibleConfig>(
      config,
      () => _transformConfig(config),
      (compatibleConfig) {
        final client = OpenAIClient(compatibleConfig);
        return OpenAICompatibleChatEmbeddingProvider(
          client,
          compatibleConfig,
          supportedCapabilities,
        );
      },
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
  OpenAICompatibleConfig _transformConfig(LLMConfig config) {
    return OpenAICompatibleConfig.fromLLMConfig(
      config,
      providerId: providerId,
      providerName: displayName,
    );
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
