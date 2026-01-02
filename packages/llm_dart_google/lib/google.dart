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
//
// Advanced, provider-native tools are opt-in:
// - `package:llm_dart_google/provider_tools.dart`
// - `package:llm_dart_google/web_search_tool_options.dart`

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
