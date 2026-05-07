import '../../core/capability.dart';
import '../../core/config.dart';
import '../../core/llm_error.dart';
import '../../core/registry.dart';

/// Base factory class that provides common functionality for all provider factories
///
/// This class reduces code duplication and provides consistent behavior across
/// all provider factories. It includes common validation, error handling,
/// and configuration transformation patterns.
abstract class BaseProviderFactory<T extends ChatCapability>
    implements LLMProviderFactory<T> {
  // Abstract methods that subclasses must implement
  @override
  String get providerId;

  @override
  Set<LLMCapability> get supportedCapabilities;

  @override
  T create(LLMConfig config);

  // Override default implementations with better ones
  @override
  String get displayName;

  @override
  String get description;

  /// Default validation that checks for API key presence
  /// Override this method for providers with different requirements
  @override
  bool validateConfig(LLMConfig config) {
    return validateApiKey(config);
  }

  /// Common API key validation
  /// Most providers require an API key
  bool validateApiKey(LLMConfig config) {
    return config.apiKey != null && config.apiKey!.isNotEmpty;
  }

  /// Validation for providers that don't require API key (like Ollama)
  bool validateModelOnly(LLMConfig config) {
    return config.model.isNotEmpty;
  }

  /// Enhanced validation with detailed error messages
  void validateConfigWithDetails(LLMConfig config) {
    final errors = <String>[];

    if (requiresApiKey && (config.apiKey == null || config.apiKey!.isEmpty)) {
      errors.add('API key is required for $displayName');
    }

    if (config.model.isEmpty) {
      errors.add('Model is required');
    }

    if (config.baseUrl.isEmpty) {
      errors.add('Base URL is required');
    }

    if (errors.isNotEmpty) {
      throw InvalidRequestError(
          'Invalid configuration for $displayName: ${errors.join(', ')}');
    }
  }

  /// Whether this provider requires an API key
  /// Override this for providers like Ollama that don't need API keys
  bool get requiresApiKey => true;

  /// Create default config with provider-specific defaults
  /// Subclasses should override getProviderDefaults() to customize
  @override
  LLMConfig getDefaultConfig() {
    final defaults = getProviderDefaults();
    final baseUrl = defaults['baseUrl'] as String?;
    final model = defaults['model'] as String?;

    if (baseUrl == null) {
      throw GenericError(
          'Provider $providerId must provide a baseUrl in getProviderDefaults()');
    }

    return LLMConfig(
      baseUrl: baseUrl,
      model: model ?? 'default-model',
    );
  }

  /// Provider-specific default values
  /// Subclasses must implement this to provide their defaults
  Map<String, dynamic> getProviderDefaults();

  /// Helper method for creating provider instances with error handling
  T createProviderSafely<P>(
    LLMConfig config,
    P Function() configFactory,
    T Function(P) providerFactory,
  ) {
    try {
      validateConfigWithDetails(config);
      final providerConfig = configFactory();
      return providerFactory(providerConfig);
    } catch (e) {
      if (e is LLMError) {
        rethrow;
      }
      throw GenericError(
          'Failed to create $displayName provider: ${e.toString()}');
    }
  }
}

/// Specialized base factory for providers that don't require API keys
abstract class LocalProviderFactory<T extends ChatCapability>
    extends BaseProviderFactory<T> {
  @override
  bool get requiresApiKey => false;

  @override
  bool validateConfig(LLMConfig config) {
    return validateModelOnly(config);
  }
}
