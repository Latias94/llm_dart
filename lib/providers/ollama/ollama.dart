// The Ollama provider facade continues to support ChatMessage-based
// chat/completion examples for existing code. Prompt-first patterns
// using ModelMessage are recommended for new integrations.
// ignore_for_file: deprecated_member_use

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

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_ollama/llm_dart_ollama.dart';

export 'package:llm_dart_ollama/llm_dart_ollama.dart';
export 'admin.dart';

const _defaultBaseUrl = 'http://localhost:11434/';

/// Ollama provider settings (Vercel AI-style).
///
/// Provides a lightweight configuration object for the Ollama model
/// factory so it can be registered with `createProviderRegistry`
/// and used via `"ollama:model"` identifiers.
class OllamaProviderSettings {
  /// Optional API key, typically used for custom proxy or auth setups.
  final String? apiKey;

  /// Ollama HTTP service URL, defaults to a local instance.
  final String? baseUrl;

  /// Unified request timeout, mapped to [LLMConfig.timeout].
  final Duration? timeout;

  /// Custom HTTP headers, passed to the underlying implementation
  /// via [LLMConfig.extensions].
  final Map<String, String>? headers;

  /// Logical provider name, used for [LanguageModel.providerId] and
  /// other metadata.
  final String? name;

  const OllamaProviderSettings({
    this.apiKey,
    this.baseUrl,
    this.timeout,
    this.headers,
    this.name,
  });
}

/// Ollama model factory (Vercel AI-style).
///
/// Provides a model-first API consistent with `OpenAI` /
/// `GoogleGenerativeAI` / `DeepSeek` and implements
/// [LanguageModelProviderFactory] and [EmbeddingModelProviderFactory]
/// for easy integration with [createProviderRegistry].
class Ollama
    implements LanguageModelProviderFactory, EmbeddingModelProviderFactory {
  final OllamaProviderSettings _settings;
  final String _baseUrl;
  final String _providerName;

  Ollama(OllamaProviderSettings settings)
      : _settings = settings,
        _baseUrl = _normalizeBaseUrl(
          settings.baseUrl ?? _defaultBaseUrl,
        ),
        _providerName = settings.name ?? 'ollama';

  /// Language model entry point, compatible with the registry call
  /// `languageModel("ollama:llama3.2")`.
  ///
  /// Internally constructs an [OllamaProvider] and wraps it in
  /// [DefaultLanguageModel] as an abstract [LanguageModel].
  @override
  LanguageModel languageModel(String modelId) {
    final llmConfig = _createLLMConfig(modelId);
    final config = OllamaConfig.fromLLMConfig(llmConfig);
    final provider = OllamaProvider(config);

    return DefaultLanguageModel(
      providerId: _providerName,
      modelId: modelId,
      config: llmConfig,
      chat: provider,
    );
  }

  /// Embedding model entry point, compatible with the registry call
  /// `textEmbeddingModel("ollama:nomic-embed-text")`.
  ///
  /// Since [OllamaProvider] implements [EmbeddingCapability] directly,
  /// this simply returns the provider instance.
  @override
  EmbeddingCapability textEmbeddingModel(String modelId) {
    final llmConfig = _createLLMConfig(modelId);
    final config = OllamaConfig.fromLLMConfig(llmConfig);
    final provider = OllamaProvider(config);
    return provider;
  }

  LLMConfig _createLLMConfig(String modelId) {
    final headers = <String, String>{};

    if (_settings.headers != null && _settings.headers!.isNotEmpty) {
      headers.addAll(_settings.headers!);
    }

    final extensions = <String, dynamic>{};
    if (headers.isNotEmpty) {
      extensions[LLMConfigKeys.customHeaders] = headers;
    }

    return LLMConfig(
      apiKey: _settings.apiKey,
      baseUrl: _baseUrl,
      model: modelId,
      timeout: _settings.timeout,
      extensions: extensions,
    );
  }

  static String _normalizeBaseUrl(String value) {
    if (value.isEmpty) return _defaultBaseUrl;
    return value.endsWith('/') ? value : '$value/';
  }
}

/// Create an Ollama model factory (Vercel AI-style).
///
/// Example:
/// ```dart
/// final ollama = createOllama(
///   baseUrl: 'http://localhost:11434',
/// );
///
/// final model = ollama.languageModel('llama3.2');
/// final result = await generateTextWithModel(
///   model,
///   messages: [ModelMessage.userText('Hello from Ollama')],
/// );
/// ```
Ollama createOllama({
  String? baseUrl,
  String? apiKey,
  Duration? timeout,
  Map<String, String>? headers,
  String? name,
}) {
  return Ollama(
    OllamaProviderSettings(
      apiKey: apiKey,
      baseUrl: baseUrl,
      timeout: timeout,
      headers: headers,
      name: name,
    ),
  );
}

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
