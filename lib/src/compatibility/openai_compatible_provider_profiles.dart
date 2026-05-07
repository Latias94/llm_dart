part of 'openai_compatible_configs.dart';

const OpenAICompatibleProviderConfig _deepseekOpenAICompatibleConfig =
    OpenAICompatibleProviderConfig(
  providerId: 'deepseek-openai',
  displayName: 'DeepSeek (OpenAI-compatible)',
  description: 'DeepSeek AI models using OpenAI-compatible interface',
  defaultBaseUrl: ProviderDefaults.deepseekBaseUrl,
  defaultModel: ProviderDefaults.deepseekDefaultModel,
  supportedCapabilities: {
    LLMCapability.chat,
    LLMCapability.streaming,
    LLMCapability.toolCalling,
    LLMCapability.reasoning,
  },
  // For unknown DeepSeek models, assume basic capabilities.
  defaultCapabilities: {
    LLMCapability.chat,
    LLMCapability.streaming,
    LLMCapability.toolCalling,
  },
  allowDynamicCapabilities: true,
  supportsReasoningEffort: false,
  supportsStructuredOutput: true,
  modelConfigs: {
    'deepseek-chat': ModelCapabilityConfig(
      supportsReasoning: false,
      supportsVision: false,
      supportsToolCalling: true,
      maxContextLength: 32768,
    ),
    'deepseek-reasoner': ModelCapabilityConfig(
      supportsReasoning: true,
      supportsVision: false,
      supportsToolCalling: true,
      maxContextLength: 32768,
      disableTemperature: true,
      disableTopP: true,
    ),
  },
);

final OpenAICompatibleProviderConfig _geminiOpenAICompatibleConfig =
    OpenAICompatibleProviderConfig(
  providerId: 'google-openai',
  displayName: 'Google Gemini (OpenAI-compatible)',
  description: 'Google Gemini models using OpenAI-compatible interface',
  defaultBaseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai/',
  defaultModel: 'gemini-2.0-flash',
  supportedCapabilities: {
    LLMCapability.chat,
    LLMCapability.streaming,
    LLMCapability.toolCalling,
    LLMCapability.reasoning,
    LLMCapability.embedding,
  },
  supportsReasoningEffort: true,
  supportsStructuredOutput: true,
  parameterMappings: {
    'reasoning_effort': 'reasoning_effort',
    'include_thoughts': 'include_thoughts',
    'thinking_budget': 'thinking_budget',
  },
  requestBodyTransformer: GoogleRequestBodyTransformer(),
  headersTransformer: GoogleHeadersTransformer(),
  modelConfigs: {
    'gemini-2.0-flash': ModelCapabilityConfig(
      supportsReasoning: false,
      supportsVision: true,
      supportsToolCalling: true,
      maxContextLength: 1000000,
    ),
    'gemini-2.5-flash-preview-05-20': ModelCapabilityConfig(
      supportsReasoning: true,
      supportsVision: true,
      supportsToolCalling: true,
      maxContextLength: 1000000,
    ),
    'text-embedding-004': ModelCapabilityConfig(
      supportsReasoning: false,
      supportsVision: false,
      supportsToolCalling: false,
      maxContextLength: 2048,
    ),
  },
);

const OpenAICompatibleProviderConfig _xaiOpenAICompatibleConfig =
    OpenAICompatibleProviderConfig(
  providerId: 'xai-openai',
  displayName: 'xAI Grok (OpenAI-compatible)',
  description: 'xAI Grok models using OpenAI-compatible interface',
  defaultBaseUrl: ProviderDefaults.xaiBaseUrl,
  defaultModel: ProviderDefaults.xaiDefaultModel,
  supportedCapabilities: {
    LLMCapability.chat,
    LLMCapability.streaming,
    LLMCapability.toolCalling,
    LLMCapability.reasoning,
  },
  supportsReasoningEffort: false,
  supportsStructuredOutput: true,
  modelConfigs: {
    'grok-3': ModelCapabilityConfig(
      supportsReasoning: false,
      supportsVision: true,
      supportsToolCalling: true,
      maxContextLength: 131072,
    ),
    'grok-3-latest': ModelCapabilityConfig(
      supportsReasoning: false,
      supportsVision: true,
      supportsToolCalling: true,
      maxContextLength: 131072,
    ),
  },
);

const OpenAICompatibleProviderConfig _groqOpenAICompatibleConfig =
    OpenAICompatibleProviderConfig(
  providerId: 'groq-openai',
  displayName: 'Groq (OpenAI-compatible)',
  description:
      'Groq AI models using OpenAI-compatible interface for ultra-fast inference',
  defaultBaseUrl: ProviderDefaults.groqBaseUrl,
  defaultModel: ProviderDefaults.groqDefaultModel,
  supportedCapabilities: {
    LLMCapability.chat,
    LLMCapability.streaming,
    LLMCapability.toolCalling,
  },
  // Groq focuses on speed, so default capabilities are conservative.
  defaultCapabilities: {
    LLMCapability.chat,
    LLMCapability.streaming,
  },
  allowDynamicCapabilities: true,
  supportsReasoningEffort: false,
  supportsStructuredOutput: true,
  modelConfigs: {
    'llama-3.3-70b-versatile': ModelCapabilityConfig(
      supportsReasoning: false,
      supportsVision: false,
      supportsToolCalling: true,
      maxContextLength: 32768,
    ),
    'mixtral-8x7b-32768': ModelCapabilityConfig(
      supportsReasoning: false,
      supportsVision: false,
      supportsToolCalling: true,
      maxContextLength: 32768,
    ),
  },
);

const OpenAICompatibleProviderConfig _phindOpenAICompatibleConfig =
    OpenAICompatibleProviderConfig(
  providerId: 'phind-openai',
  displayName: 'Phind (OpenAI-compatible)',
  description: 'Phind AI models using OpenAI-compatible interface',
  defaultBaseUrl: ProviderDefaults.phindBaseUrl,
  defaultModel: ProviderDefaults.phindDefaultModel,
  supportedCapabilities: {
    LLMCapability.chat,
    LLMCapability.streaming,
    LLMCapability.toolCalling,
  },
  supportsReasoningEffort: false,
  supportsStructuredOutput: false,
  modelConfigs: {
    'Phind-70B': ModelCapabilityConfig(
      supportsReasoning: false,
      supportsVision: false,
      supportsToolCalling: true,
      maxContextLength: 32768,
    ),
  },
);

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

final List<OpenAICompatibleProviderConfig> _openAICompatibleProviderProfiles =
    <OpenAICompatibleProviderConfig>[
  _deepseekOpenAICompatibleConfig,
  _geminiOpenAICompatibleConfig,
  _xaiOpenAICompatibleConfig,
  _groqOpenAICompatibleConfig,
  _phindOpenAICompatibleConfig,
  _openRouterOpenAICompatibleConfig,
];

final Map<String, OpenAICompatibleProviderConfig>
    _openAICompatibleProviderProfilesById =
    <String, OpenAICompatibleProviderConfig>{
  for (final profile in _openAICompatibleProviderProfiles)
    profile.providerId: profile,
};
