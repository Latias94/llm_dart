import 'package:llm_dart_core/core/capability.dart';
import 'package:llm_dart_core/core/config.dart';
import 'package:llm_dart_core/core/llm_error.dart';
import 'package:llm_dart_core/core/provider_options.dart';
import 'package:llm_dart_core/core/registry.dart';

/// Base factory class that provides common functionality for all provider factories.
///
/// This reduces code duplication and provides consistent behavior across
/// all provider factories. It includes common validation, error handling,
/// and configuration transformation patterns.
abstract class BaseProviderFactory<T extends Object>
    implements LLMProviderFactory<T> {
  @override
  String get providerId;

  @override
  Set<LLMCapability> get supportedCapabilities;

  @override
  T create(LLMConfig config);

  @override
  String get displayName;

  @override
  String get description;

  /// Default validation that checks for API key presence.
  ///
  /// Override this method for providers with different requirements.
  @override
  bool validateConfig(LLMConfig config) {
    return validateApiKey(config);
  }

  /// Common API key validation (most providers require an API key).
  bool validateApiKey(LLMConfig config) {
    return config.apiKey != null && config.apiKey!.isNotEmpty;
  }

  /// Validation for providers that don't require API key (like Ollama).
  bool validateModelOnly(LLMConfig config) {
    return config.model.isNotEmpty;
  }

  /// Enhanced validation with detailed error messages.
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

  /// Whether this provider requires an API key.
  ///
  /// Override this for providers like Ollama that don't need API keys.
  bool get requiresApiKey => true;

  /// Common configuration transformation for basic parameters.
  Map<String, dynamic> getBaseConfigMap(LLMConfig config) {
    return {
      'apiKey': config.apiKey,
      'baseUrl': config.baseUrl,
      'model': config.model,
      'maxTokens': config.maxTokens,
      'temperature': config.temperature,
      'systemPrompt': config.systemPrompt,
      'timeout': config.timeout,
      'topP': config.topP,
      'topK': config.topK,
      'tools': config.tools,
      'toolChoice': config.toolChoice,
    };
  }

  /// Helper method to safely get provider options with type checking.
  E? getProviderOption<E>(
    LLMConfig config,
    String providerId,
    String key, [
    E? defaultValue,
  ]) {
    return readProviderOption<E>(config.providerOptions, providerId, key) ??
        defaultValue;
  }

  /// Create default config with provider-specific defaults.
  ///
  /// Subclasses should override [getProviderDefaults] to customize.
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

  /// Provider-specific default values.
  ///
  /// Subclasses must implement this to provide their defaults.
  Map<String, dynamic> getProviderDefaults();

  /// Helper method for creating provider instances with error handling.
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

/// Specialized base factory for OpenAI-compatible providers.
abstract class OpenAICompatibleBaseFactory<T extends ChatCapability>
    extends BaseProviderFactory<T> {
  /// Common OpenAI-compatible configuration transformation.
  Map<String, dynamic> getOpenAICompatibleConfigMap(LLMConfig config) {
    final baseMap = getBaseConfigMap(config);
    final pid = providerId;

    baseMap.addAll({
      'reasoningEffort':
          getProviderOption<String>(config, pid, 'reasoningEffort'),
      'jsonSchema': getProviderOption(config, pid, 'jsonSchema'),
      'voice': getProviderOption<String>(config, pid, 'voice'),
      'embeddingEncodingFormat':
          getProviderOption<String>(config, pid, 'embeddingEncodingFormat'),
      'embeddingDimensions':
          getProviderOption<int>(config, pid, 'embeddingDimensions'),
    });

    baseMap.removeWhere((key, value) => value == null);

    return baseMap;
  }
}

/// Specialized base factory for providers that don't require API keys.
abstract class LocalProviderFactory<T extends ChatCapability>
    extends BaseProviderFactory<T> {
  @override
  bool get requiresApiKey => false;

  @override
  bool validateConfig(LLMConfig config) {
    return validateModelOnly(config);
  }
}

/// Specialized base factory for audio-only providers.
abstract class AudioProviderFactory<T extends AudioCapability>
    extends BaseProviderFactory<T> {
  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.textToSpeech,
        LLMCapability.speechToText,
      };

  /// Audio providers typically need voice-related provider options.
  Map<String, dynamic> getAudioConfigMap(LLMConfig config) {
    final baseMap = getBaseConfigMap(config);
    final pid = providerId;

    baseMap.addAll({
      'voiceId': getProviderOption<String>(config, pid, 'voiceId'),
      'stability': getProviderOption<double>(config, pid, 'stability'),
      'similarityBoost':
          getProviderOption<double>(config, pid, 'similarityBoost'),
      'style': getProviderOption<double>(config, pid, 'style'),
      'useSpeakerBoost':
          getProviderOption<bool>(config, pid, 'useSpeakerBoost'),
    });

    baseMap.removeWhere((key, value) => value == null);

    return baseMap;
  }
}
