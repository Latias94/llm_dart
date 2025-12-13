import 'package:llm_dart_core/llm_dart_core.dart';

import '../config/phind_config.dart';
import '../provider/phind_provider.dart';

const _defaultBaseUrl = 'https://api.phind.com/v1/';

/// Phind provider settings (Vercel AI-style).
///
/// Mirrors a typical Vercel AI SDK provider settings object for Phind:
/// - [apiKey] is required.
/// - [baseUrl] and [headers] allow proxying and custom HTTP configuration.
/// - [name] controls the logical provider id used in metadata and registries.
class PhindProviderSettings {
  /// API key used for authenticating requests.
  final String apiKey;

  /// Base URL for the Phind API.
  ///
  /// Defaults to `https://api.phind.com/v1/` when not provided.
  final String? baseUrl;

  /// Additional custom headers to send with each request.
  final Map<String, String>? headers;

  /// Logical provider name used for metadata (e.g. `phind`).
  final String? name;

  /// Optional default timeout applied via [LLMConfig.timeout].
  final Duration? timeout;

  const PhindProviderSettings({
    required this.apiKey,
    this.baseUrl,
    this.headers,
    this.name,
    this.timeout,
  });
}

/// Phind model factory (Vercel AI-style).
///
/// Provides a model-centric API similar to `createPhind` in a Vercel-style SDK.
/// It returns [LanguageModel] instances that can be passed into helpers like
/// [generateTextWithModel] or registered in a provider registry.
class Phind implements LanguageModelProviderFactory {
  final PhindProviderSettings _settings;
  final String _baseUrl;
  final String _providerName;

  Phind(PhindProviderSettings settings)
      : _settings = settings,
        _baseUrl = _normalizeBaseUrl(
          settings.baseUrl ?? _defaultBaseUrl,
        ),
        _providerName = settings.name ?? 'phind';

  /// Create a language model for text generation.
  ///
  /// Alias for [chat].
  @override
  LanguageModel languageModel(String modelId) => chat(modelId);

  /// Create a chat model for text/coding assistance.
  LanguageModel chat(String modelId) {
    final llmConfig = _createLLMConfig(modelId);
    final config = PhindConfig.fromLLMConfig(llmConfig);
    final provider = PhindProvider(config);

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

/// Create a Phind model factory (Vercel AI-style).
///
/// Example:
/// ```dart
/// final phind = createPhind(
///   apiKey: 'phind-...',
/// );
///
/// final model = phind.chat('Phind-70B');
/// final result = await generateTextWithModel(
///   model,
///   promptMessages: [ModelMessage.userText('Explain binary search in Dart')],
/// );
/// ```
Phind createPhind({
  required String apiKey,
  String? baseUrl,
  Map<String, String>? headers,
  String? name,
  Duration? timeout,
}) {
  return Phind(
    PhindProviderSettings(
      apiKey: apiKey,
      baseUrl: baseUrl,
      headers: headers,
      name: name,
      timeout: timeout,
    ),
  );
}

/// Alias for [createPhind] to mirror a default `phind` export.
Phind phind({
  required String apiKey,
  String? baseUrl,
  Map<String, String>? headers,
  String? name,
  Duration? timeout,
}) {
  return createPhind(
    apiKey: apiKey,
    baseUrl: baseUrl,
    headers: headers,
    name: name,
    timeout: timeout,
  );
}

