import 'package:llm_dart_core/llm_dart_core.dart';

/// Configuration for OpenAI-compatible providers
///
/// This configuration describes the common parameters needed to talk to
/// any provider that exposes an OpenAI-style REST API (chat/completions
/// endpoints, embeddings, etc.), independent of the actual vendor.
class OpenAICompatibleConfig {
  /// API key for authentication.
  final String apiKey;

  /// Base URL for the OpenAI-compatible API, e.g.:
  /// - https://api.openai.com/v1/
  /// - https://api.groq.com/openai/v1/
  /// - https://api.deepinfra.com/v1/openai/
  final String baseUrl;

  /// Default model identifier.
  final String model;

  /// Optional system prompt for chat models.
  final String? systemPrompt;

  /// Optional generation parameters.
  final int? maxTokens;
  final double? temperature;
  final double? topP;
  final int? topK;

  /// Optional tools and tool choice.
  final List<Tool>? tools;
  final ToolChoice? toolChoice;

  /// Reasoning support (for providers that expose reasoning_effort).
  final ReasoningEffort? reasoningEffort;

  /// Structured output configuration.
  final StructuredOutputFormat? jsonSchema;

  /// Stop sequences and user identifier.
  final List<String>? stopSequences;
  final String? user;

  /// Service tier for the request, if supported.
  final ServiceTier? serviceTier;

  /// Provider identifier used for logging/metrics and provider-specific tweaks.
  ///
  /// Examples:
  /// - "openai"
  /// - "groq"
  /// - "deepinfra"
  /// - "openrouter"
  final String providerId;

  /// Reference to the original LLMConfig for accessing extensions.
  final LLMConfig? _originalConfig;

  const OpenAICompatibleConfig({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
    required this.providerId,
    this.systemPrompt,
    this.maxTokens,
    this.temperature,
    this.topP,
    this.topK,
    this.tools,
    this.toolChoice,
    this.reasoningEffort,
    this.jsonSchema,
    this.stopSequences,
    this.user,
    this.serviceTier,
    LLMConfig? originalConfig,
  }) : _originalConfig = originalConfig;

  /// Get extension value from original config, if available.
  T? getExtension<T>(String key) => _originalConfig?.getExtension<T>(key);

  LLMConfig? get originalConfig => _originalConfig;

  OpenAICompatibleConfig copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
    String? systemPrompt,
    String? providerId,
    int? maxTokens,
    double? temperature,
    double? topP,
    int? topK,
    List<Tool>? tools,
    ToolChoice? toolChoice,
    ReasoningEffort? reasoningEffort,
    StructuredOutputFormat? jsonSchema,
    List<String>? stopSequences,
    String? user,
    ServiceTier? serviceTier,
  }) {
    return OpenAICompatibleConfig(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      providerId: providerId ?? this.providerId,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      maxTokens: maxTokens ?? this.maxTokens,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      topK: topK ?? this.topK,
      tools: tools ?? this.tools,
      toolChoice: toolChoice ?? this.toolChoice,
      reasoningEffort: reasoningEffort ?? this.reasoningEffort,
      jsonSchema: jsonSchema ?? this.jsonSchema,
      stopSequences: stopSequences ?? this.stopSequences,
      user: user ?? this.user,
      serviceTier: serviceTier ?? this.serviceTier,
      originalConfig: _originalConfig,
    );
  }
}

/// Preset configurations for common OpenAI-compatible providers.
///
/// These helpers fill in `baseUrl` and `providerId` for well-known vendors,
/// so callers only need to provide API keys and models.
class OpenAICompatibleConfigs {
  /// DeepSeek preset using its OpenAI-compatible endpoint.
  ///
  /// Base URL: https://api.deepseek.com/v1/
  static OpenAICompatibleConfig deepseekOpenAI({
    required String apiKey,
    String model = 'deepseek-chat',
    String baseUrl = 'https://api.deepseek.com/v1/',
    LLMConfig? originalConfig,
  }) {
    return OpenAICompatibleConfig(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      providerId: 'deepseek-openai',
      originalConfig: originalConfig,
    );
  }

  /// Google Gemini preset using its OpenAI-compatible endpoint.
  ///
  /// Base URL: https://generativelanguage.googleapis.com/v1beta/openai/
  static OpenAICompatibleConfig googleOpenAI({
    required String apiKey,
    String model = 'gemini-2.0-flash',
    String baseUrl = 'https://generativelanguage.googleapis.com/v1beta/openai/',
    LLMConfig? originalConfig,
  }) {
    return OpenAICompatibleConfig(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      providerId: 'google-openai',
      originalConfig: originalConfig,
    );
  }

  /// xAI Grok preset using its OpenAI-compatible endpoint.
  ///
  /// Base URL: https://api.x.ai/v1/
  static OpenAICompatibleConfig xaiOpenAI({
    required String apiKey,
    String model = 'grok-3',
    String baseUrl = 'https://api.x.ai/v1/',
    LLMConfig? originalConfig,
  }) {
    return OpenAICompatibleConfig(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      providerId: 'xai-openai',
      originalConfig: originalConfig,
    );
  }

  /// Groq preset using its OpenAI-compatible endpoint.
  ///
  /// Base URL: https://api.groq.com/openai/v1/
  static OpenAICompatibleConfig groqOpenAI({
    required String apiKey,
    String model = 'llama-3.3-70b-versatile',
    String baseUrl = 'https://api.groq.com/openai/v1/',
    LLMConfig? originalConfig,
  }) {
    return OpenAICompatibleConfig(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      providerId: 'groq-openai',
      originalConfig: originalConfig,
    );
  }

  /// Phind preset using its OpenAI-compatible endpoint.
  ///
  /// Base URL: https://api.phind.com/v1/
  static OpenAICompatibleConfig phindOpenAI({
    required String apiKey,
    String model = 'Phind-70B',
    String baseUrl = 'https://api.phind.com/v1/',
    LLMConfig? originalConfig,
  }) {
    return OpenAICompatibleConfig(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      providerId: 'phind-openai',
      originalConfig: originalConfig,
    );
  }

  /// DeepInfra preset using its OpenAI-compatible endpoint.
  ///
  /// Base URL: https://api.deepinfra.com/v1/openai/
  static OpenAICompatibleConfig deepinfra({
    required String apiKey,
    String model = 'meta-llama-3-8b-instruct',
    String baseUrl = 'https://api.deepinfra.com/v1/openai/',
    LLMConfig? originalConfig,
  }) {
    return OpenAICompatibleConfig(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      providerId: 'deepinfra',
      originalConfig: originalConfig,
    );
  }

  /// OpenRouter preset using its OpenAI-compatible endpoint.
  ///
  /// Base URL: https://openrouter.ai/api/v1/
  static OpenAICompatibleConfig openrouter({
    required String apiKey,
    required String model,
    String baseUrl = 'https://openrouter.ai/api/v1/',
    LLMConfig? originalConfig,
  }) {
    return OpenAICompatibleConfig(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      providerId: 'openrouter',
      originalConfig: originalConfig,
    );
  }
}
