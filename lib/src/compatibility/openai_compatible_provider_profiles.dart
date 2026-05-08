part of 'openai_compatible_configs.dart';

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
