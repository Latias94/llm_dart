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

const String _deepInfraOpenAIBaseUrl = 'https://api.deepinfra.com/v1/';
const String _deepInfraOpenAIDefaultEndpointPrefix = 'openai';
const String _deepInfraOpenAIDefaultModel =
    'meta-llama/Meta-Llama-3.1-8B-Instruct';

const String _fireworksOpenAIBaseUrl = 'https://api.fireworks.ai/inference/v1/';
const String _fireworksOpenAIDefaultModel =
    'accounts/fireworks/models/llama-v3p1-8b-instruct';

const String _cerebrasOpenAIBaseUrl = 'https://api.cerebras.ai/v1/';
const String _cerebrasOpenAIDefaultModel = 'llama3.1-8b';

const String _vercelV0OpenAIBaseUrl = 'https://api.v0.dev/v1/';
const String _vercelV0OpenAIDefaultModel = 'v0-1.5-md';

const String _basetenOpenAIBaseUrl = 'https://inference.baseten.co/v1/';
const String _basetenOpenAIDefaultModel = 'deepseek-ai/DeepSeek-V3.1';

const String _openRouterBaseUrl = 'https://openrouter.ai/api/v1/';
const String _openRouterDefaultModel = 'openai/gpt-4';

const String _githubCopilotBaseUrl = 'https://api.githubcopilot.com/';
const String _githubCopilotDefaultModel = 'gpt-4';

const String _togetherAIBaseUrl = 'https://api.together.xyz/v1/';
const String _togetherAIDefaultModel = 'meta-llama/Llama-3-70b-chat-hf';

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

  /// DeepInfra configuration using OpenAI-compatible interface
  static const OpenAICompatibleProviderConfig deepinfra =
      OpenAICompatibleProviderConfig(
    providerId: 'deepinfra-openai',
    displayName: 'DeepInfra (OpenAI-compatible)',
    description: 'DeepInfra models using an OpenAI-compatible interface',
    defaultBaseUrl: _deepInfraOpenAIBaseUrl,
    defaultEndpointPrefix: _deepInfraOpenAIDefaultEndpointPrefix,
    defaultModel: _deepInfraOpenAIDefaultModel,
    supportedCapabilities: _bestEffortCapabilities,
  );

  /// Fireworks configuration using OpenAI-compatible interface
  static const OpenAICompatibleProviderConfig fireworks =
      OpenAICompatibleProviderConfig(
    providerId: 'fireworks-openai',
    displayName: 'Fireworks (OpenAI-compatible)',
    description: 'Fireworks models using an OpenAI-compatible interface',
    defaultBaseUrl: _fireworksOpenAIBaseUrl,
    defaultModel: _fireworksOpenAIDefaultModel,
    supportedCapabilities: _bestEffortCapabilities,
  );

  /// Cerebras configuration using OpenAI-compatible interface
  static const OpenAICompatibleProviderConfig cerebras =
      OpenAICompatibleProviderConfig(
    providerId: 'cerebras-openai',
    displayName: 'Cerebras (OpenAI-compatible)',
    description: 'Cerebras models using an OpenAI-compatible interface',
    defaultBaseUrl: _cerebrasOpenAIBaseUrl,
    defaultModel: _cerebrasOpenAIDefaultModel,
    supportedCapabilities: _bestEffortCapabilities,
  );

  /// Vercel v0 configuration using OpenAI-compatible interface
  static const OpenAICompatibleProviderConfig vercelV0 =
      OpenAICompatibleProviderConfig(
    providerId: 'vercel-v0',
    displayName: 'Vercel v0 (OpenAI-compatible)',
    description: 'Vercel v0 models using an OpenAI-compatible interface',
    defaultBaseUrl: _vercelV0OpenAIBaseUrl,
    defaultModel: _vercelV0OpenAIDefaultModel,
    supportedCapabilities: _bestEffortCapabilities,
  );

  /// Baseten configuration using OpenAI-compatible interface
  static const OpenAICompatibleProviderConfig baseten =
      OpenAICompatibleProviderConfig(
    providerId: 'baseten-openai',
    displayName: 'Baseten (OpenAI-compatible)',
    description: 'Baseten models using an OpenAI-compatible interface',
    defaultBaseUrl: _basetenOpenAIBaseUrl,
    defaultModel: _basetenOpenAIDefaultModel,
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
    defaultBaseUrl: _openRouterBaseUrl,
    defaultModel: _openRouterDefaultModel,
    supportedCapabilities: _bestEffortCapabilities,
  );

  /// GitHub Copilot Chat configuration using OpenAI-compatible interface.
  static const OpenAICompatibleProviderConfig githubCopilot =
      OpenAICompatibleProviderConfig(
    providerId: 'github-copilot',
    displayName: 'GitHub Copilot',
    description: 'GitHub Copilot Chat via an OpenAI-compatible endpoint',
    defaultBaseUrl: _githubCopilotBaseUrl,
    defaultModel: _githubCopilotDefaultModel,
    supportedCapabilities: _bestEffortCapabilities,
  );

  /// Together AI configuration using OpenAI-compatible interface.
  static const OpenAICompatibleProviderConfig togetherAI =
      OpenAICompatibleProviderConfig(
    providerId: 'together-ai',
    displayName: 'Together AI',
    description: 'Together AI models via an OpenAI-compatible endpoint',
    defaultBaseUrl: _togetherAIBaseUrl,
    defaultModel: _togetherAIDefaultModel,
    supportedCapabilities: _bestEffortCapabilities,
  );

  /// Get all available OpenAI-compatible configurations
  static List<OpenAICompatibleProviderConfig> getAllConfigs() {
    return [
      deepseek,
      gemini,
      deepinfra,
      fireworks,
      cerebras,
      vercelV0,
      baseten,
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
      case 'deepinfra-openai':
        return deepinfra;
      case 'fireworks-openai':
        return fireworks;
      case 'cerebras-openai':
        return cerebras;
      case 'vercel-v0':
        return vercelV0;
      case 'baseten-openai':
        return baseten;
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
