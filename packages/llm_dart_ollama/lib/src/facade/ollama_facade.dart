import 'package:llm_dart_core/llm_dart_core.dart';

import '../config/ollama_config.dart';
import '../provider/ollama_provider.dart';

const _defaultBaseUrl = 'http://localhost:11434/';

/// Ollama provider settings (Vercel AI-style).
///
/// Provides a lightweight configuration object for the Ollama model factory so
/// it can be registered with `createProviderRegistry` and used via
/// `"ollama:model"` identifiers.
class OllamaProviderSettings {
  /// Optional API key, typically used for custom proxy or auth setups.
  final String? apiKey;

  /// Ollama HTTP service URL, defaults to a local instance.
  final String? baseUrl;

  /// Unified request timeout, mapped to [LLMConfig.timeout].
  final Duration? timeout;

  /// Custom HTTP headers, passed to the underlying implementation via
  /// [LLMConfig.extensions].
  final Map<String, String>? headers;

  /// Logical provider name, used for [LanguageModel.providerId] and other
  /// metadata.
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
/// Provides a model-first API consistent with `OpenAI` / `GoogleGenerativeAI` /
/// `DeepSeek` and implements [LanguageModelProviderFactory] and
/// [EmbeddingModelProviderFactory] for easy integration with
/// [createProviderRegistry].
class Ollama implements LanguageModelProviderFactory, EmbeddingModelProviderFactory {
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
  /// Since [OllamaProvider] implements [EmbeddingCapability] directly, this
  /// simply returns the provider instance.
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
///   promptMessages: [ModelMessage.userText('Hello from Ollama')],
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

