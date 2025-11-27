/// Modular Groq Provider
///
/// This library provides a modular implementation of the Groq provider
///
/// **Key Benefits:**
/// - Single Responsibility: Each module handles one capability
/// - Easier Testing: Modules can be tested independently
/// - Better Maintainability: Changes isolated to specific modules
/// - Cleaner Code: Smaller, focused classes
/// - Reusability: Modules can be reused across providers
/// - Speed Optimized: Groq is known for fast inference
///
/// **Usage:**
/// ```dart
/// import 'package:llm_dart/providers/groq/groq.dart';
///
/// final provider = GroqProvider(GroqConfig(
///   apiKey: 'your-api-key',
///   model: 'llama-3.3-70b-versatile',
/// ));
///
/// // Use chat capability
/// final response = await provider.chat(messages);
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
/// helpers like [generateTextWithModel] or used via the provider registry.
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
///
/// Example:
/// ```dart
/// final groq = createGroq(
///   apiKey: 'gsk-...',
/// );
///
/// final model = groq.chat('llama-3.3-70b-versatile');
/// final result = await generateTextWithModel(
///   model: model,
///   messages: [ChatMessage.user('Hello')],
/// );
/// ```
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

/// Create a Groq provider with default configuration
GroqProvider createGroqProvider({
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
  List<Tool>? tools,
  ToolChoice? toolChoice,
}) {
  final config = GroqConfig(
    apiKey: apiKey,
    model: model ?? 'llama-3.3-70b-versatile',
    baseUrl: baseUrl ?? 'https://api.groq.com/openai/v1/',
    maxTokens: maxTokens,
    temperature: temperature,
    systemPrompt: systemPrompt,
    timeout: timeout,
    topP: topP,
    topK: topK,
    tools: tools,
    toolChoice: toolChoice,
  );

  return GroqProvider(config);
}

/// Create a Groq provider for chat
GroqProvider createGroqChatProvider({
  required String apiKey,
  String model = 'llama-3.3-70b-versatile',
  String? systemPrompt,
  double? temperature,
  int? maxTokens,
}) {
  return createGroqProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    temperature: temperature,
    maxTokens: maxTokens,
  );
}

/// Create a Groq provider for fast inference
GroqProvider createGroqFastProvider({
  required String apiKey,
  String model = 'llama-3.1-8b-instant',
  String? systemPrompt,
  double? temperature,
  int? maxTokens,
}) {
  return createGroqProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    temperature: temperature,
    maxTokens: maxTokens,
  );
}

/// Create a Groq provider for vision tasks
GroqProvider createGroqVisionProvider({
  required String apiKey,
  String model = 'llava-v1.5-7b-4096-preview',
  String? systemPrompt,
  double? temperature,
  int? maxTokens,
}) {
  return createGroqProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    temperature: temperature,
    maxTokens: maxTokens,
  );
}

/// Create a Groq provider for code generation
GroqProvider createGroqCodeProvider({
  required String apiKey,
  String model = 'llama-3.1-70b-versatile',
  String? systemPrompt,
  double? temperature,
  int? maxTokens,
}) {
  return createGroqProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    temperature: temperature ?? 0.1, // Lower temperature for code
    maxTokens: maxTokens,
  );
}
