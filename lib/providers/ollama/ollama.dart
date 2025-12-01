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
import '../../utils/provider_registry.dart'
    show LanguageModelProviderFactory, EmbeddingModelProviderFactory;

export 'package:llm_dart_ollama/llm_dart_ollama.dart';
export 'admin.dart';

const _defaultBaseUrl = 'http://localhost:11434/';

/// Ollama provider settings (Vercel AI-style).
///
/// 为 Ollama 提供一个轻量的 model factory 配置对象，方便在
/// `createProviderRegistry` 中注册并按 `"ollama:model"` 的形式使用。
class OllamaProviderSettings {
  /// 可选 API key，一般用于自定义代理或鉴权场景。
  final String? apiKey;

  /// Ollama HTTP 服务地址，默认指向本机。
  final String? baseUrl;

  /// 统一的请求超时时间，对应 [LLMConfig.timeout]。
  final Duration? timeout;

  /// 自定义 HTTP 头，通过 [LLMConfig.extensions] 传递给底层实现。
  final Map<String, String>? headers;

  /// 逻辑 provider 名称，用于 [LanguageModel.providerId] 等元数据。
  final String? name;

  const OllamaProviderSettings({
    this.apiKey,
    this.baseUrl,
    this.timeout,
    this.headers,
    this.name,
  });
}

/// Ollama model factory（Vercel AI 风格）。
///
/// 提供与 `OpenAI`/`GoogleGenerativeAI`/`DeepSeek` 一致的 model-first API，
/// 并实现 `LanguageModelProviderFactory` 与 `EmbeddingModelProviderFactory`，
/// 便于与 [createProviderRegistry] 集成。
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

  /// 语言模型入口，兼容 Registry 的 `languageModel("ollama:llama3.2")` 用法。
  ///
  /// 内部直接构造一个 [OllamaProvider] 并由 [DefaultLanguageModel] 包装为
  /// 抽象的 [LanguageModel]。
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

  /// 嵌入模型入口，兼容 Registry 的
  /// `textEmbeddingModel("ollama:nomic-embed-text")` 用法。
  ///
  /// 由于 [OllamaProvider] 本身实现了 [EmbeddingCapability]，这里直接
  /// 返回 provider 实例。
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

/// 创建一个 Ollama model factory（Vercel AI 风格）。
///
/// 示例：
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
