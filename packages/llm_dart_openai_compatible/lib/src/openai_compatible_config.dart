import 'package:llm_dart_core/core/config.dart';
import 'package:llm_dart_core/core/provider_defaults.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_core/models/tool_models.dart';

import 'openai_request_config.dart';

/// Generic OpenAI-compatible configuration.
///
/// This config is used by providers that speak the OpenAI Chat Completions API
/// (or close variants) but are not "OpenAI the provider".
class OpenAICompatibleConfig implements OpenAIRequestConfig {
  @override
  final String providerId;

  @override
  final String providerName;

  @override
  final String apiKey;

  @override
  final String baseUrl;

  @override
  final String model;

  @override
  final Map<String, dynamic>? extraBody;

  @override
  final Map<String, String>? extraHeaders;

  @override
  final int? maxTokens;

  @override
  final double? temperature;

  @override
  final String? systemPrompt;

  @override
  final Duration? timeout;

  @override
  final double? topP;

  @override
  final int? topK;

  @override
  final List<Tool>? tools;

  @override
  final ToolChoice? toolChoice;

  @override
  final ReasoningEffort? reasoningEffort;

  @override
  final StructuredOutputFormat? jsonSchema;

  @override
  final String? voice;

  @override
  final String? embeddingEncodingFormat;

  @override
  final int? embeddingDimensions;

  @override
  final List<String>? stopSequences;

  @override
  final String? user;

  @override
  final ServiceTier? serviceTier;

  final LLMConfig? _originalConfig;

  const OpenAICompatibleConfig({
    required this.providerId,
    required this.providerName,
    required this.apiKey,
    required this.baseUrl,
    required this.model,
    this.extraBody,
    this.extraHeaders,
    this.maxTokens,
    this.temperature,
    this.systemPrompt,
    this.timeout,
    this.topP,
    this.topK,
    this.tools,
    this.toolChoice,
    this.reasoningEffort,
    this.jsonSchema,
    this.voice,
    this.embeddingEncodingFormat,
    this.embeddingDimensions,
    this.stopSequences,
    this.user,
    this.serviceTier,
    LLMConfig? originalConfig,
  }) : _originalConfig = originalConfig;

  factory OpenAICompatibleConfig.fromLLMConfig(
    LLMConfig config, {
    required String providerId,
    String? providerName,
  }) {
    return OpenAICompatibleConfig(
      providerId: providerId,
      providerName: providerName ?? providerId,
      apiKey: config.apiKey!,
      baseUrl: config.baseUrl,
      model: config.model.isEmpty
          ? ProviderDefaults.openaiDefaultModel
          : config.model,
      extraBody: config.getProviderOption<Map<String, dynamic>>(
        providerId,
        'extraBody',
      ),
      extraHeaders: config.getProviderOption<Map<String, String>>(
        providerId,
        'extraHeaders',
      ),
      maxTokens: config.maxTokens,
      temperature: config.temperature,
      systemPrompt: config.systemPrompt,
      timeout: config.timeout,
      topP: config.topP,
      topK: config.topK,
      tools: config.tools,
      toolChoice: config.toolChoice,
      stopSequences: config.stopSequences,
      user: config.user,
      serviceTier: config.serviceTier,
      reasoningEffort: ReasoningEffort.fromString(
        config.getProviderOption<String>(providerId, 'reasoningEffort'),
      ),
      jsonSchema: config.getProviderOption<StructuredOutputFormat>(
          providerId, 'jsonSchema'),
      voice: config.getProviderOption<String>(providerId, 'voice'),
      embeddingEncodingFormat: config.getProviderOption<String>(
        providerId,
        'embeddingEncodingFormat',
      ),
      embeddingDimensions:
          config.getProviderOption<int>(providerId, 'embeddingDimensions'),
      originalConfig: config,
    );
  }

  @override
  LLMConfig? get originalConfig => _originalConfig;

  @override
  T? getProviderOption<T>(String key) =>
      _originalConfig?.getProviderOption<T>(providerId, key);
}
