library;

import 'config.dart';
import 'capability.dart';
import 'llm_error.dart';

/// Factory interface for creating LLM provider instances.
///
/// This interface allows for extensible provider registration where
/// callers can add custom providers without modifying the core library.
abstract class LLMProviderFactory<T extends Object> {
  /// Unique identifier for this provider.
  String get providerId;

  /// Set of capabilities this provider supports.
  Set<LLMCapability> get supportedCapabilities;

  /// Create a provider instance from the given configuration.
  T create(LLMConfig config);

  /// Validate that the configuration is valid for this provider.
  bool validateConfig(LLMConfig config);

  /// Get default configuration for this provider.
  LLMConfig getDefaultConfig();

  /// Human-readable name for this provider.
  String get displayName => providerId;

  /// Description of this provider.
  String get description => 'LLM provider: $providerId';
}

/// Registry for managing LLM provider factories.
///
/// This singleton class manages the registration and creation of LLM providers.
/// It supports both built-in providers (when registered by higher-level
/// packages) and user-defined custom providers.
class LLMProviderRegistry {
  static final Map<String, LLMProviderFactory> _factories = {};

  /// Register a provider factory.
  ///
  /// Throws [InvalidRequestError] if a provider with the same ID is already
  /// registered.
  static void register<T extends Object>(LLMProviderFactory<T> factory) {
    if (_factories.containsKey(factory.providerId)) {
      throw InvalidRequestError(
        'Provider with ID "${factory.providerId}" is already registered',
      );
    }
    _factories[factory.providerId] = factory;
  }

  /// Register a provider factory, replacing any existing one with the same ID.
  static void registerOrReplace<T extends Object>(
    LLMProviderFactory<T> factory,
  ) {
    _factories[factory.providerId] = factory;
  }

  /// Unregister a provider factory.
  ///
  /// Returns true if the provider was found and removed, false otherwise.
  static bool unregister(String providerId) {
    return _factories.remove(providerId) != null;
  }

  /// Get a registered provider factory, or null if not found.
  static LLMProviderFactory? getFactory(String providerId) {
    return _factories[providerId];
  }

  /// Get all registered provider IDs.
  static List<String> getRegisteredProviders() {
    return _factories.keys.toList();
  }

  /// Get all registered provider factories.
  static Map<String, LLMProviderFactory> getAllFactories() {
    return Map.unmodifiable(_factories);
  }

  /// Check if a provider is registered.
  static bool isRegistered(String providerId) {
    return _factories.containsKey(providerId);
  }

  /// Check if a provider supports a specific capability.
  ///
  /// Returns true if the provider exists and supports the capability.
  static bool supportsCapability(String providerId, LLMCapability capability) {
    final factory = getFactory(providerId);
    return factory?.supportedCapabilities.contains(capability) ?? false;
  }

  /// Get providers that support a specific capability.
  static List<String> getProvidersWithCapability(LLMCapability capability) {
    return _factories.entries
        .where(
          (entry) => entry.value.supportedCapabilities.contains(capability),
        )
        .map((entry) => entry.key)
        .toList();
  }

  /// Create a chat-capable provider instance.
  ///
  /// Convenience wrapper around [createProviderTyped] for providers that
  /// implement [ChatCapability].
  static ChatCapability createProvider(String providerId, LLMConfig config) {
    return createProviderTyped<ChatCapability>(providerId, config);
  }

  /// Create a provider instance with a specific required type.
  ///
  /// This generic helper allows capability-specific builders to request
  /// providers that implement a particular interface, such as
  /// [AudioCapability] for audio-only providers.
  ///
  /// Throws:
  /// - [InvalidRequestError] if the provider is unknown or the configuration
  ///   is invalid.
  /// - [UnsupportedCapabilityError] if the created provider does not implement
  ///   the required type [T].
  static T createProviderTyped<T extends Object>(
    String providerId,
    LLMConfig config,
  ) {
    final factory = getFactory(providerId);
    if (factory == null) {
      throw InvalidRequestError('Unknown provider: $providerId');
    }

    if (!factory.validateConfig(config)) {
      throw InvalidRequestError(
        'Invalid configuration for provider: $providerId',
      );
    }

    final provider = factory.create(config);

    if (provider is! T) {
      throw UnsupportedCapabilityError(
        'Provider "$providerId" does not implement the required type '
        '${T.toString()}.',
      );
    }

    return provider;
  }

  /// Get provider information, or null if not found.
  static ProviderInfo? getProviderInfo(String providerId) {
    final factory = getFactory(providerId);
    if (factory == null) return null;

    return ProviderInfo(
      id: factory.providerId,
      displayName: factory.displayName,
      description: factory.description,
      supportedCapabilities: factory.supportedCapabilities,
      defaultConfig: factory.getDefaultConfig(),
    );
  }

  /// Get information for all registered providers.
  static List<ProviderInfo> getAllProviderInfo() {
    return _factories.values
        .map(
          (factory) => ProviderInfo(
            id: factory.providerId,
            displayName: factory.displayName,
            description: factory.description,
            supportedCapabilities: factory.supportedCapabilities,
            defaultConfig: factory.getDefaultConfig(),
          ),
        )
        .toList();
  }

  /// Clear all registered providers.
  ///
  /// Primarily useful for tests; callers are responsible for re-registering
  /// any built-in providers they rely on.
  static void clear() {
    _factories.clear();
  }
}

/// Alias for [LLMProviderRegistry] with a clearer name.
///
/// This registry stores provider factories (constructors), not provider
/// instances. For managing already-created providers at runtime, see
/// `ProviderRegistry` / `ProviderInstanceRegistry` in `src/utils/provider_registry.dart`.
abstract final class ProviderFactoryRegistry {
  static void register<T extends Object>(LLMProviderFactory<T> factory) =>
      LLMProviderRegistry.register(factory);

  static void registerOrReplace<T extends Object>(
          LLMProviderFactory<T> factory) =>
      LLMProviderRegistry.registerOrReplace(factory);

  static bool unregister(String providerId) =>
      LLMProviderRegistry.unregister(providerId);

  static LLMProviderFactory? getFactory(String providerId) =>
      LLMProviderRegistry.getFactory(providerId);

  static List<String> getRegisteredProviders() =>
      LLMProviderRegistry.getRegisteredProviders();

  static Map<String, LLMProviderFactory> getAllFactories() =>
      LLMProviderRegistry.getAllFactories();

  static bool isRegistered(String providerId) =>
      LLMProviderRegistry.isRegistered(providerId);

  static bool supportsCapability(String providerId, LLMCapability capability) =>
      LLMProviderRegistry.supportsCapability(providerId, capability);

  static List<String> getProvidersWithCapability(LLMCapability capability) =>
      LLMProviderRegistry.getProvidersWithCapability(capability);

  static ChatCapability createProvider(String providerId, LLMConfig config) =>
      LLMProviderRegistry.createProvider(providerId, config);

  static T createProviderTyped<T extends Object>(
          String providerId, LLMConfig config) =>
      LLMProviderRegistry.createProviderTyped(providerId, config);

  static ProviderInfo? getProviderInfo(String providerId) =>
      LLMProviderRegistry.getProviderInfo(providerId);

  static List<ProviderInfo> getAllProviderInfo() =>
      LLMProviderRegistry.getAllProviderInfo();

  static void clear() => LLMProviderRegistry.clear();
}

/// Information about a registered provider.
class ProviderInfo {
  /// Unique provider ID.
  final String id;

  /// Human-readable display name.
  final String displayName;

  /// Provider description.
  final String description;

  /// Set of capabilities this provider supports.
  final Set<LLMCapability> supportedCapabilities;

  /// Default configuration for this provider.
  final LLMConfig defaultConfig;

  const ProviderInfo({
    required this.id,
    required this.displayName,
    required this.description,
    required this.supportedCapabilities,
    required this.defaultConfig,
  });

  /// Check if this provider supports a capability.
  bool supports(LLMCapability capability) =>
      supportedCapabilities.contains(capability);

  @override
  String toString() =>
      'ProviderInfo(id: $id, capabilities: $supportedCapabilities)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProviderInfo &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
