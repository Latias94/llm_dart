/// Google Vertex provider (express mode).
///
/// This package reuses the Google Generative AI request/response mapping from
/// `llm_dart_google`, but exposes provider metadata under the `vertex`
/// namespace for Vercel AI SDK parity.
///
/// Note: for AI SDK v6 parity, the canonical providerOptions/providerMetadata key
/// is now `vertex` (with `google-vertex` kept as a deprecated alias).
library;

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/google.dart';

import 'defaults.dart';
import 'google_vertex_factory.dart';

GoogleProvider createGoogleVertexProvider({
  required String apiKey,
  String? model,
  String? baseUrl,
  int? maxTokens,
  double? temperature,
  String? systemPrompt,
  Duration? timeout,
  bool? stream,
  double? topP,
  int? topK,
  ReasoningEffort? reasoningEffort,
  int? thinkingBudgetTokens,
  bool? includeThoughts,
  bool? enableImageGeneration,
  List<String>? responseModalities,
  List<SafetySetting>? safetySettings,
  int? maxInlineDataSize,
  int? candidateCount,
  List<String>? stopSequences,
  String? embeddingTaskType,
  String? embeddingTitle,
  int? embeddingDimensions,
}) {
  final config = GoogleConfig(
    providerOptionsName: vertexProviderId,
    providerId: vertexProviderId,
    providerOptionsFallbackIds: const ['google-vertex', 'google'],
    apiKey: apiKey,
    model: model ?? googleVertexDefaultModel,
    baseUrl: baseUrl ?? googleVertexBaseUrl,
    maxTokens: maxTokens,
    temperature: temperature,
    systemPrompt: systemPrompt,
    timeout: timeout,
    stream: stream ?? false,
    topP: topP,
    topK: topK,
    reasoningEffort: reasoningEffort,
    thinkingBudgetTokens: thinkingBudgetTokens,
    includeThoughts: includeThoughts,
    enableImageGeneration: enableImageGeneration,
    responseModalities: responseModalities,
    safetySettings: safetySettings,
    maxInlineDataSize: maxInlineDataSize ?? 20 * 1024 * 1024,
    candidateCount: candidateCount,
    stopSequences: stopSequences,
    embeddingTaskType: embeddingTaskType,
    embeddingTitle: embeddingTitle,
    embeddingDimensions: embeddingDimensions,
  );

  return GoogleProvider(config);
}
