import '../../core/capability.dart';
import '../config/provider_defaults.dart';

/// Legacy map-based defaults for OpenAI-compatible provider presets.
///
/// Provider-owned services such as DeepSeek, Groq, Phind, and xAI should use
/// their dedicated providers instead of old `*-openai` aliases. Prefer
/// `OpenAICompatibleConfigs` for typed modern provider configuration.
class OpenAICompatibleDefaults {
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
      openRouter,
      githubCopilot,
      togetherAI,
    ];
  }

  /// Get configuration by provider ID.
  static Map<String, dynamic>? getConfig(String providerId) {
    switch (providerId) {
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
