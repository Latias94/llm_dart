import 'package:llm_dart_core/llm_dart_core.dart';

/// DeepSeek provider configuration
///
/// This class contains all configuration options for the DeepSeek providers.
/// It's extracted from the main provider to improve modularity and reusability.
class DeepSeekConfig {
  final String apiKey;
  final String baseUrl;
  final String model;
  final int? maxTokens;
  final double? temperature;
  final String? systemPrompt;
  final Duration? timeout;

  final double? topP;
  final int? topK;
  final List<Tool>? tools;
  final ToolChoice? toolChoice;

  // DeepSeek-specific parameters
  final bool? logprobs;
  final int? topLogprobs;
  final double? frequencyPenalty;
  final double? presencePenalty;
  final Map<String, dynamic>? responseFormat;

  /// Reference to original LLMConfig for accessing extensions
  final LLMConfig? _originalConfig;

  static const String _defaultBaseUrl = 'https://api.deepseek.com/v1/';
  static const String _defaultModel = 'deepseek-chat';

  const DeepSeekConfig({
    required this.apiKey,
    this.baseUrl = _defaultBaseUrl,
    this.model = _defaultModel,
    this.maxTokens,
    this.temperature,
    this.systemPrompt,
    this.timeout,
    this.topP,
    this.topK,
    this.tools,
    this.toolChoice,
    this.logprobs,
    this.topLogprobs,
    this.frequencyPenalty,
    this.presencePenalty,
    this.responseFormat,
    LLMConfig? originalConfig,
  }) : _originalConfig = originalConfig;

  /// Create DeepSeekConfig from unified LLMConfig
  factory DeepSeekConfig.fromLLMConfig(LLMConfig config) {
    // Apply provider-specific defaults when the unified config leaves
    // baseUrl/model empty. This keeps the fallback logic in a single,
    // well-defined place.
    final resolvedBaseUrl =
        config.baseUrl.isNotEmpty ? config.baseUrl : _defaultBaseUrl;
    final resolvedModel =
        config.model.isNotEmpty ? config.model : _defaultModel;

    return DeepSeekConfig(
      apiKey: config.apiKey!,
      baseUrl: resolvedBaseUrl,
      model: resolvedModel,
      maxTokens: config.maxTokens,
      temperature: config.temperature,
      systemPrompt: config.systemPrompt,
      timeout: config.timeout,
      topP: config.topP,
      topK: config.topK,
      tools: config.tools,
      toolChoice: config.toolChoice,
      // DeepSeek-specific parameters from extensions
      //
      // Prefer well-known keys from LLMConfigKeys for new code, while
      // still honoring the historical wire-style keys for backwards
      // compatibility with existing callers and tests.
      logprobs: config.getExtension<bool>(LLMConfigKeys.logprobs) ??
          config.getExtension<bool>('logprobs'),
      topLogprobs: config.getExtension<int>(LLMConfigKeys.topLogprobs) ??
          config.getExtension<int>('top_logprobs'),
      frequencyPenalty:
          config.getExtension<double>(LLMConfigKeys.frequencyPenalty) ??
              config.getExtension<double>('frequency_penalty'),
      presencePenalty:
          config.getExtension<double>(LLMConfigKeys.presencePenalty) ??
              config.getExtension<double>('presence_penalty'),
      responseFormat:
          config.getExtension<Map<String, dynamic>>(LLMConfigKeys.responseFormat) ??
              config.getExtension<Map<String, dynamic>>('response_format'),
      originalConfig: config,
    );
  }

  /// Get extension value from original config
  T? getExtension<T>(String key) => _originalConfig?.getExtension<T>(key);

  /// Get the original LLMConfig for HTTP configuration
  LLMConfig? get originalConfig => _originalConfig;

  /// Check if this model supports reasoning/thinking
  bool get supportsReasoning {
    // DeepSeek reasoner model supports reasoning
    // Reference: https://api-docs.deepseek.com/api/create-chat-completion
    return model == 'deepseek-reasoner';
  }

  /// Check if this model supports vision
  bool get supportsVision {
    // Currently no vision models available in DeepSeek API
    // Reference: https://api-docs.deepseek.com/api/list-models
    return false;
  }

  /// Check if this model supports tool calling
  bool get supportsToolCalling {
    // Both deepseek-chat and deepseek-reasoner support tool calling
    // Reference: https://api-docs.deepseek.com/guides/function_calling
    return model == 'deepseek-chat' || model == 'deepseek-reasoner';
  }

  /// Check if this model supports code generation
  bool get supportsCodeGeneration {
    // Both models can handle code generation tasks
    return model == 'deepseek-chat' || model == 'deepseek-reasoner';
  }

  DeepSeekConfig copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
    int? maxTokens,
    double? temperature,
    String? systemPrompt,
    Duration? timeout,
    double? topP,
    int? topK,
    List<Tool>? tools,
    ToolChoice? toolChoice,
    bool? logprobs,
    int? topLogprobs,
    double? frequencyPenalty,
    double? presencePenalty,
    Map<String, dynamic>? responseFormat,
  }) =>
      DeepSeekConfig(
        apiKey: apiKey ?? this.apiKey,
        baseUrl: baseUrl ?? this.baseUrl,
        model: model ?? this.model,
        maxTokens: maxTokens ?? this.maxTokens,
        temperature: temperature ?? this.temperature,
        systemPrompt: systemPrompt ?? this.systemPrompt,
        timeout: timeout ?? this.timeout,
        topP: topP ?? this.topP,
        topK: topK ?? this.topK,
        tools: tools ?? this.tools,
        toolChoice: toolChoice ?? this.toolChoice,
        logprobs: logprobs ?? this.logprobs,
        topLogprobs: topLogprobs ?? this.topLogprobs,
        frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
        presencePenalty: presencePenalty ?? this.presencePenalty,
        responseFormat: responseFormat ?? this.responseFormat,
      );
}
