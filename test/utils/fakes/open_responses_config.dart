import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/builtin_tools.dart';
import 'package:llm_dart_openai_compatible/openai_compatible_config.dart';
import 'package:llm_dart_openai_compatible/openai_responses_config.dart';

/// Minimal config adapter for "Open Responses"-style endpoints (e.g. LMStudio)
/// that stream OpenAI Responses API events.
///
/// This is primarily used for fixture-driven parity tests.
class OpenResponsesConfig extends OpenAICompatibleConfig
    implements OpenAIResponsesConfig {
  @override
  final String? previousResponseId;

  @override
  final List<OpenAIBuiltInTool>? builtInTools;

  const OpenResponsesConfig({
    required super.apiKey,
    required super.baseUrl,
    required super.model,
    this.previousResponseId,
    this.builtInTools,
    super.endpointPrefix,
    super.extraBody,
    super.extraHeaders,
    super.maxTokens,
    super.temperature,
    super.systemPrompt,
    super.timeout,
    super.topP,
    super.topK,
    super.tools,
    super.toolChoice,
    super.reasoningEffort,
    super.jsonSchema,
    super.voice,
    super.embeddingEncodingFormat,
    super.embeddingDimensions,
    super.stopSequences,
    super.user,
    super.serviceTier,
    super.originalConfig,
  }) : super(
          providerId: 'open_responses',
          providerName: 'Open Responses',
        );

  factory OpenResponsesConfig.fromLLMConfig(
    LLMConfig config, {
    String? providerName,
  }) {
    final base = OpenAICompatibleConfig.fromLLMConfig(
      config,
      providerId: 'open_responses',
      providerName: providerName ?? 'Open Responses',
    );

    return OpenResponsesConfig(
      apiKey: base.apiKey,
      baseUrl: base.baseUrl,
      model: base.model,
      endpointPrefix: base.endpointPrefix,
      extraBody: base.extraBody,
      extraHeaders: base.extraHeaders,
      maxTokens: base.maxTokens,
      temperature: base.temperature,
      systemPrompt: base.systemPrompt,
      timeout: base.timeout,
      topP: base.topP,
      topK: base.topK,
      tools: base.tools,
      toolChoice: base.toolChoice,
      reasoningEffort: base.reasoningEffort,
      jsonSchema: base.jsonSchema,
      voice: base.voice,
      embeddingEncodingFormat: base.embeddingEncodingFormat,
      embeddingDimensions: base.embeddingDimensions,
      stopSequences: base.stopSequences,
      user: base.user,
      serviceTier: base.serviceTier,
      originalConfig: config,
    );
  }
}
