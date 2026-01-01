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
/// import 'package:llm_dart_google/llm_dart_google.dart';
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

import 'package:llm_dart_core/llm_dart_core.dart';
import 'config.dart';
import 'provider.dart';

// Core exports
export 'config.dart';
export 'provider.dart';

// Capability modules
export 'chat.dart';
export 'embeddings.dart';
export 'images.dart';
export 'tts.dart';
export 'provider_tools.dart';
export 'web_search_tool_options.dart';

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
    model: model ?? 'gemini-1.5-flash',
    baseUrl: baseUrl ?? 'https://generativelanguage.googleapis.com/v1beta/',
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

/// Create a Google provider for chat
GoogleProvider createGoogleChatProvider({
  required String apiKey,
  String model = 'gemini-1.5-flash',
  String? systemPrompt,
  double? temperature,
  int? maxTokens,
}) {
  return createGoogleProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    temperature: temperature,
    maxTokens: maxTokens,
  );
}

/// Create a Google provider for reasoning tasks
GoogleProvider createGoogleReasoningProvider({
  required String apiKey,
  String model = 'gemini-2.0-flash-thinking-exp',
  String? systemPrompt,
  int? thinkingBudgetTokens,
  bool includeThoughts = true,
}) {
  return createGoogleProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    thinkingBudgetTokens: thinkingBudgetTokens,
    includeThoughts: includeThoughts,
  );
}

/// Create a Google provider for vision tasks
GoogleProvider createGoogleVisionProvider({
  required String apiKey,
  String model = 'gemini-1.5-pro',
  String? systemPrompt,
  double? temperature,
  int? maxTokens,
}) {
  return createGoogleProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    temperature: temperature,
    maxTokens: maxTokens,
  );
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
