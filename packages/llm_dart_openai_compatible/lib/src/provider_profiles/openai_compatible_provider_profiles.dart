import 'package:llm_dart_core/llm_dart_core.dart';

/// Google-specific request body transformer for OpenAI-compatible interface.
///
/// This transformer handles Google Gemini's specific thinking/reasoning
/// parameters when using the OpenAI-compatible interface.
class GoogleRequestBodyTransformer implements RequestBodyTransformer {
  const GoogleRequestBodyTransformer();

  @override
  Map<String, dynamic> transform(
    Map<String, dynamic> body,
    LLMConfig config,
    OpenAICompatibleProviderConfig providerConfig,
  ) {
    final transformedBody = Map<String, dynamic>.from(body);

    _addThinkingConfig(transformedBody, config);
    _addReasoningEffort(transformedBody, config);

    return transformedBody;
  }

  void _addThinkingConfig(Map<String, dynamic> body, LLMConfig config) {
    final reasoning = config.getExtension<bool>('reasoning') ?? false;
    final includeThoughts = config.getExtension<bool>('includeThoughts');
    final thinkingBudgetTokens =
        config.getExtension<int>('thinkingBudgetTokens');

    if (!reasoning && includeThoughts == null && thinkingBudgetTokens == null) {
      return;
    }

    final extraBody = body['extra_body'] as Map<String, dynamic>? ?? {};
    final configSection = extraBody['config'] as Map<String, dynamic>? ?? {};
    final thinkingConfig = <String, dynamic>{};

    if (includeThoughts != null) {
      thinkingConfig['includeThoughts'] = includeThoughts;
    } else if (reasoning) {
      thinkingConfig['includeThoughts'] = true;
    }

    if (thinkingBudgetTokens != null) {
      thinkingConfig['thinkingBudget'] = thinkingBudgetTokens;
    }

    if (thinkingConfig.isNotEmpty) {
      configSection['thinkingConfig'] = thinkingConfig;
      extraBody['config'] = configSection;
      body['extra_body'] = extraBody;
    }
  }

  void _addReasoningEffort(Map<String, dynamic> body, LLMConfig config) {
    final reasoningEffortString =
        config.getExtension<String>('reasoningEffort');
    if (reasoningEffortString == null || reasoningEffortString.isEmpty) {
      return;
    }

    final extraBody = body['extra_body'] as Map<String, dynamic>? ?? {};
    extraBody['reasoning_effort'] = reasoningEffortString;
    body['extra_body'] = extraBody;
  }
}

/// Google-specific headers transformer for OpenAI-compatible interface.
///
/// This transformer handles Google Gemini's specific headers when using
/// the OpenAI-compatible interface.
class GoogleHeadersTransformer implements HeadersTransformer {
  const GoogleHeadersTransformer();

  @override
  Map<String, String> transform(
    Map<String, String> headers,
    LLMConfig config,
    OpenAICompatibleProviderConfig providerConfig,
  ) {
    final transformedHeaders = Map<String, String>.from(headers);

    _addThinkingHeaders(transformedHeaders, config);

    return transformedHeaders;
  }

  void _addThinkingHeaders(Map<String, String> headers, LLMConfig config) {
    final reasoning = config.getExtension<bool>('reasoning') ?? false;
    final includeThoughts = config.getExtension<bool>('includeThoughts');

    if (reasoning || includeThoughts == true) {
      headers['X-Goog-Include-Thoughts'] = 'true';
    }
  }
}

/// Pre-configured OpenAI-compatible provider configurations.
///
/// This class defines the provider-level capability profiles for
/// common OpenAI-compatible vendors (DeepSeek, Gemini, xAI, Groq, etc.).
/// It is used by the main `llm_dart` package to register provider
/// factories without embedding provider metadata into the core package.
class OpenAICompatibleProviderProfiles {
  /// DeepSeek configuration using OpenAI-compatible interface.
  static const OpenAICompatibleProviderConfig deepseek =
      OpenAICompatibleProviderConfig(
    providerId: 'deepseek-openai',
    displayName: 'DeepSeek (OpenAI-compatible)',
    description: 'DeepSeek AI models using OpenAI-compatible interface',
    defaultBaseUrl: 'https://api.deepseek.com/v1/',
    defaultModel: 'deepseek-chat',
    supportedCapabilities: {
      LLMCapability.chat,
      LLMCapability.streaming,
      LLMCapability.toolCalling,
      LLMCapability.reasoning,
    },
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

  /// Google Gemini configuration using OpenAI-compatible interface.
  static final OpenAICompatibleProviderConfig gemini =
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

  /// xAI Grok configuration using OpenAI-compatible interface.
  static const OpenAICompatibleProviderConfig xai =
      OpenAICompatibleProviderConfig(
    providerId: 'xai-openai',
    displayName: 'xAI Grok (OpenAI-compatible)',
    description: 'xAI Grok models using OpenAI-compatible interface',
    defaultBaseUrl: 'https://api.x.ai/v1/',
    defaultModel: 'grok-3',
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

  /// Groq configuration using OpenAI-compatible interface.
  static const OpenAICompatibleProviderConfig groq =
      OpenAICompatibleProviderConfig(
    providerId: 'groq-openai',
    displayName: 'Groq (OpenAI-compatible)',
    description:
        'Groq AI models using OpenAI-compatible interface for ultra-fast inference',
    defaultBaseUrl: 'https://api.groq.com/openai/v1/',
    defaultModel: 'llama-3.3-70b-versatile',
    supportedCapabilities: {
      LLMCapability.chat,
      LLMCapability.streaming,
      LLMCapability.toolCalling,
    },
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

  /// Phind configuration using OpenAI-compatible interface.
  static const OpenAICompatibleProviderConfig phind =
      OpenAICompatibleProviderConfig(
    providerId: 'phind-openai',
    displayName: 'Phind (OpenAI-compatible)',
    description: 'Phind AI models using OpenAI-compatible interface',
    defaultBaseUrl: 'https://api.phind.com/v1/',
    defaultModel: 'Phind-70B',
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

  /// OpenRouter configuration using OpenAI-compatible interface.
  static const OpenAICompatibleProviderConfig openRouter =
      OpenAICompatibleProviderConfig(
    providerId: 'openrouter',
    displayName: 'OpenRouter',
    description: 'OpenRouter unified API for multiple AI models',
    defaultBaseUrl: 'https://openrouter.ai/api/v1/',
    defaultModel: 'openai/gpt-4',
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

  /// Get all available OpenAI-compatible provider configurations.
  static List<OpenAICompatibleProviderConfig> getAllConfigs() {
    return [
      deepseek,
      gemini,
      xai,
      groq,
      phind,
      openRouter,
    ];
  }

  /// Get configuration by provider ID.
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
      case 'phind-openai':
        return phind;
      case 'openrouter':
        return openRouter;
      default:
        return null;
    }
  }

  /// Check if a provider ID is OpenAI-compatible.
  static bool isOpenAICompatible(String providerId) {
    return getConfig(providerId) != null;
  }

  /// Get model capabilities for a specific provider and model.
  static ModelCapabilityConfig? getModelCapabilities(
    String providerId,
    String model,
  ) {
    final config = getConfig(providerId);
    return config?.modelConfigs[model];
  }
}
