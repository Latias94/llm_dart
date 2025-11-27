/// DeepSeek Provider facade for the main `llm_dart` package.
///
/// This library now re-exports the DeepSeek provider implementation
/// from the `llm_dart_deepseek` subpackage, while keeping the original
/// import path stable for backwards compatibility.
library;

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_deepseek/llm_dart_deepseek.dart' as deepseek_impl;

import '../../core/provider_defaults.dart';

export 'package:llm_dart_deepseek/llm_dart_deepseek.dart'
    show DeepSeekConfig, DeepSeekProvider;

@Deprecated(
  'Use DeepSeekConfig from package:llm_dart_deepseek/llm_dart_deepseek.dart '
  'instead. This alias exists only for backwards compatibility and will be '
  'removed in a future release.',
)
// Backwards-compatible alias for the DeepSeek configuration type.
typedef DeepSeekConfig = deepseek_impl.DeepSeekConfig;

@Deprecated(
  'Use DeepSeekProvider from package:llm_dart_deepseek/llm_dart_deepseek.dart '
  'instead. This alias exists only for backwards compatibility and will be '
  'removed in a future release.',
)
// Backwards-compatible alias for the DeepSeek provider type.
typedef DeepSeekProvider = deepseek_impl.DeepSeekProvider;

/// DeepSeek provider settings (Vercel AI-style).
///
/// Mirrors the core fields from `DeepSeekProviderSettings` in the
/// Vercel AI SDK while using Dart naming conventions.
class DeepSeekProviderSettings {
  /// API key for authenticating requests.
  final String apiKey;

  /// Base URL for the DeepSeek API.
  ///
  /// Defaults to `https://api.deepseek.com/v1/`.
  final String? baseUrl;

  /// Additional custom headers to send with each request.
  final Map<String, String>? headers;

  /// Logical provider name used for metadata (e.g. `deepseek.chat`).
  final String? name;

  /// Optional default timeout applied via [LLMConfig.timeout].
  final Duration? timeout;

  const DeepSeekProviderSettings({
    required this.apiKey,
    this.baseUrl,
    this.headers,
    this.name,
    this.timeout,
  });
}

/// DeepSeek model factory (Vercel AI-style).
///
/// Provides a model-centric API similar to `createDeepSeek` in the
/// Vercel AI SDK. It returns [LanguageModel] instances that can be
/// passed into helpers like [generateTextWithModel] or [runAgentText].
class DeepSeek {
  final DeepSeekProviderSettings _settings;
  final String _baseUrl;
  final String _providerName;

  DeepSeek(DeepSeekProviderSettings settings)
      : _settings = settings,
        _baseUrl = _normalizeBaseUrl(
          settings.baseUrl ?? ProviderDefaults.deepseekBaseUrl,
        ),
        _providerName = settings.name ?? 'deepseek';

  /// Create a language model for text generation.
  ///
  /// Alias for [chat].
  LanguageModel languageModel(String modelId) => chat(modelId);

  /// Create a chat model for text generation.
  LanguageModel chat(String modelId) {
    final llmConfig = _createLLMConfig(modelId);
    final config = deepseek_impl.DeepSeekConfig.fromLLMConfig(llmConfig);
    final client = deepseek_impl.DeepSeekClient(config);
    final chat = deepseek_impl.DeepSeekChat(client, config);

    return DefaultLanguageModel(
      providerId: _providerName,
      modelId: modelId,
      config: llmConfig,
      chat: chat,
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
    if (value.isEmpty) return ProviderDefaults.deepseekBaseUrl;
    return value.endsWith('/') ? value : '$value/';
  }
}

/// Create a DeepSeek model factory (Vercel AI-style).
///
/// Example:
/// ```dart
/// final deepseek = createDeepSeek(
///   apiKey: 'sk-deepseek-...',
/// );
///
/// final model = deepseek.chat('deepseek-chat');
/// final result = await generateTextWithModel(
///   model: model,
///   messages: [ChatMessage.user('Hello')],
/// );
/// ```
DeepSeek createDeepSeek({
  required String apiKey,
  String? baseUrl,
  Map<String, String>? headers,
  String? name,
  Duration? timeout,
}) {
  return DeepSeek(
    DeepSeekProviderSettings(
      apiKey: apiKey,
      baseUrl: baseUrl,
      headers: headers,
      name: name,
      timeout: timeout,
    ),
  );
}

/// Alias for [createDeepSeek] to mirror the default `deepseek` export
/// from the Vercel AI SDK.
DeepSeek deepseek({
  required String apiKey,
  String? baseUrl,
  Map<String, String>? headers,
  String? name,
  Duration? timeout,
}) {
  return createDeepSeek(
    apiKey: apiKey,
    baseUrl: baseUrl,
    headers: headers,
    name: name,
    timeout: timeout,
  );
}

/// Create a DeepSeek provider with default configuration
deepseek_impl.DeepSeekProvider createDeepSeekProvider({
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
}) {
  final config = deepseek_impl.DeepSeekConfig(
    apiKey: apiKey,
    model: model ?? 'deepseek-chat',
    baseUrl: baseUrl ?? 'https://api.deepseek.com/v1/',
    maxTokens: maxTokens,
    temperature: temperature,
    systemPrompt: systemPrompt,
    timeout: timeout,
    topP: topP,
    topK: topK,
  );

  return deepseek_impl.DeepSeekProvider(config);
}

/// Create a DeepSeek provider for chat
deepseek_impl.DeepSeekProvider createDeepSeekChatProvider({
  required String apiKey,
  String model = 'deepseek-chat',
  String? systemPrompt,
  double? temperature,
  int? maxTokens,
}) {
  return createDeepSeekProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    temperature: temperature,
    maxTokens: maxTokens,
  );
}

/// Create a DeepSeek provider for reasoning tasks
/// Uses the deepseek-reasoner model which supports reasoning/thinking
deepseek_impl.DeepSeekProvider createDeepSeekReasoningProvider({
  required String apiKey,
  String model = 'deepseek-reasoner',
  String? systemPrompt,
  double? temperature,
  int? maxTokens,
}) {
  return createDeepSeekProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    temperature: temperature,
    maxTokens: maxTokens,
  );
}
