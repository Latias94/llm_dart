import '../core/capability.dart';
import '../core/config.dart';
import '../core/llm_error.dart';
import 'capability_utils.dart';

/// Factory interface for providers that can create language models.
///
/// Mirrors the `languageModel(modelId)` capability on providers in the
/// Vercel AI SDK.
abstract class LanguageModelProviderFactory {
  LanguageModel languageModel(String modelId);
}

/// Factory interface for providers that can create text embedding models.
abstract class EmbeddingModelProviderFactory {
  EmbeddingCapability textEmbeddingModel(String modelId);
}

/// Factory interface for providers that can create image generation models.
abstract class ImageModelProviderFactory {
  ImageGenerationCapability imageModel(String modelId);
}

/// Factory interface for providers that can create speech/transcription models.
abstract class SpeechModelProviderFactory {
  AudioCapability transcription(String modelId);
  AudioCapability speech(String modelId);
}

  /// Enterprise-grade provider registry for managing multiple providers
  /// and their capabilities.
  ///
  /// This is a runtime provider registry, complementary to
  /// `LLMProviderRegistry` (factory registry). It is intended for
  /// managing provider instances and their capability matrix at the
  /// application layer.
class ProviderRegistry {
  final Map<String, dynamic> _providers = {};
  final Map<String, Set<LLMCapability>> _capabilities = {};
  final Map<String, Map<String, dynamic>> _metadata = {};

  /// Register a provider with optional metadata.
  void registerProvider(
    String id,
    dynamic provider, {
    Map<String, dynamic>? metadata,
  }) {
    _providers[id] = provider;
    _capabilities[id] = CapabilityUtils.getCapabilities(provider);
    _metadata[id] = metadata ?? {};
  }

  /// Unregister a provider.
  bool unregisterProvider(String id) {
    final existed = _providers.containsKey(id);
    _providers.remove(id);
    _capabilities.remove(id);
    _metadata.remove(id);
    return existed;
  }

  /// Get a registered provider by ID.
  T? getProvider<T>(String id) {
    final provider = _providers[id];
    return provider is T ? provider : null;
  }

  /// Check if a provider supports a capability.
  bool hasCapability(String providerId, LLMCapability capability) {
    return _capabilities[providerId]?.contains(capability) ?? false;
  }

  /// Get all capabilities for a provider.
  Set<LLMCapability> getCapabilities(String providerId) {
    return _capabilities[providerId] ?? {};
  }

  /// Find providers that support a specific capability.
  List<String> findProvidersWithCapability(LLMCapability capability) {
    return _capabilities.entries
        .where((entry) => entry.value.contains(capability))
        .map((entry) => entry.key)
        .toList();
  }

  /// Find providers that support all required capabilities.
  List<String> findProvidersWithAllCapabilities(Set<LLMCapability> required) {
    return _capabilities.entries
        .where((entry) => required.every((cap) => entry.value.contains(cap)))
        .map((entry) => entry.key)
        .toList();
  }

  /// Find the best provider for a set of requirements.
  ///
  /// Returns the providerId that satisfies all required capabilities
  /// and has the highest number of preferred capabilities.
  String? findBestProvider(
    Set<LLMCapability> required, {
    Set<LLMCapability>? preferred,
  }) {
    String? bestProvider;
    var bestScore = -1;

    for (final entry in _capabilities.entries) {
      final providerId = entry.key;
      final capabilities = entry.value;

      if (!required.every((cap) => capabilities.contains(cap))) {
        continue;
      }

      var score = required.length;

      if (preferred != null) {
        score += preferred.where((cap) => capabilities.contains(cap)).length;
      }

      if (score > bestScore) {
        bestScore = score;
        bestProvider = providerId;
      }
    }

    return bestProvider;
  }

  /// Execute action with the best available provider.
  Future<R?> withBestProvider<R>(
    Set<LLMCapability> required,
    Future<R> Function(String providerId, dynamic provider) action, {
    Set<LLMCapability>? preferred,
  }) async {
    final providerId = findBestProvider(required, preferred: preferred);
    if (providerId == null) return null;

    final provider = _providers[providerId];
    if (provider == null) return null;

    return await action(providerId, provider);
  }

  /// Execute action with capability-specific provider.
  Future<R?> withCapabilityProvider<T, R>(
    LLMCapability capability,
    Future<R> Function(T provider) action,
  ) async {
    final providerIds = findProvidersWithCapability(capability);

    for (final providerId in providerIds) {
      final provider = _providers[providerId];
      if (provider is T) {
        return await action(provider);
      }
    }

    return null;
  }

  /// Get capability matrix for all providers.
  Map<String, Set<LLMCapability>> getCapabilityMatrix() {
    return Map.from(_capabilities);
  }

  /// Get detailed provider information.
  RegistryProviderInfo? getProviderInfo(String id) {
    final provider = _providers[id];
    if (provider == null) return null;

    return RegistryProviderInfo(
      id: id,
      provider: provider,
      capabilities: _capabilities[id] ?? {},
      metadata: _metadata[id] ?? {},
    );
  }

  /// Get all registered provider IDs.
  List<String> getProviderIds() {
    return _providers.keys.toList();
  }

  /// Get providers count.
  int get providerCount => _providers.length;

  /// Check if registry is empty.
  bool get isEmpty => _providers.isEmpty;

  /// Clear all providers.
  void clear() {
    _providers.clear();
    _capabilities.clear();
    _metadata.clear();
  }

  /// Get registry statistics.
  RegistryStats getStats() {
    final allCapabilities = _capabilities.values.expand((caps) => caps).toSet();

    final capabilityCount = <LLMCapability, int>{};
    for (final capability in allCapabilities) {
      capabilityCount[capability] = _capabilities.values
          .where((caps) => caps.contains(capability))
          .length;
    }

    return RegistryStats(
      providerCount: _providers.length,
      capabilityCount: capabilityCount,
    );
  }
}

/// Detailed provider info snapshot for diagnostics.
class RegistryProviderInfo {
  final String id;
  final dynamic provider;
  final Set<LLMCapability> capabilities;
  final Map<String, dynamic> metadata;

  const RegistryProviderInfo({
    required this.id,
    required this.provider,
    required this.capabilities,
    required this.metadata,
  });
}

/// Aggregate statistics for a [ProviderRegistry].
class RegistryStats {
  final int providerCount;
  final Map<LLMCapability, int> capabilityCount;

  const RegistryStats({
    required this.providerCount,
    required this.capabilityCount,
  });
}

  /// High-level client for resolving typed models from a [ProviderRegistry].
  ///
  /// Provides parsing of `"provider:model"`-style identifiers, e.g.:
  /// - `languageModel('openai:gpt-4o')`
  /// - `textEmbeddingModel('openai:text-embedding-3-small')`
  /// - `imageModel('openai:dall-e-3')`, etc.
class ProviderRegistryClient {
  final ProviderRegistry _registry;
  final String _separator;

  ProviderRegistryClient(this._registry, {String separator = ':'})
      : _separator = separator;

  (String, String) _splitId(String id, String modelType) {
    final index = id.indexOf(_separator);
    if (index == -1) {
      throw InvalidRequestError(
        'Invalid $modelType id for registry: $id '
        '(must be in the format "providerId$_separator'
        'modelId")',
      );
    }

    final providerId = id.substring(0, index);
    final modelId = id.substring(index + _separator.length);
    return (providerId, modelId);
  }

  /// Resolve a language model for the given combined id.
  LanguageModel languageModel(String id) {
    final (providerId, modelId) = _splitId(id, 'languageModel');
    final provider = _registry.getProvider<Object>(providerId);

    if (provider is LanguageModelProviderFactory) {
      return provider.languageModel(modelId);
    }

    throw InvalidRequestError(
      'Provider "$providerId" does not support language models via '
      'LanguageModelProviderFactory. '
      'Make sure you register a facade such as OpenAI, GoogleGenerativeAI, '
      'or DeepSeek that implements LanguageModelProviderFactory.',
    );
  }

  /// Resolve a text embedding model for the given combined id.
  EmbeddingCapability textEmbeddingModel(String id) {
    final (providerId, modelId) = _splitId(id, 'textEmbeddingModel');
    final provider = _registry.getProvider<Object>(providerId);

    if (provider is EmbeddingModelProviderFactory) {
      return provider.textEmbeddingModel(modelId);
    }

    throw InvalidRequestError(
      'Provider "$providerId" does not support embedding models via '
      'EmbeddingModelProviderFactory.',
    );
  }

  /// Resolve an image generation model for the given combined id.
  ImageGenerationCapability imageModel(String id) {
    final (providerId, modelId) = _splitId(id, 'imageModel');
    final provider = _registry.getProvider<Object>(providerId);

    if (provider is ImageModelProviderFactory) {
      return provider.imageModel(modelId);
    }

    throw InvalidRequestError(
      'Provider "$providerId" does not support image models via '
      'ImageModelProviderFactory.',
    );
  }

  /// Resolve a transcription (speech-to-text) model for the given id.
  AudioCapability transcriptionModel(String id) {
    final (providerId, modelId) = _splitId(id, 'transcriptionModel');
    final provider = _registry.getProvider<Object>(providerId);

    if (provider is SpeechModelProviderFactory) {
      return provider.transcription(modelId);
    }

    throw InvalidRequestError(
      'Provider "$providerId" does not support transcription models via '
      'SpeechModelProviderFactory.',
    );
  }

  /// Resolve a speech (text-to-speech) model for the given id.
  AudioCapability speechModel(String id) {
    final (providerId, modelId) = _splitId(id, 'speechModel');
    final provider = _registry.getProvider<Object>(providerId);

    if (provider is SpeechModelProviderFactory) {
      return provider.speech(modelId);
    }

    throw InvalidRequestError(
      'Provider "$providerId" does not support speech models via '
      'SpeechModelProviderFactory.',
    );
  }

  /// Expose underlying provider ids for diagnostics or tooling.
  List<String> get providerIds => _registry.getProviderIds();

  /// Expose registry statistics for debugging/monitoring.
  RegistryStats get stats => _registry.getStats();
}

/// Create a registry client for the given provider facades.
///
/// [providers] is typically a map of Vercel-style provider facades such
/// as `OpenAI`, `GoogleGenerativeAI`, `DeepSeek`, etc. Keys are logical
/// providerIds that act as the prefix component of combined modelIds
/// (for example `"openai:gpt-4o"`).
ProviderRegistryClient createProviderRegistry(
  Map<String, Object> providers, {
  String separator = ':',
}) {
  final registry = ProviderRegistry();
  for (final entry in providers.entries) {
    registry.registerProvider(entry.key, entry.value);
  }
  return ProviderRegistryClient(registry, separator: separator);
}
