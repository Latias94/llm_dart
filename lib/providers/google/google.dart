/// Modular Google Provider
///
/// This library provides a modular implementation of the Google provider
///
/// **Key Benefits:**
/// - Single Responsibility: Each module handles one capability
/// - Easier Testing: Modules can be tested independently
/// - Better Maintainability: Changes isolated to specific modules
/// - Cleaner Code: Smaller, focused classes
/// - Reusability: Modules can be reused across providers
///
/// **Usage:**
/// ```dart
/// import 'package:llm_dart/providers/google/google.dart';
///
/// final provider = GoogleProvider(GoogleConfig(
///   apiKey: 'your-api-key',
///   model: 'gemini-1.5-flash',
/// ));
///
/// // Use chat capability
/// final response = await provider.chat(messages);
/// ```
library;

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/llm_dart_google.dart'
    show
        GoogleConfig,
        GoogleClient,
        GoogleProvider,
        GoogleChat,
        GoogleEmbeddings,
        GoogleImages,
        SafetySetting;

import '../../core/provider_defaults.dart';

/// Public Google provider surface re-export.
///
/// This mirrors the primary Google provider types while keeping internal
/// implementation details (like HTTP strategies) in the sub-package.
export 'package:llm_dart_google/llm_dart_google.dart'
    show
        // Core config / client / provider
        GoogleConfig,
        GoogleClient,
        GoogleProvider,

        // Chat / embeddings / images
        GoogleChat,
        GoogleChatResponse,
        GoogleEmbeddings,
        GoogleImages,

        // Safety & harm configuration
        SafetySetting,
        HarmCategory,
        HarmBlockThreshold,

        // Files API
        GoogleFilesClient,
        GoogleFile;

// Builder APIs for configuring Google via LLMBuilder.
export 'builder.dart';

/// Google Generative AI provider settings (Vercel AI-style).
///
/// Mirrors the core fields from `GoogleGenerativeAIProviderSettings` in the
/// Vercel AI SDK while using Dart naming conventions.
class GoogleGenerativeAIProviderSettings {
  /// API key for authenticating requests.
  final String apiKey;

  /// Base URL for the Google Generative AI API.
  ///
  /// Defaults to `https://generativelanguage.googleapis.com/v1beta/`.
  final String? baseUrl;

  /// Additional custom headers to send with each request.
  final Map<String, String>? headers;

  /// Logical provider name used for metadata (e.g. `google.generative-ai`).
  final String? name;

  /// Optional default timeout applied via [LLMConfig.timeout].
  final Duration? timeout;

  const GoogleGenerativeAIProviderSettings({
    required this.apiKey,
    this.baseUrl,
    this.headers,
    this.name,
    this.timeout,
  });
}

/// Google Generative AI model factory (Vercel AI-style).
///
/// Provides a model-centric API similar to `createGoogleGenerativeAI` in
/// the Vercel AI SDK. It returns [LanguageModel] instances and capability
/// interfaces that can be used with high-level helpers.
class GoogleGenerativeAI {
  final GoogleGenerativeAIProviderSettings _settings;
  final String _baseUrl;
  final String _providerName;

  GoogleGenerativeAI(GoogleGenerativeAIProviderSettings settings)
      : _settings = settings,
        _baseUrl = _normalizeBaseUrl(
          settings.baseUrl ?? ProviderDefaults.googleBaseUrl,
        ),
        _providerName = settings.name ?? 'google';

  /// Create a language model for text generation.
  ///
  /// Alias for [chat].
  LanguageModel languageModel(String modelId) => chat(modelId);

  /// Create a chat model for text generation.
  LanguageModel chat(String modelId) {
    final llmConfig = _createLLMConfig(modelId);
    final config = GoogleConfig.fromLLMConfig(llmConfig);
    final client = GoogleClient(config);
    final chat = GoogleChat(client, config);

    return DefaultLanguageModel(
      providerId: _providerName,
      modelId: modelId,
      config: llmConfig,
      chat: chat,
    );
  }

  /// Create an embeddings model.
  EmbeddingCapability embedding(String modelId) {
    final llmConfig = _createLLMConfig(modelId);
    final config = GoogleConfig.fromLLMConfig(llmConfig);
    final client = GoogleClient(config);
    return GoogleEmbeddings(client, config);
  }

  /// Alias for [embedding] to mirror the Vercel AI SDK.
  EmbeddingCapability textEmbedding(String modelId) => embedding(modelId);

  /// Alias for [embedding] to mirror the Vercel AI SDK.
  EmbeddingCapability textEmbeddingModel(String modelId) => embedding(modelId);

  /// Create an image generation model.
  ImageGenerationCapability image(String modelId) => imageModel(modelId);

  /// Alias for [image] to mirror the Vercel AI SDK.
  ImageGenerationCapability imageModel(String modelId) {
    final llmConfig = _createLLMConfig(modelId);
    final config = GoogleConfig.fromLLMConfig(llmConfig);
    final client = GoogleClient(config);
    return GoogleImages(client, config);
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
    if (value.isEmpty) return ProviderDefaults.googleBaseUrl;
    return value.endsWith('/') ? value : '$value/';
  }
}

/// Create a Google Generative AI model factory (Vercel AI-style).
///
/// Example:
/// ```dart
/// final google = createGoogleGenerativeAI(
///   apiKey: 'AIza-...',
/// );
///
/// final model = google.chat('gemini-1.5-flash');
/// final result = await generateTextWithModel(
///   model: model,
///   messages: [ChatMessage.user('Hello')],
/// );
/// ```
GoogleGenerativeAI createGoogleGenerativeAI({
  required String apiKey,
  String? baseUrl,
  Map<String, String>? headers,
  String? name,
  Duration? timeout,
}) {
  return GoogleGenerativeAI(
    GoogleGenerativeAIProviderSettings(
      apiKey: apiKey,
      baseUrl: baseUrl,
      headers: headers,
      name: name,
      timeout: timeout,
    ),
  );
}

/// Alias for [createGoogleGenerativeAI] to mirror the default `google`
/// export from the Vercel AI SDK.
GoogleGenerativeAI google({
  required String apiKey,
  String? baseUrl,
  Map<String, String>? headers,
  String? name,
  Duration? timeout,
}) {
  return createGoogleGenerativeAI(
    apiKey: apiKey,
    baseUrl: baseUrl,
    headers: headers,
    name: name,
    timeout: timeout,
  );
}

/// Create a Google provider with default configuration
GoogleProvider createGoogleProvider({
  required String apiKey,
  String? model,
  String? baseUrl,
  int? maxTokens,
  double? temperature,
  String? systemPrompt,
  Duration? timeout,
  double? topP,
  int? topK,
  ReasoningEffort? reasoningEffort,
  int? thinkingBudgetTokens,
  bool? includeThoughts,
  bool? enableImageGeneration,
  List<String>? responseModalities,
  List<SafetySetting>? safetySettings,
  int? maxInlineDataSize,
  int? candidateCount,
  List<String>? stopSequences,
  String? embeddingTaskType,
  String? embeddingTitle,
  int? embeddingDimensions,
}) {
  final config = GoogleConfig(
    apiKey: apiKey,
    model: model ?? 'gemini-1.5-flash',
    baseUrl: baseUrl ?? 'https://generativelanguage.googleapis.com/v1beta/',
    maxTokens: maxTokens,
    temperature: temperature,
    systemPrompt: systemPrompt,
    timeout: timeout,
    topP: topP,
    topK: topK,
    reasoningEffort: reasoningEffort,
    thinkingBudgetTokens: thinkingBudgetTokens,
    includeThoughts: includeThoughts,
    enableImageGeneration: enableImageGeneration,
    responseModalities: responseModalities,
    safetySettings: safetySettings,
    maxInlineDataSize: maxInlineDataSize ?? 20 * 1024 * 1024,
    candidateCount: candidateCount,
    stopSequences: stopSequences,
    embeddingTaskType: embeddingTaskType,
    embeddingTitle: embeddingTitle,
    embeddingDimensions: embeddingDimensions,
  );

  return GoogleProvider(config);
}

/// Create a Google provider for chat
GoogleProvider createGoogleChatProvider({
  required String apiKey,
  String model = 'gemini-1.5-flash',
  String? systemPrompt,
  double? temperature,
  int? maxTokens,
}) {
  return createGoogleProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    temperature: temperature,
    maxTokens: maxTokens,
  );
}

/// Create a Google provider for reasoning tasks
GoogleProvider createGoogleReasoningProvider({
  required String apiKey,
  String model = 'gemini-2.0-flash-thinking-exp',
  String? systemPrompt,
  int? thinkingBudgetTokens,
  bool includeThoughts = true,
}) {
  return createGoogleProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    thinkingBudgetTokens: thinkingBudgetTokens,
    includeThoughts: includeThoughts,
  );
}

/// Create a Google provider for vision tasks
GoogleProvider createGoogleVisionProvider({
  required String apiKey,
  String model = 'gemini-1.5-pro',
  String? systemPrompt,
  double? temperature,
  int? maxTokens,
}) {
  return createGoogleProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    temperature: temperature,
    maxTokens: maxTokens,
  );
}

/// Create a Google provider for image generation
GoogleProvider createGoogleImageGenerationProvider({
  required String apiKey,
  String model = 'gemini-1.5-pro',
  List<String>? responseModalities,
}) {
  return createGoogleProvider(
    apiKey: apiKey,
    model: model,
    enableImageGeneration: true,
    responseModalities: responseModalities ?? ['TEXT', 'IMAGE'],
  );
}

/// Create a Google provider for embeddings
GoogleProvider createGoogleEmbeddingProvider({
  required String apiKey,
  String model = 'text-embedding-004',
  String? embeddingTaskType,
  String? embeddingTitle,
  int? embeddingDimensions,
}) {
  return createGoogleProvider(
    apiKey: apiKey,
    model: model,
    embeddingTaskType: embeddingTaskType,
    embeddingTitle: embeddingTitle,
    embeddingDimensions: embeddingDimensions,
  );
}
