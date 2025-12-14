import 'package:llm_dart_core/llm_dart_core.dart';

import '../config/groq_config.dart';
import '../provider/groq_provider.dart';

const _defaultBaseUrl = 'https://api.groq.com/openai/v1/';

/// Groq provider settings (Vercel AI-style).
///
/// Mirrors the core fields from a typical Vercel AI SDK provider:
/// - [apiKey] is required.
/// - [baseUrl] and [headers] allow proxying and custom HTTP config.
/// - [name] controls the logical provider id used in metadata and registries.
class GroqProviderSettings {
  /// API key used for authenticating requests.
  final String apiKey;

  /// Base URL for the Groq API.
  ///
  /// Defaults to `https://api.groq.com/openai/v1/` when not provided.
  final String? baseUrl;

  /// Additional custom headers to send with each request.
  final Map<String, String>? headers;

  /// Logical provider name used for metadata (e.g. `groq`).
  final String? name;

  /// Optional default timeout applied via [LLMConfig.timeout].
  final Duration? timeout;

  const GroqProviderSettings({
    required this.apiKey,
    this.baseUrl,
    this.headers,
    this.name,
    this.timeout,
  });
}

/// Groq model factory (Vercel AI-style).
///
/// Provides a model-centric API similar to `createGroq` in the Vercel
/// AI SDK. It returns [LanguageModel] instances that can be passed into
/// helpers like `generateTextWithModel` or used via the provider registry.
class Groq implements LanguageModelProviderFactory {
  final GroqProviderSettings _settings;
  final String _baseUrl;
  final String _providerName;

  Groq(GroqProviderSettings settings)
      : _settings = settings,
        _baseUrl = _normalizeBaseUrl(
          settings.baseUrl ?? _defaultBaseUrl,
        ),
        _providerName = settings.name ?? 'groq';

  /// Create a language model for text generation.
  ///
  /// Alias for [chat].
  @override
  LanguageModel languageModel(String modelId) => chat(modelId);

  /// Create a chat model for text generation.
  LanguageModel chat(String modelId) {
    final llmConfig = _createLLMConfig(modelId);
    final config = GroqConfig.fromLLMConfig(llmConfig);
    final provider = GroqProvider(config);

    return DefaultLanguageModel(
      providerId: _providerName,
      modelId: modelId,
      config: llmConfig,
      chat: provider,
    );
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

/// Create a Groq model factory (Vercel AI-style).
Groq createGroq({
  required String apiKey,
  String? baseUrl,
  Map<String, String>? headers,
  String? name,
  Duration? timeout,
}) {
  return Groq(
    GroqProviderSettings(
      apiKey: apiKey,
      baseUrl: baseUrl,
      headers: headers,
      name: name,
      timeout: timeout,
    ),
  );
}

/// Alias for [createGroq] to mirror a default `groq` export.
Groq groq({
  required String apiKey,
  String? baseUrl,
  Map<String, String>? headers,
  String? name,
  Duration? timeout,
}) {
  return createGroq(
    apiKey: apiKey,
    baseUrl: baseUrl,
    headers: headers,
    name: name,
    timeout: timeout,
  );
}
