import 'package:llm_dart_core/llm_dart_core.dart';

/// Shared config surface required to talk to an OpenAI-style HTTP API.
///
/// This is intentionally an interface so both:
/// - `llm_dart_openai`'s OpenAI-specific config, and
/// - `llm_dart_openai_compatible`'s generic config
/// can be consumed by the same client/protocol implementation.
abstract class OpenAIRequestConfig {
  /// Registry/provider identifier used for provider-specific behavior.
  ///
  /// Examples: `openai`, `groq`, `openrouter`, `deepseek-openai`.
  String get providerId;

  /// Human-readable provider name used in errors/logging.
  ///
  /// Examples: `OpenAI`, `Groq`, `OpenRouter`.
  String get providerName;

  /// Optional API key for authenticating requests.
  ///
  /// OpenAI-compatible endpoints may be deployed without authentication (e.g.
  /// local gateways) or may rely on custom headers. When null/empty, the client
  /// should omit auth headers and let the server decide.
  String? get apiKey;
  String get baseUrl;
  String get model;

  /// Optional endpoint prefix inserted before every API endpoint path.
  ///
  /// This exists for OpenAI-compatible providers that mount the OpenAI routes
  /// under an additional path segment.
  ///
  /// Example: DeepInfra uses `/openai/*` routes, so `endpointPrefix` can be set
  /// to `openai` and calling `chat/completions` becomes `openai/chat/completions`.
  ///
  /// Notes:
  /// - The prefix may contain leading/trailing slashes; implementations should
  ///   normalize it.
  /// - This is applied to all endpoints (chat, embeddings, audio, images,
  ///   responses, etc.).
  String? get endpointPrefix;

  /// Extra request body fields merged into the final JSON payload.
  ///
  /// This is the escape hatch for provider-specific features (e.g. xAI live
  /// search `search_parameters`) that are not part of the standardized surface.
  ///
  /// If a key collides with a standard field, the extra body value wins.
  Map<String, dynamic>? get extraBody;

  /// Extra HTTP headers merged into the request headers.
  ///
  /// If a key collides with a standard header, the extra header value wins.
  Map<String, String>? get extraHeaders;

  int? get maxTokens;
  double? get temperature;
  String? get systemPrompt;
  Duration? get timeout;

  double? get topP;
  int? get topK;
  List<Tool>? get tools;
  ToolChoice? get toolChoice;
  ReasoningEffort? get reasoningEffort;
  StructuredOutputFormat? get jsonSchema;
  String? get voice;
  String? get embeddingEncodingFormat;
  int? get embeddingDimensions;
  List<String>? get stopSequences;
  String? get user;
  ServiceTier? get serviceTier;

  /// Reference to original unified config for HTTP customization and provider options.
  LLMConfig? get originalConfig;

  /// Read a provider-specific option from [originalConfig.providerOptions].
  ///
  /// This is the escape hatch for OpenAI-style optional parameters that are
  /// not part of the standardized surface.
  T? getProviderOption<T>(String key);
}
