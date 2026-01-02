/// Modular Ollama Provider
///
/// This library provides a modular implementation of the Ollama provider
///
/// **Key Benefits:**
/// - Single Responsibility: Each module handles one capability
/// - Easier Testing: Modules can be tested independently
/// - Better Maintainability: Changes isolated to specific modules
/// - Cleaner Code: Smaller, focused classes
/// - Reusability: Modules can be reused across providers
/// - Local Deployment: Designed for local Ollama instances
///
/// **Usage:**
/// ```dart
/// import 'package:llm_dart_ollama/ollama.dart';
///
/// final provider = OllamaProvider(OllamaConfig(
///   baseUrl: 'http://localhost:11434',
///   model: 'llama3.2',
/// ));
///
/// // Use chat capability
/// final response = await provider.chat(messages);
///
/// // Use embeddings capability
/// final embeddings = await provider.embed(['text to embed']);
///
/// // Opt-in endpoint wrappers (Tier 3):
/// // - `package:llm_dart_ollama/completion.dart`
/// // - `package:llm_dart_ollama/models.dart`
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
//
// Advanced endpoint wrappers are opt-in:
// - `package:llm_dart_ollama/completion.dart`
// - `package:llm_dart_ollama/models.dart`

/// Create an Ollama provider with default configuration
OllamaProvider createOllamaProvider({
  String? baseUrl,
  String? apiKey,
  String? model,
  int? maxTokens,
  double? temperature,
  String? systemPrompt,
  Duration? timeout,
  double? topP,
  int? topK,
  List<Tool>? tools,
  StructuredOutputFormat? jsonSchema,
  // Ollama-specific parameters
  int? numCtx,
  int? numGpu,
  int? numThread,
  bool? numa,
  int? numBatch,
  String? keepAlive,
  bool? raw,
  bool? reasoning,
}) {
  final config = OllamaConfig(
    baseUrl: baseUrl ?? 'http://localhost:11434',
    apiKey: apiKey,
    model: model ?? 'llama3.2',
    maxTokens: maxTokens,
    temperature: temperature,
    systemPrompt: systemPrompt,
    timeout: timeout,
    topP: topP,
    topK: topK,
    tools: tools,
    jsonSchema: jsonSchema,
    numCtx: numCtx,
    numGpu: numGpu,
    numThread: numThread,
    numa: numa,
    numBatch: numBatch,
    keepAlive: keepAlive,
    raw: raw,
    reasoning: reasoning,
  );

  return OllamaProvider(config);
}
