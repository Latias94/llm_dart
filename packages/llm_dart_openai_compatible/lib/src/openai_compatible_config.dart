import 'package:llm_dart_core/llm_dart_core.dart';

import '../defaults.dart';
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
  final String? apiKey;

  @override
  final String baseUrl;

  @override
  final String model;

  @override
  final String? endpointPrefix;

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
    this.apiKey,
    required this.baseUrl,
    required this.model,
    this.endpointPrefix,
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
    String? defaultEndpointPrefix,
  }) {
    final fallbackProviderId = providerId == 'google-openai' ? 'google' : null;

    Map<String, dynamic> mergedProviderOptionMap(
      String key, {
      String? fallbackKey,
    }) {
      final direct = readProviderOptionMap(
        config.providerOptions,
        providerId,
        key,
      );
      final directAlt = fallbackKey == null
          ? null
          : readProviderOptionMap(
              config.providerOptions,
              providerId,
              fallbackKey,
            );

      final fallback = fallbackProviderId == null
          ? null
          : readProviderOptionMap(
              config.providerOptions,
              fallbackProviderId,
              key,
            );
      final fallbackAlt = (fallbackProviderId == null || fallbackKey == null)
          ? null
          : readProviderOptionMap(
              config.providerOptions,
              fallbackProviderId,
              fallbackKey,
            );

      final merged = <String, dynamic>{};
      merged.addAll(fallbackAlt ?? const {});
      merged.addAll(fallback ?? const {});
      merged.addAll(directAlt ?? const {});
      merged.addAll(direct ?? const {});
      return merged;
    }

    final rawGlobalHeaders = readProviderOptionMap(
          config.providerOptions,
          'openai-compatible',
          'headers',
        ) ??
        const <String, dynamic>{};
    final rawGlobalExtraHeaders = readProviderOptionMap(
          config.providerOptions,
          'openai-compatible',
          'extraHeaders',
        ) ??
        const <String, dynamic>{};
    final rawProviderHeaders = mergedProviderOptionMap('headers');
    final rawProviderExtraHeaders = mergedProviderOptionMap('extraHeaders');

    Map<String, String>? mergedHeaders;
    if (rawGlobalHeaders.isNotEmpty ||
        rawGlobalExtraHeaders.isNotEmpty ||
        rawProviderHeaders.isNotEmpty ||
        rawProviderExtraHeaders.isNotEmpty) {
      final result = <String, String>{};

      // Merge order:
      // - openai-compatible headers
      // - openai-compatible extraHeaders (override)
      // - provider-specific headers (override)
      // - provider-specific extraHeaders (override)
      for (final entry in rawGlobalHeaders.entries) {
        result[entry.key] = entry.value.toString();
      }
      for (final entry in rawGlobalExtraHeaders.entries) {
        result[entry.key] = entry.value.toString();
      }
      for (final entry in rawProviderHeaders.entries) {
        result[entry.key] = entry.value.toString();
      }
      for (final entry in rawProviderExtraHeaders.entries) {
        result[entry.key] = entry.value.toString();
      }
      mergedHeaders = result.isEmpty ? null : result;
    }

    final rawGlobalEndpointPrefix = readProviderOption<String>(
            config.providerOptions, 'openai-compatible', 'endpointPrefix') ??
        readProviderOption<String>(
            config.providerOptions, 'openai-compatible', 'pathPrefix') ??
        readProviderOption<String>(
            config.providerOptions, 'openai-compatible', 'endpoint_prefix');
    final rawProviderEndpointPrefix = readProviderOption<String>(
            config.providerOptions, providerId, 'endpointPrefix',
            fallbackProviderId: fallbackProviderId) ??
        readProviderOption<String>(
            config.providerOptions, providerId, 'pathPrefix',
            fallbackProviderId: fallbackProviderId) ??
        readProviderOption<String>(
            config.providerOptions, providerId, 'endpoint_prefix',
            fallbackProviderId: fallbackProviderId);

    final resolvedEndpointPrefix = (rawProviderEndpointPrefix ??
            rawGlobalEndpointPrefix ??
            defaultEndpointPrefix)
        ?.trim();

    final rawGlobalExtraBody = readProviderOptionMap(
          config.providerOptions,
          'openai-compatible',
          'extraBody',
        ) ??
        readProviderOptionMap(
          config.providerOptions,
          'openai-compatible',
          'extra_body',
        );

    final rawProviderExtraBody = mergedProviderOptionMap(
      'extraBody',
      fallbackKey: 'extra_body',
    );

    final Map<String, dynamic>? mergedExtraBody;
    if ((rawGlobalExtraBody != null && rawGlobalExtraBody.isNotEmpty) ||
        rawProviderExtraBody.isNotEmpty) {
      mergedExtraBody = {
        ...?rawGlobalExtraBody,
        ...rawProviderExtraBody,
      };
    } else {
      mergedExtraBody = null;
    }

    return OpenAICompatibleConfig(
      providerId: providerId,
      providerName: providerName ?? providerId,
      apiKey: config.apiKey,
      baseUrl: config.baseUrl,
      model:
          config.model.isEmpty ? openaiCompatibleFallbackModel : config.model,
      endpointPrefix:
          resolvedEndpointPrefix != null && resolvedEndpointPrefix.isNotEmpty
              ? resolvedEndpointPrefix
              : null,
      extraBody: mergedExtraBody,
      extraHeaders: mergedHeaders,
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
  T? getProviderOption<T>(String key) {
    final original = _originalConfig;
    if (original == null) return null;

    final fallbackProviderId = providerId == 'google-openai' ? 'google' : null;

    final direct = readProviderOption<T>(
      original.providerOptions,
      providerId,
      key,
      fallbackProviderId: fallbackProviderId,
    );
    if (direct != null) return direct;

    if (providerId != 'openai-compatible') {
      return readProviderOption<T>(
          original.providerOptions, 'openai-compatible', key);
    }

    return null;
  }
}
