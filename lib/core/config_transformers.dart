part of 'config.dart';

/// Abstract interface for transforming unified config to provider-specific config
abstract class ConfigTransformer<T> {
  /// Transform unified LLMConfig to provider-specific configuration
  T transform(LLMConfig config);

  /// Validate that the config contains all required fields for this provider
  bool validate(LLMConfig config);

  /// Get default configuration for this provider
  LLMConfig getDefaultConfig();
}

/// Abstract interface for transforming request body for provider-specific parameters
abstract class RequestBodyTransformer {
  /// Transform the request body to include provider-specific parameters
  ///
  /// [body] - The original OpenAI-compatible request body
  /// [config] - The LLM configuration containing extensions and parameters
  /// [providerConfig] - The provider-specific configuration
  ///
  /// Returns the transformed request body with provider-specific parameters
  Map<String, dynamic> transform(
    Map<String, dynamic> body,
    LLMConfig config,
    OpenAICompatibleProviderConfig providerConfig,
  );
}

/// Abstract interface for transforming headers for provider-specific requirements
abstract class HeadersTransformer {
  /// Transform the headers to include provider-specific headers
  ///
  /// [headers] - The original headers map
  /// [config] - The LLM configuration containing extensions and parameters
  /// [providerConfig] - The provider-specific configuration
  ///
  /// Returns the transformed headers with provider-specific additions
  Map<String, String> transform(
    Map<String, String> headers,
    LLMConfig config,
    OpenAICompatibleProviderConfig providerConfig,
  );
}
