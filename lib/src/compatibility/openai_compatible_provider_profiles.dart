part of 'openai_compatible_configs.dart';

const OpenAICompatibleProviderConfig _openRouterOpenAICompatibleConfig =
    OpenAICompatibleProviderConfig(
  providerId: 'openrouter',
  displayName: 'OpenRouter',
  description: 'OpenRouter unified API for multiple AI models',
  defaultBaseUrl: ProviderDefaults.openRouterBaseUrl,
  defaultModel: ProviderDefaults.openRouterDefaultModel,
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
  defaultBaseUrl: ProviderDefaults.githubCopilotBaseUrl,
  defaultModel: ProviderDefaults.githubCopilotDefaultModel,
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
  defaultBaseUrl: ProviderDefaults.togetherAIBaseUrl,
  defaultModel: ProviderDefaults.togetherAIDefaultModel,
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
