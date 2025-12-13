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

export 'package:llm_dart_ollama/llm_dart_ollama.dart';
export 'admin.dart';
