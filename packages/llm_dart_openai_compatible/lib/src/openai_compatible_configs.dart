import 'package:llm_dart_core/llm_dart_core.dart';
import '../defaults.dart';

import 'openai_compatible_provider_config.dart';

const String _deepseekOpenAIBaseUrl = 'https://api.deepseek.com/v1/';
const String _deepseekOpenAIDefaultModel = 'deepseek-chat';

const String _groqOpenAIBaseUrl = 'https://api.groq.com/openai/v1/';
const String _groqOpenAIDefaultModel = 'llama-3.3-70b-versatile';

const String _xaiOpenAIBaseUrl = 'https://api.x.ai/v1/';
const String _xaiOpenAIDefaultModel = 'grok-3';

const String _googleOpenAIBaseUrl =
    'https://generativelanguage.googleapis.com/v1beta/openai/';
const String _googleOpenAIDefaultModel = 'gemini-2.0-flash';

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
    defaultBaseUrl: _deepseekOpenAIBaseUrl,
    defaultModel: _deepseekOpenAIDefaultModel,
    supportedCapabilities: _bestEffortCapabilities,
  );

  /// Google Gemini configuration using OpenAI-compatible interface
  static final OpenAICompatibleProviderConfig gemini =
      OpenAICompatibleProviderConfig(
    providerId: 'google-openai',
    displayName: 'Google Gemini (OpenAI-compatible)',
    description: 'Google Gemini models using OpenAI-compatible interface',
    defaultBaseUrl: _googleOpenAIBaseUrl,
    defaultModel: _googleOpenAIDefaultModel,
    supportedCapabilities: _bestEffortCapabilities,
  );

  /// xAI Grok configuration using OpenAI-compatible interface
  static const OpenAICompatibleProviderConfig xai =
      OpenAICompatibleProviderConfig(
    providerId: 'xai-openai',
    displayName: 'xAI Grok (OpenAI-compatible)',
    description: 'xAI Grok models using OpenAI-compatible interface',
    defaultBaseUrl: _xaiOpenAIBaseUrl,
    defaultModel: _xaiOpenAIDefaultModel,
    supportedCapabilities: _bestEffortCapabilities,
  );

  /// Groq configuration using OpenAI-compatible interface
  static const OpenAICompatibleProviderConfig groq =
      OpenAICompatibleProviderConfig(
    providerId: 'groq-openai',
    displayName: 'Groq (OpenAI-compatible)',
    description:
        'Groq AI models using OpenAI-compatible interface for ultra-fast inference',
    defaultBaseUrl: _groqOpenAIBaseUrl,
    defaultModel: _groqOpenAIDefaultModel,
    supportedCapabilities: _bestEffortCapabilities,
  );

  /// OpenRouter configuration using OpenAI-compatible interface
  static const OpenAICompatibleProviderConfig openRouter =
      OpenAICompatibleProviderConfig(
    providerId: 'openrouter',
    displayName: 'OpenRouter',
    description: 'OpenRouter unified API for multiple AI models',
    defaultBaseUrl: openRouterBaseUrl,
    defaultModel: openRouterDefaultModel,
    supportedCapabilities: _bestEffortCapabilities,
  );

  /// GitHub Copilot Chat configuration using OpenAI-compatible interface.
  static const OpenAICompatibleProviderConfig githubCopilot =
      OpenAICompatibleProviderConfig(
    providerId: 'github-copilot',
    displayName: 'GitHub Copilot',
    description: 'GitHub Copilot Chat via an OpenAI-compatible endpoint',
    defaultBaseUrl: githubCopilotBaseUrl,
    defaultModel: githubCopilotDefaultModel,
    supportedCapabilities: _bestEffortCapabilities,
  );

  /// Together AI configuration using OpenAI-compatible interface.
  static const OpenAICompatibleProviderConfig togetherAI =
      OpenAICompatibleProviderConfig(
    providerId: 'together-ai',
    displayName: 'Together AI',
    description: 'Together AI models via an OpenAI-compatible endpoint',
    defaultBaseUrl: togetherAIBaseUrl,
    defaultModel: togetherAIDefaultModel,
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
      githubCopilot,
      togetherAI,
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
      case 'github-copilot':
        return githubCopilot;
      case 'together-ai':
        return togetherAI;
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
