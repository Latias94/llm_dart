import '../../core/capability.dart';
import '../../core/config.dart';

/// OpenAI-compatible provider configuration.
///
/// This configuration defines the capabilities and behavior of providers that
/// use OpenAI-compatible APIs. Since these providers can vary significantly
/// in their actual capabilities, this configuration provides:
///
/// - **Default capability assumptions** for unknown models
/// - **Model-specific overrides** for known models
/// - **Flexible capability detection** for dynamic scenarios
class OpenAICompatibleProviderConfig {
  /// Provider identifier.
  final String providerId;

  /// Display name for UI.
  final String displayName;

  /// Provider description.
  final String description;

  /// Default base URL for API requests.
  final String defaultBaseUrl;

  /// Default model name.
  final String defaultModel;

  /// Supported capabilities for this provider.
  ///
  /// For OpenAI-compatible providers, this represents the capabilities that
  /// are generally supported. Actual support may vary by specific model.
  final Set<LLMCapability> supportedCapabilities;

  /// Default capabilities assumed for unknown models.
  ///
  /// When a model is not explicitly configured in [modelConfigs],
  /// these capabilities will be assumed. This provides a safe fallback
  /// for OpenAI-compatible providers where we can't know all models.
  ///
  /// If null, defaults to [supportedCapabilities].
  final Set<LLMCapability>? defaultCapabilities;

  /// Whether to allow dynamic capability detection.
  ///
  /// When true, the provider may attempt to detect capabilities at runtime
  /// based on API responses or other indicators. This is useful for
  /// OpenAI-compatible providers with unknown capabilities.
  final bool allowDynamicCapabilities;

  /// Provider-specific model configurations.
  final Map<String, ModelCapabilityConfig> modelConfigs;

  /// Whether this provider supports reasoning effort parameter.
  final bool supportsReasoningEffort;

  /// Whether this provider supports structured output.
  final bool supportsStructuredOutput;

  /// Custom parameter mappings for this provider.
  final Map<String, String> parameterMappings;

  /// Custom request body transformer for provider-specific parameters.
  final RequestBodyTransformer? requestBodyTransformer;

  /// Custom headers transformer for provider-specific headers.
  final HeadersTransformer? headersTransformer;

  const OpenAICompatibleProviderConfig({
    required this.providerId,
    required this.displayName,
    required this.description,
    required this.defaultBaseUrl,
    required this.defaultModel,
    required this.supportedCapabilities,
    this.defaultCapabilities,
    this.allowDynamicCapabilities = true,
    this.modelConfigs = const {},
    this.supportsReasoningEffort = false,
    this.supportsStructuredOutput = false,
    this.parameterMappings = const {},
    this.requestBodyTransformer,
    this.headersTransformer,
  });

  /// Get effective default capabilities for unknown models.
  Set<LLMCapability> get effectiveDefaultCapabilities =>
      defaultCapabilities ?? supportedCapabilities;
}

/// Model-specific capability configuration.
class ModelCapabilityConfig {
  /// Whether this model supports reasoning/thinking.
  final bool supportsReasoning;

  /// Whether this model supports vision/image input.
  final bool supportsVision;

  /// Whether this model supports tool calling.
  final bool supportsToolCalling;

  /// Maximum context length for this model.
  final int? maxContextLength;

  /// Whether temperature should be disabled for this model.
  final bool disableTemperature;

  /// Whether top_p should be disabled for this model.
  final bool disableTopP;

  /// Custom reasoning effort mapping for this model.
  final Map<String, dynamic>? reasoningEffortMapping;

  const ModelCapabilityConfig({
    this.supportsReasoning = false,
    this.supportsVision = false,
    this.supportsToolCalling = true,
    this.maxContextLength,
    this.disableTemperature = false,
    this.disableTopP = false,
    this.reasoningEffortMapping,
  });
}

/// Abstract interface for transforming unified config to provider-specific config.
abstract class ConfigTransformer<T> {
  /// Transform unified LLMConfig to provider-specific configuration.
  T transform(LLMConfig config);

  /// Validate that the config contains all required fields for this provider.
  bool validate(LLMConfig config);

  /// Get default configuration for this provider.
  LLMConfig getDefaultConfig();
}

/// Abstract interface for transforming request body for provider-specific parameters.
abstract class RequestBodyTransformer {
  /// Transform the request body to include provider-specific parameters.
  ///
  /// [body] - The original OpenAI-compatible request body
  /// [config] - The LLM configuration containing extensions and parameters
  /// [providerConfig] - The provider-specific configuration
  ///
  /// Returns the transformed request body with provider-specific parameters.
  Map<String, dynamic> transform(
    Map<String, dynamic> body,
    LLMConfig config,
    OpenAICompatibleProviderConfig providerConfig,
  );
}

/// Abstract interface for transforming headers for provider-specific requirements.
abstract class HeadersTransformer {
  /// Transform the headers to include provider-specific headers.
  ///
  /// [headers] - The original headers map
  /// [config] - The LLM configuration containing extensions and parameters
  /// [providerConfig] - The provider-specific configuration
  ///
  /// Returns the transformed headers with provider-specific additions.
  Map<String, String> transform(
    Map<String, String> headers,
    LLMConfig config,
    OpenAICompatibleProviderConfig providerConfig,
  );
}
