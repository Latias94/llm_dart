import 'package:llm_dart_core/core/config.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_core/models/tool_models.dart';

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

  String get apiKey;
  String get baseUrl;
  String get model;

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
