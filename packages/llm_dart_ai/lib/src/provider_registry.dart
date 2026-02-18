import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;

import 'middleware.dart';
import 'wrap_language_model_with_middleware.dart';

/// Vercel AI SDK-style "provider registry" for resolving models by a combined id
/// like `openai:gpt-4.1`.
///
/// Notes (Dart-flavored):
/// - Providers are configured as factories per model-id.
/// - Only language models (chat) support middleware today.
/// - This is intentionally not tied to [LLMProviderRegistry] (factory registry)
///   to avoid core→provider coupling.
AiProviderRegistry createProviderRegistry(
  Map<String, provider.ProviderV3> providers, {
  String separator = ':',
  LanguageModelMiddleware? languageModelMiddleware,
  List<LanguageModelMiddleware>? languageModelMiddlewares,
}) {
  final all = <LanguageModelMiddleware>[
    if (languageModelMiddleware != null) languageModelMiddleware,
    ...?languageModelMiddlewares,
  ];

  final registry = AiProviderRegistry._(
    separator: separator,
    languageModelMiddlewares: List<LanguageModelMiddleware>.unmodifiable(all),
  );

  for (final entry in providers.entries) {
    registry.registerProviderV3(id: entry.key, provider: entry.value);
  }

  return registry;
}

/// Error thrown when the provider id part does not exist in the registry.
class NoSuchProviderError extends provider.NoSuchModelError {
  final String providerId;
  final List<String> availableProviders;

  NoSuchProviderError({
    required String modelId,
    required String modelType,
    required this.providerId,
    required this.availableProviders,
    String? message,
  }) : super(
          modelId: modelId,
          modelType: modelType,
          message: message ??
              'No such provider: $providerId (available providers: ${availableProviders.join(', ')})',
        );
}

/// Provider registry implementation.
class AiProviderRegistry {
  final Map<String, provider.ProviderV3> _providers = {};
  final String _separator;
  final List<LanguageModelMiddleware> _languageModelMiddlewares;

  AiProviderRegistry._({
    required String separator,
    required List<LanguageModelMiddleware> languageModelMiddlewares,
  })  : _separator = separator,
        _languageModelMiddlewares = languageModelMiddlewares;

  void registerProviderV3({
    required String id,
    required provider.ProviderV3 provider,
  }) {
    _providers[id] = provider;
  }

  provider.ProviderV3 _getProvider(String providerId, String modelType) {
    final provider = _providers[providerId];
    if (provider == null) {
      throw NoSuchProviderError(
        modelId: providerId,
        modelType: modelType,
        providerId: providerId,
        availableProviders: _providers.keys.toList(growable: false),
      );
    }
    return provider;
  }

  ({String providerId, String modelId}) _splitId(String id, String modelType) {
    final index = id.indexOf(_separator);
    if (index == -1) {
      throw provider.NoSuchModelError(
        modelId: id,
        modelType: modelType,
        message:
            'Invalid $modelType id for registry: $id (must be in the format "providerId$_separator'
            'modelId")',
      );
    }
    return (
      providerId: id.substring(0, index),
      modelId: id.substring(index + _separator.length),
    );
  }

  ChatCapability languageModel(String id) {
    final split = _splitId(id, 'languageModel');
    final resolvedProvider = _getProvider(split.providerId, 'languageModel');
    ChatCapability model;
    try {
      model = resolvedProvider.languageModel(split.modelId);
    } on provider.NoSuchModelError catch (e) {
      throw provider.NoSuchModelError(
        modelId: id,
        modelType: e.modelType,
        message: e.message,
      );
    }
    if (_languageModelMiddlewares.isNotEmpty) {
      model = wrapLanguageModelWithMiddleware(
        model,
        middlewares: _languageModelMiddlewares,
      );
    }
    return model;
  }

  EmbeddingCapability embeddingModel(String id) {
    final split = _splitId(id, 'embeddingModel');
    final resolvedProvider = _getProvider(split.providerId, 'embeddingModel');
    try {
      return resolvedProvider.embeddingModel(split.modelId);
    } on provider.NoSuchModelError catch (e) {
      throw provider.NoSuchModelError(
        modelId: id,
        modelType: e.modelType,
        message: e.message,
      );
    }
  }

  ImageGenerationCapability imageModel(String id) {
    final split = _splitId(id, 'imageModel');
    final resolvedProvider = _getProvider(split.providerId, 'imageModel');
    try {
      return resolvedProvider.imageModel(split.modelId);
    } on provider.NoSuchModelError catch (e) {
      throw provider.NoSuchModelError(
        modelId: id,
        modelType: e.modelType,
        message: e.message,
      );
    }
  }

  /// Experimental: resolves a video model by registry id (e.g. `google:veo-2.0-generate-001`).
  ExperimentalVideoGenerationCapability videoModel(String id) {
    final split = _splitId(id, 'videoModel');
    final resolvedProvider = _getProvider(split.providerId, 'videoModel');
    try {
      return resolvedProvider.videoModel(split.modelId);
    } on provider.NoSuchModelError catch (e) {
      throw provider.NoSuchModelError(
        modelId: id,
        modelType: e.modelType,
        message: e.message,
      );
    }
  }

  SpeechToTextCapability transcriptionModel(String id) {
    final split = _splitId(id, 'transcriptionModel');
    final resolvedProvider =
        _getProvider(split.providerId, 'transcriptionModel');
    try {
      return resolvedProvider.transcriptionModel(split.modelId);
    } on provider.NoSuchModelError catch (e) {
      throw provider.NoSuchModelError(
        modelId: id,
        modelType: e.modelType,
        message: e.message,
      );
    }
  }

  TextToSpeechCapability speechModel(String id) {
    final split = _splitId(id, 'speechModel');
    final resolvedProvider = _getProvider(split.providerId, 'speechModel');
    try {
      return resolvedProvider.speechModel(split.modelId);
    } on provider.NoSuchModelError catch (e) {
      throw provider.NoSuchModelError(
        modelId: id,
        modelType: e.modelType,
        message: e.message,
      );
    }
  }

  RerankCapability rerankingModel(String id) {
    final split = _splitId(id, 'rerankingModel');
    final resolvedProvider = _getProvider(split.providerId, 'rerankingModel');
    try {
      return resolvedProvider.rerankingModel(split.modelId);
    } on provider.NoSuchModelError catch (e) {
      throw provider.NoSuchModelError(
        modelId: id,
        modelType: e.modelType,
        message: e.message,
      );
    }
  }
}
