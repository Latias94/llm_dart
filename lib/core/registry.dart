import 'package:logging/logging.dart';

import 'capability.dart';
import 'config.dart';
import 'llm_error.dart';

/// Factory interface for creating LLM provider instances
///
/// This interface allows for extensible provider registration where
/// users can add custom providers without modifying the core library.
abstract class LLMProviderFactory<T extends ChatCapability> {
  /// Unique identifier for this provider
  String get providerId;

  /// Set of capabilities this provider supports
  Set<LLMCapability> get supportedCapabilities;

  /// Create a provider instance from the given configuration
  T create(LLMConfig config);

  /// Validate that the configuration is valid for this provider
  bool validateConfig(LLMConfig config);

  /// Get default configuration for this provider
  LLMConfig getDefaultConfig();

  /// Get human-readable name for this provider
  String get displayName => providerId;

  /// Get description of this provider
  String get description => 'LLM provider: $providerId';
}

/// Registry for managing LLM provider factories
///
/// This singleton class manages the registration and creation of LLM providers.
/// It supports both built-in providers and user-defined custom providers.
class LLMProviderRegistry {
  static final Map<String, LLMProviderFactory> _factories = {};
  static bool _initialized = false;
  static final Logger _logger = Logger('LLMProviderRegistry');
  static void Function()? _builtinRegistrar;

  /// Register a provider factory
  ///
  /// [factory] - The factory to register
  ///
  /// Throws [InvalidRequestError] if a provider with the same ID is already registered
  static void register<T extends ChatCapability>(
      LLMProviderFactory<T> factory) {
    if (_factories.containsKey(factory.providerId)) {
      throw InvalidRequestError(
          'Provider with ID "${factory.providerId}" is already registered');
    }
    _factories[factory.providerId] = factory;
  }

  /// Register a provider factory, replacing any existing one with the same ID
  ///
  /// [factory] - The factory to register
  static void registerOrReplace<T extends ChatCapability>(
      LLMProviderFactory<T> factory) {
    _factories[factory.providerId] = factory;
  }

  /// Configures the lazy registrar used to populate built-in providers.
  ///
  /// The callback is invoked the first time the registry is accessed after a
  /// [clear] or when the registry has not yet been initialized.
  static void configureBuiltinRegistrar(void Function() registrar) {
    _builtinRegistrar = registrar;
  }

  /// Unregister a provider factory
  ///
  /// [providerId] - ID of the provider to unregister
  ///
  /// Returns true if the provider was found and removed, false otherwise
  static bool unregister(String providerId) {
    return _factories.remove(providerId) != null;
  }

  /// Get a registered provider factory
  ///
  /// [providerId] - ID of the provider to get
  ///
  /// Returns the factory or null if not found
  static LLMProviderFactory? getFactory(String providerId) {
    _ensureInitialized();
    return _factories[providerId];
  }

  /// Get all registered provider IDs
  static List<String> getRegisteredProviders() {
    _ensureInitialized();
    return _factories.keys.toList();
  }

  /// Get all registered provider factories
  static Map<String, LLMProviderFactory> getAllFactories() {
    _ensureInitialized();
    return Map.unmodifiable(_factories);
  }

  /// Check if a provider is registered
  ///
  /// [providerId] - ID of the provider to check
  static bool isRegistered(String providerId) {
    _ensureInitialized();
    return _factories.containsKey(providerId);
  }

  /// Check if a provider supports a specific capability
  ///
  /// [providerId] - ID of the provider to check
  /// [capability] - Capability to check for
  ///
  /// Returns true if the provider exists and supports the capability
  static bool supportsCapability(String providerId, LLMCapability capability) {
    final factory = getFactory(providerId);
    return factory?.supportedCapabilities.contains(capability) ?? false;
  }

  /// Get providers that support a specific capability
  ///
  /// [capability] - Capability to filter by
  ///
  /// Returns list of provider IDs that support the capability
  static List<String> getProvidersWithCapability(LLMCapability capability) {
    _ensureInitialized();
    return _factories.entries
        .where(
            (entry) => entry.value.supportedCapabilities.contains(capability))
        .map((entry) => entry.key)
        .toList();
  }

  /// Create a provider instance
  ///
  /// [providerId] - ID of the provider to create
  /// [config] - Configuration for the provider
  ///
  /// Returns the created provider instance
  ///
  /// Throws [InvalidRequestError] if:
  /// - Provider is not registered
  /// - Configuration is invalid for the provider
  static ChatCapability createProvider(String providerId, LLMConfig config) {
    final factory = getFactory(providerId);
    if (factory == null) {
      throw InvalidRequestError('Unknown provider: $providerId');
    }

    if (!factory.validateConfig(config)) {
      throw InvalidRequestError(
          'Invalid configuration for provider: $providerId');
    }

    return factory.create(config);
  }

  /// Get provider information
  ///
  /// [providerId] - ID of the provider
  ///
  /// Returns provider information or null if not found
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

  /// Get information for all registered providers
  static List<ProviderInfo> getAllProviderInfo() {
    _ensureInitialized();
    return _factories.values
        .map((factory) => ProviderInfo(
              id: factory.providerId,
              displayName: factory.displayName,
              description: factory.description,
              supportedCapabilities: factory.supportedCapabilities,
              defaultConfig: factory.getDefaultConfig(),
            ))
        .toList();
  }

  /// Clear all registered providers (mainly for testing)
  static void clear() {
    _factories.clear();
    _initialized = false;
  }

  /// Initialize built-in providers
  static void _ensureInitialized() {
    if (!_initialized) {
      _registerBuiltinProviders();
      _initialized = true;
    }
  }

  /// Register built-in providers
  static void _registerBuiltinProviders() {
    try {
      _builtinRegistrar?.call();
    } catch (e) {
      _logger.warning('Failed to register built-in providers: $e');
      // Silently fail if built-in providers are not available.
    }
  }
}

/// Information about a registered provider
class ProviderInfo {
  /// Unique provider ID
  final String id;

  /// Human-readable display name
  final String displayName;

  /// Provider description
  final String description;

  /// Set of capabilities this provider supports
  final Set<LLMCapability> supportedCapabilities;

  /// Default configuration for this provider
  final LLMConfig defaultConfig;

  const ProviderInfo({
    required this.id,
    required this.displayName,
    required this.description,
    required this.supportedCapabilities,
    required this.defaultConfig,
  });

  /// Check if this provider supports a capability
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
