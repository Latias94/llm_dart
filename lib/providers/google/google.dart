/// Modular Google Provider
///
/// This library provides a modular implementation of the Google provider
///
/// **Key Benefits:**
/// - Single Responsibility: Each module handles one capability
/// - Easier Testing: Modules can be tested independently
/// - Better Maintainability: Changes isolated to specific modules
/// - Cleaner Code: Smaller, focused classes
/// - Reusability: Modules can be reused across providers
///
/// **Usage:**
/// ```dart
/// import 'package:llm_dart/providers/google/google.dart';
///
/// final provider = GoogleProvider(GoogleConfig(
///   apiKey: 'your-api-key',
///   model: 'gemini-1.5-flash',
/// ));
///
/// // Use chat capability
/// final response = await provider.chat(messages);
/// ```
library;

import '../../core/web_search.dart';
import '../../models/chat_models.dart';
import 'config.dart';
import 'defaults.dart';
import 'provider.dart';

// Core exports
export 'config.dart';
export 'defaults.dart';
export 'provider.dart';
export 'builder.dart';

/// Create a Google provider with default configuration
GoogleProvider createGoogleProvider({
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
  WebSearchConfig? webSearchConfig,
  List<SafetySetting>? safetySettings,
  int? maxInlineDataSize,
  int? candidateCount,
  List<String>? stopSequences,
  String? embeddingTaskType,
  String? embeddingTitle,
  int? embeddingDimensions,
}) {
  final config = GoogleConfig(
    apiKey: apiKey,
    model: model ?? GoogleDefaults.defaultModel,
    baseUrl: baseUrl ?? GoogleDefaults.baseUrl,
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
    webSearchConfig: webSearchConfig,
    safetySettings: safetySettings,
    maxInlineDataSize: maxInlineDataSize ?? GoogleDefaults.maxInlineDataSize,
    candidateCount: candidateCount,
    stopSequences: stopSequences,
    embeddingTaskType: embeddingTaskType,
    embeddingTitle: embeddingTitle,
    embeddingDimensions: embeddingDimensions,
  );

  return GoogleProvider(config);
}

/// Create a Google provider for image generation
GoogleProvider createGoogleImageGenerationProvider({
  required String apiKey,
  String model = 'gemini-1.5-pro',
  List<String>? responseModalities,
}) {
  return createGoogleProvider(
    apiKey: apiKey,
    model: model,
    enableImageGeneration: true,
    responseModalities: responseModalities ?? ['TEXT', 'IMAGE'],
  );
}

/// Create a Google provider for embeddings
GoogleProvider createGoogleEmbeddingProvider({
  required String apiKey,
  String model = 'text-embedding-004',
  String? embeddingTaskType,
  String? embeddingTitle,
  int? embeddingDimensions,
}) {
  return createGoogleProvider(
    apiKey: apiKey,
    model: model,
    embeddingTaskType: embeddingTaskType,
    embeddingTitle: embeddingTitle,
    embeddingDimensions: embeddingDimensions,
  );
}
