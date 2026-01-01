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

import 'package:llm_dart_core/llm_dart_core.dart';
import 'config.dart';
import 'provider.dart';

// Core exports
export 'config.dart';
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

/// Create an Ollama provider for chat
OllamaProvider createOllamaChatProvider({
  String baseUrl = 'http://localhost:11434',
  String model = 'llama3.2',
  String? systemPrompt,
  double? temperature,
  int? maxTokens,
}) {
  return createOllamaProvider(
    baseUrl: baseUrl,
    model: model,
    systemPrompt: systemPrompt,
    temperature: temperature,
    maxTokens: maxTokens,
  );
}

/// Create an Ollama provider for vision tasks
OllamaProvider createOllamaVisionProvider({
  String baseUrl = 'http://localhost:11434',
  String model = 'llava',
  String? systemPrompt,
  double? temperature,
  int? maxTokens,
}) {
  return createOllamaProvider(
    baseUrl: baseUrl,
    model: model,
    systemPrompt: systemPrompt,
    temperature: temperature,
    maxTokens: maxTokens,
  );
}

/// Create an Ollama provider for code generation
OllamaProvider createOllamaCodeProvider({
  String baseUrl = 'http://localhost:11434',
  String model = 'codellama',
  String? systemPrompt,
  double? temperature,
  int? maxTokens,
}) {
  return createOllamaProvider(
    baseUrl: baseUrl,
    model: model,
    systemPrompt: systemPrompt,
    temperature: temperature ?? 0.1, // Lower temperature for code
    maxTokens: maxTokens,
  );
}

/// Create an Ollama provider for embeddings
OllamaProvider createOllamaEmbeddingProvider({
  String baseUrl = 'http://localhost:11434',
  String model = 'nomic-embed-text',
}) {
  return createOllamaProvider(
    baseUrl: baseUrl,
    model: model,
  );
}

/// Create an Ollama provider for completion tasks
OllamaProvider createOllamaCompletionProvider({
  String baseUrl = 'http://localhost:11434',
  String model = 'llama3.2',
  double? temperature,
  int? maxTokens,
}) {
  return createOllamaProvider(
    baseUrl: baseUrl,
    model: model,
    temperature: temperature,
    maxTokens: maxTokens,
  );
}

/// Create an Ollama provider for reasoning tasks
OllamaProvider createOllamaReasoningProvider({
  String baseUrl = 'http://localhost:11434',
  String model = 'gpt-oss:latest',
  String? systemPrompt,
  bool reasoning = true,
}) {
  return createOllamaProvider(
    baseUrl: baseUrl,
    model: model,
    systemPrompt: systemPrompt,
    reasoning: reasoning,
  );
}
