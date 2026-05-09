/// Compatibility-first root Ollama provider entrypoint.
///
/// For new shared-capability code, prefer the package-owned modern Ollama
/// surfaces in `package:llm_dart_ollama/llm_dart_ollama.dart`:
///
/// - `Ollama(...).chatModel(...)`
/// - `Ollama(...).embeddingModel(...)`
///
/// Keep this root entrypoint only when you still need the legacy root provider
/// surface, compatibility capability interfaces, or residual provider-shaped
/// APIs such as `/api/generate` completion and model listing.
///
/// **Usage:**
/// ```dart
/// import 'package:llm_dart/providers/ollama/ollama.dart';
///
/// final provider = OllamaProvider(OllamaConfig(
///   baseUrl: 'http://localhost:11434',
///   model: 'llama3.2',
/// ));
///
/// // Use chat capability
/// final response = await provider.chat(messages);
///
/// // Use completion capability
/// final completion = await provider.complete(CompletionRequest(prompt: 'Hello'));
///
/// // Use embeddings capability
/// final embeddings = await provider.embed(['text to embed']);
///
/// // List available models
/// final models = await provider.models();
/// ```
library;

import '../../models/tool_models.dart';
import 'config.dart';
import 'defaults.dart';
import 'provider.dart';

// Core exports
export 'config.dart';
export 'defaults.dart';
export 'client.dart';
export 'provider.dart';

// Capability modules
export 'chat.dart';
export 'completion.dart';
export 'embeddings.dart';
export 'models.dart';

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
    baseUrl: baseUrl ?? OllamaDefaults.baseUrl,
    apiKey: apiKey,
    model: model ?? OllamaDefaults.defaultModel,
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
