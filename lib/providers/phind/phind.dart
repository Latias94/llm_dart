/// Modular Phind Provider
///
/// This library provides a modular implementation of the Phind provider
/// following the same architecture pattern as other providers.
///
/// **Key Features:**
/// - Specialized for coding and development tasks
/// - Phind-70B model with coding expertise
/// - Unique API format handling
/// - Modular architecture for easy maintenance
/// - Support for code generation and reasoning
///
/// **Usage:**
/// ```dart
/// import 'package:llm_dart/providers/phind/phind.dart';
///
/// final provider = PhindProvider(PhindConfig(
///   apiKey: 'your-api-key',
///   model: 'Phind-70B',
/// ));
///
/// // Use chat capability for coding questions
/// final response = await provider.chat([
///   ChatMessage.user('How do I implement a binary search in Dart?')
/// ]);
///
/// // Use streaming for real-time code generation
/// await for (final event in provider.chatStream([
///   ChatMessage.user('Write a Flutter widget for a todo list')
/// ])) {
///   if (event is TextDeltaEvent) {
///     print(event.text);
///   }
/// }
/// ```
library;

import 'package:llm_dart_core/llm_dart_core.dart';
import '../../utils/provider_registry.dart' show LanguageModelProviderFactory;
import 'config.dart';
import 'provider.dart';

// Core exports
export 'config.dart';
export 'client.dart';
export 'provider.dart';

// Capability modules
export 'chat.dart';

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
/// Provides a model-centric API similar to `createPhind` in a Vercel-style
/// SDK. It returns [LanguageModel] instances that can be passed into
/// helpers like [generateTextWithModel] or registered in a provider
/// registry.
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
///   model: model,
///   messages: [ChatMessage.user('Explain binary search in Dart')],
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

/// Create a Phind provider with default settings
PhindProvider createPhindProvider({
  required String apiKey,
  String model = 'Phind-70B',
  String baseUrl = 'https://api.phind.com/v1/',
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
}) {
  final config = PhindConfig(
    apiKey: apiKey,
    model: model,
    baseUrl: baseUrl,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
  );

  return PhindProvider(config);
}

/// Create a Phind provider optimized for code generation
PhindProvider createPhindCodeProvider({
  required String apiKey,
  String model = 'Phind-70B',
  double? temperature = 0.1, // Lower temperature for more deterministic code
  int? maxTokens = 4000,
  String? systemPrompt =
      'You are an expert programmer. Provide clear, well-commented code solutions.',
}) {
  final config = PhindConfig(
    apiKey: apiKey,
    model: model,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
  );

  return PhindProvider(config);
}

/// Create a Phind provider optimized for code explanation
PhindProvider createPhindExplainerProvider({
  required String apiKey,
  String model = 'Phind-70B',
  double? temperature = 0.3,
  int? maxTokens = 2000,
  String? systemPrompt =
      'You are a coding tutor. Explain code concepts clearly and provide examples.',
}) {
  final config = PhindConfig(
    apiKey: apiKey,
    model: model,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
  );

  return PhindProvider(config);
}
