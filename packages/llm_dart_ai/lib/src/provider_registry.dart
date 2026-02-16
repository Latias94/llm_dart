import 'package:llm_dart_core/llm_dart_core.dart';

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
  Map<String, ProviderRegistryEntry> providers, {
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
    registry.registerProvider(id: entry.key, provider: entry.value);
  }

  return registry;
}

/// @deprecated Use [createProviderRegistry] instead.
@Deprecated('Use createProviderRegistry instead.')
AiProviderRegistry experimentalCreateProviderRegistry(
  Map<String, ProviderRegistryEntry> providers, {
  String separator = ':',
  LanguageModelMiddleware? languageModelMiddleware,
  List<LanguageModelMiddleware>? languageModelMiddlewares,
}) =>
    createProviderRegistry(
      providers,
      separator: separator,
      languageModelMiddleware: languageModelMiddleware,
      languageModelMiddlewares: languageModelMiddlewares,
    );

/// A single provider entry in a [ProviderRegistry].
///
/// Each factory is expected to return a capability instance configured for the
/// given model id.
class ProviderRegistryEntry {
  final ChatCapability Function(String modelId)? languageModel;
  final EmbeddingCapability Function(String modelId)? embeddingModel;
  final ImageGenerationCapability Function(String modelId)? imageModel;

  /// Experimental video model factory (Vercel AI SDK parity).
  ///
  /// This returns an [ExperimentalVideoGenerationCapability] that can be used
  /// with `experimentalGenerateVideo(...)`.
  final ExperimentalVideoGenerationCapability Function(String modelId)?
      videoModel;
  final SpeechToTextCapability Function(String modelId)? transcriptionModel;
  final TextToSpeechCapability Function(String modelId)? speechModel;
  final RerankCapability Function(String modelId)? rerankingModel;

  const ProviderRegistryEntry({
    this.languageModel,
    this.embeddingModel,
    this.imageModel,
    this.videoModel,
    this.transcriptionModel,
    this.speechModel,
    this.rerankingModel,
  });
}

/// Error thrown when a provider registry cannot resolve a model id.
class NoSuchModelError extends InvalidRequestError {
  final String modelId;
  final String modelType;

  NoSuchModelError({
    required this.modelId,
    required this.modelType,
    String? message,
  }) : super(
          message ??
              'No such $modelType: $modelId (invalid registry id or unsupported model type).',
        );
}

/// Error thrown when the provider id part does not exist in the registry.
class NoSuchProviderError extends NoSuchModelError {
  final String providerId;
  final List<String> availableProviders;

  NoSuchProviderError({
    required super.modelId,
    required super.modelType,
    required this.providerId,
    required this.availableProviders,
    String? message,
  }) : super(
          message: message ??
              'No such provider: $providerId (available providers: ${availableProviders.join(', ')})',
        );
}

/// Provider registry implementation.
class AiProviderRegistry {
  final Map<String, ProviderRegistryEntry> _providers = {};
  final String _separator;
  final List<LanguageModelMiddleware> _languageModelMiddlewares;

  AiProviderRegistry._({
    required String separator,
    required List<LanguageModelMiddleware> languageModelMiddlewares,
  })  : _separator = separator,
        _languageModelMiddlewares = languageModelMiddlewares;

  void registerProvider({
    required String id,
    required ProviderRegistryEntry provider,
  }) {
    _providers[id] = provider;
  }

  ProviderRegistryEntry _getProvider(String providerId, String modelType) {
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
      throw NoSuchModelError(
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
    final provider = _getProvider(split.providerId, 'languageModel');
    final factory = provider.languageModel;
    if (factory == null) {
      throw NoSuchModelError(modelId: id, modelType: 'languageModel');
    }

    var model = factory(split.modelId);
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
    final provider = _getProvider(split.providerId, 'embeddingModel');
    final factory = provider.embeddingModel;
    if (factory == null) {
      throw NoSuchModelError(modelId: id, modelType: 'embeddingModel');
    }
    return factory(split.modelId);
  }

  ImageGenerationCapability imageModel(String id) {
    final split = _splitId(id, 'imageModel');
    final provider = _getProvider(split.providerId, 'imageModel');
    final factory = provider.imageModel;
    if (factory == null) {
      throw NoSuchModelError(modelId: id, modelType: 'imageModel');
    }
    return factory(split.modelId);
  }

  /// Experimental: resolves a video model by registry id (e.g. `google:veo-2.0-generate-001`).
  ExperimentalVideoGenerationCapability videoModel(String id) {
    final split = _splitId(id, 'videoModel');
    final provider = _getProvider(split.providerId, 'videoModel');
    final factory = provider.videoModel;
    if (factory == null) {
      throw NoSuchModelError(modelId: id, modelType: 'videoModel');
    }
    return factory(split.modelId);
  }

  SpeechToTextCapability transcriptionModel(String id) {
    final split = _splitId(id, 'transcriptionModel');
    final provider = _getProvider(split.providerId, 'transcriptionModel');
    final factory = provider.transcriptionModel;
    if (factory == null) {
      throw NoSuchModelError(modelId: id, modelType: 'transcriptionModel');
    }
    return factory(split.modelId);
  }

  TextToSpeechCapability speechModel(String id) {
    final split = _splitId(id, 'speechModel');
    final provider = _getProvider(split.providerId, 'speechModel');
    final factory = provider.speechModel;
    if (factory == null) {
      throw NoSuchModelError(modelId: id, modelType: 'speechModel');
    }
    return factory(split.modelId);
  }

  RerankCapability rerankingModel(String id) {
    final split = _splitId(id, 'rerankingModel');
    final provider = _getProvider(split.providerId, 'rerankingModel');
    final factory = provider.rerankingModel;
    if (factory == null) {
      throw NoSuchModelError(modelId: id, modelType: 'rerankingModel');
    }
    return factory(split.modelId);
  }
}
