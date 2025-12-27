import 'package:llm_dart_core/core/capability.dart';
import 'package:llm_dart_core/core/provider_defaults.dart';

import 'openai_compatible_provider_config.dart';

/// Pre-configured OpenAI-compatible provider configurations
///
/// This file contains configurations for popular AI providers that offer
/// OpenAI-compatible APIs, making it easy for users to switch between
/// providers without manual configuration.
class OpenAICompatibleConfigs {
  static const Set<LLMCapability> _bestEffortCapabilities = {
    LLMCapability.chat,
    LLMCapability.streaming,
    LLMCapability.toolCalling,
    LLMCapability.embedding,
  };

  /// DeepSeek configuration using OpenAI-compatible interface
  static const OpenAICompatibleProviderConfig deepseek =
      OpenAICompatibleProviderConfig(
    providerId: 'deepseek-openai',
    displayName: 'DeepSeek (OpenAI-compatible)',
    description: 'DeepSeek AI models using OpenAI-compatible interface',
    defaultBaseUrl: ProviderDefaults.deepseekBaseUrl,
    defaultModel: ProviderDefaults.deepseekDefaultModel,
    supportedCapabilities: _bestEffortCapabilities,
  );

  /// Google Gemini configuration using OpenAI-compatible interface
  static final OpenAICompatibleProviderConfig gemini =
      OpenAICompatibleProviderConfig(
    providerId: 'google-openai',
    displayName: 'Google Gemini (OpenAI-compatible)',
    description: 'Google Gemini models using OpenAI-compatible interface',
    defaultBaseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai/',
    defaultModel: 'gemini-2.0-flash',
    supportedCapabilities: _bestEffortCapabilities,
  );

  /// xAI Grok configuration using OpenAI-compatible interface
  static const OpenAICompatibleProviderConfig xai =
      OpenAICompatibleProviderConfig(
    providerId: 'xai-openai',
    displayName: 'xAI Grok (OpenAI-compatible)',
    description: 'xAI Grok models using OpenAI-compatible interface',
    defaultBaseUrl: ProviderDefaults.xaiBaseUrl,
    defaultModel: ProviderDefaults.xaiDefaultModel,
    supportedCapabilities: _bestEffortCapabilities,
  );

  /// Groq configuration using OpenAI-compatible interface
  static const OpenAICompatibleProviderConfig groq =
      OpenAICompatibleProviderConfig(
    providerId: 'groq-openai',
    displayName: 'Groq (OpenAI-compatible)',
    description:
        'Groq AI models using OpenAI-compatible interface for ultra-fast inference',
    defaultBaseUrl: ProviderDefaults.groqBaseUrl,
    defaultModel: ProviderDefaults.groqDefaultModel,
    supportedCapabilities: _bestEffortCapabilities,
  );

  /// OpenRouter configuration using OpenAI-compatible interface
  static const OpenAICompatibleProviderConfig openRouter =
      OpenAICompatibleProviderConfig(
    providerId: 'openrouter',
    displayName: 'OpenRouter',
    description: 'OpenRouter unified API for multiple AI models',
    defaultBaseUrl: ProviderDefaults.openRouterBaseUrl,
    defaultModel: ProviderDefaults.openRouterDefaultModel,
    supportedCapabilities: _bestEffortCapabilities,
  );

  /// Get all available OpenAI-compatible configurations
  static List<OpenAICompatibleProviderConfig> getAllConfigs() {
    return [
      deepseek,
      gemini,
      xai,
      groq,
      openRouter,
    ];
  }

  /// Get configuration by provider ID
  static OpenAICompatibleProviderConfig? getConfig(String providerId) {
    switch (providerId) {
      case 'deepseek-openai':
        return deepseek;
      case 'google-openai':
        return gemini;
      case 'xai-openai':
        return xai;
      case 'groq-openai':
        return groq;
      case 'openrouter':
        return openRouter;
      default:
        return null;
    }
  }

  /// Check if a provider ID is OpenAI-compatible
  static bool isOpenAICompatible(String providerId) {
    return getConfig(providerId) != null;
  }

  /// Get model capabilities for a specific provider and model (legacy).
  ///
  /// Removed: LLM Dart does not maintain per-model matrices.
}
