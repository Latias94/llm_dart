import '../../core/capability.dart';
import 'openai_compatible_provider_config.dart';

/// Pre-configured OpenAI-compatible provider configurations.
///
/// Dedicated providers such as DeepSeek, Google, Groq, Phind, and xAI are no
/// longer duplicated here as `*-openai` aliases. They own their provider
/// options through first-class facades. This registry is for OpenAI-family
/// endpoints that either need a special compatibility bridge, like OpenRouter,
/// or do not yet have a dedicated provider facade.
class OpenAICompatibleConfigs {
  /// OpenRouter configuration using OpenAI-compatible interface
  static const OpenAICompatibleProviderConfig openRouter =
      _openRouterOpenAICompatibleConfig;

  /// GitHub Copilot Chat API using the generic OpenAI-family compatibility path.
  static const OpenAICompatibleProviderConfig githubCopilot =
      _githubCopilotOpenAICompatibleConfig;

  /// Together AI using the generic OpenAI-family compatibility path.
  static const OpenAICompatibleProviderConfig togetherAI =
      _togetherAIOpenAICompatibleConfig;

  /// Get all available OpenAI-compatible configurations
  static List<OpenAICompatibleProviderConfig> getAllConfigs() {
    return List<OpenAICompatibleProviderConfig>.of(
      _openAICompatibleProviderProfiles,
    );
  }

  /// Get configuration by provider ID
  static OpenAICompatibleProviderConfig? getConfig(String providerId) {
    return _openAICompatibleProviderProfilesById[providerId];
  }

  /// Check if a provider ID is OpenAI-compatible
  static bool isOpenAICompatible(String providerId) {
    return getConfig(providerId) != null;
  }

  /// Get model capabilities for a specific provider and model
  static ModelCapabilityConfig? getModelCapabilities(
      String providerId, String model) {
    final config = getConfig(providerId);
    return config?.modelConfigs[model];
  }
}

const String _openRouterBaseUrl = 'https://openrouter.ai/api/v1/';
const String _openRouterDefaultModel = 'openai/gpt-4';
const String _githubCopilotBaseUrl =
    'https://api.githubcopilot.com/chat/completions';
const String _githubCopilotDefaultModel = 'gpt-4';
const String _togetherAIBaseUrl = 'https://api.together.xyz/v1/';
const String _togetherAIDefaultModel = 'meta-llama/Llama-3-70b-chat-hf';

const OpenAICompatibleProviderConfig _openRouterOpenAICompatibleConfig =
    OpenAICompatibleProviderConfig(
  providerId: 'openrouter',
  displayName: 'OpenRouter',
  description: 'OpenRouter unified API for multiple AI models',
  defaultBaseUrl: _openRouterBaseUrl,
  defaultModel: _openRouterDefaultModel,
  supportedCapabilities: {
    LLMCapability.chat,
    LLMCapability.streaming,
    LLMCapability.toolCalling,
    LLMCapability.vision,
    LLMCapability.liveSearch,
  },
  supportsReasoningEffort: false,
  supportsStructuredOutput: true,
  parameterMappings: {
    'search_prompt': 'search_prompt',
    'use_online_shortcut': 'use_online_shortcut',
  },
  modelConfigs: {
    'openai/gpt-4': ModelCapabilityConfig(
      supportsReasoning: false,
      supportsVision: true,
      supportsToolCalling: true,
      maxContextLength: 8192,
    ),
    'anthropic/claude-3.5-sonnet': ModelCapabilityConfig(
      supportsReasoning: false,
      supportsVision: true,
      supportsToolCalling: true,
      maxContextLength: 200000,
    ),
  },
);

const OpenAICompatibleProviderConfig _githubCopilotOpenAICompatibleConfig =
    OpenAICompatibleProviderConfig(
  providerId: 'github-copilot',
  displayName: 'GitHub Copilot',
  description: 'GitHub Copilot Chat API',
  defaultBaseUrl: _githubCopilotBaseUrl,
  defaultModel: _githubCopilotDefaultModel,
  supportedCapabilities: {
    LLMCapability.chat,
    LLMCapability.streaming,
    LLMCapability.toolCalling,
  },
);

const OpenAICompatibleProviderConfig _togetherAIOpenAICompatibleConfig =
    OpenAICompatibleProviderConfig(
  providerId: 'together-ai',
  displayName: 'Together AI',
  description: 'Together AI platform for open source models',
  defaultBaseUrl: _togetherAIBaseUrl,
  defaultModel: _togetherAIDefaultModel,
  supportedCapabilities: {
    LLMCapability.chat,
    LLMCapability.streaming,
    LLMCapability.toolCalling,
  },
);

final List<OpenAICompatibleProviderConfig> _openAICompatibleProviderProfiles =
    <OpenAICompatibleProviderConfig>[
  _openRouterOpenAICompatibleConfig,
  _githubCopilotOpenAICompatibleConfig,
  _togetherAIOpenAICompatibleConfig,
];

final Map<String, OpenAICompatibleProviderConfig>
    _openAICompatibleProviderProfilesById =
    <String, OpenAICompatibleProviderConfig>{
  for (final profile in _openAICompatibleProviderProfiles)
    profile.providerId: profile,
};
