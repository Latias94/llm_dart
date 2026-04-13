import '../../core/capability.dart';
import '../provider_defaults.dart';

/// Legacy map-based defaults for OpenAI-compatible providers.
///
/// Prefer `OpenAICompatibleConfigs` for typed modern provider configuration.
class OpenAICompatibleDefaults {
  /// DeepSeek using OpenAI-compatible API.
  static const Map<String, dynamic> deepseek = {
    'providerId': 'deepseek-openai',
    'displayName': 'DeepSeek (OpenAI-compatible)',
    'description': 'DeepSeek AI models using OpenAI-compatible interface',
    'baseUrl': ProviderDefaults.deepseekBaseUrl,
    'model': ProviderDefaults.deepseekDefaultModel,
    'capabilities': {
      LLMCapability.chat,
      LLMCapability.streaming,
      LLMCapability.toolCalling,
      LLMCapability.reasoning,
    },
  };

  /// Groq using OpenAI-compatible API.
  static const Map<String, dynamic> groq = {
    'providerId': 'groq-openai',
    'displayName': 'Groq (OpenAI-compatible)',
    'description':
        'Groq AI models using OpenAI-compatible interface for ultra-fast inference',
    'baseUrl': ProviderDefaults.groqBaseUrl,
    'model': ProviderDefaults.groqDefaultModel,
    'capabilities': {
      LLMCapability.chat,
      LLMCapability.streaming,
      LLMCapability.toolCalling,
    },
  };

  /// xAI using OpenAI-compatible API.
  static const Map<String, dynamic> xai = {
    'providerId': 'xai-openai',
    'displayName': 'xAI Grok (OpenAI-compatible)',
    'description': 'xAI Grok models using OpenAI-compatible interface',
    'baseUrl': ProviderDefaults.xaiBaseUrl,
    'model': ProviderDefaults.xaiDefaultModel,
    'capabilities': {
      LLMCapability.chat,
      LLMCapability.streaming,
      LLMCapability.toolCalling,
      LLMCapability.reasoning,
    },
  };

  /// Phind using OpenAI-compatible API.
  static const Map<String, dynamic> phind = {
    'providerId': 'phind-openai',
    'displayName': 'Phind (OpenAI-compatible)',
    'description': 'Phind AI models using OpenAI-compatible interface',
    'baseUrl': ProviderDefaults.phindBaseUrl,
    'model': ProviderDefaults.phindDefaultModel,
    'capabilities': {
      LLMCapability.chat,
      LLMCapability.streaming,
      LLMCapability.toolCalling,
    },
  };

  /// OpenRouter configuration.
  static const Map<String, dynamic> openRouter = {
    'providerId': 'openrouter',
    'displayName': 'OpenRouter',
    'description': 'OpenRouter unified API for multiple AI models',
    'baseUrl': ProviderDefaults.openRouterBaseUrl,
    'model': ProviderDefaults.openRouterDefaultModel,
    'capabilities': {
      LLMCapability.chat,
      LLMCapability.streaming,
      LLMCapability.toolCalling,
      LLMCapability.vision,
    },
  };

  /// GitHub Copilot configuration.
  static const Map<String, dynamic> githubCopilot = {
    'providerId': 'github-copilot',
    'displayName': 'GitHub Copilot',
    'description': 'GitHub Copilot Chat API',
    'baseUrl': ProviderDefaults.githubCopilotBaseUrl,
    'model': ProviderDefaults.githubCopilotDefaultModel,
    'capabilities': {
      LLMCapability.chat,
      LLMCapability.streaming,
      LLMCapability.toolCalling,
    },
  };

  /// Together AI configuration.
  static const Map<String, dynamic> togetherAI = {
    'providerId': 'together-ai',
    'displayName': 'Together AI',
    'description': 'Together AI platform for open source models',
    'baseUrl': ProviderDefaults.togetherAIBaseUrl,
    'model': ProviderDefaults.togetherAIDefaultModel,
    'capabilities': {
      LLMCapability.chat,
      LLMCapability.streaming,
      LLMCapability.toolCalling,
    },
  };

  /// Get all OpenAI-compatible configurations.
  static List<Map<String, dynamic>> getAllConfigs() {
    return [
      deepseek,
      groq,
      xai,
      phind,
      openRouter,
      githubCopilot,
      togetherAI,
    ];
  }

  /// Get configuration by provider ID.
  static Map<String, dynamic>? getConfig(String providerId) {
    switch (providerId) {
      case 'deepseek-openai':
        return deepseek;
      case 'groq-openai':
        return groq;
      case 'xai-openai':
        return xai;
      case 'phind-openai':
        return phind;
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
}
