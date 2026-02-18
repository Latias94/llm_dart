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

/// Creates a provider registry from `ProviderV3` instances.
///
/// Mirrors the upstream AI SDK `createProviderRegistry({ providers })` shape,
/// where providers are objects implementing `ProviderV3`.
AiProviderRegistry createProviderRegistryV3(
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
class NoSuchModelError extends provider.NoSuchModelError {
  NoSuchModelError({
    required super.modelId,
    required super.modelType,
    super.message,
  });
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

class _ProviderV3FromEntry
    with provider.ProviderV3Defaults
    implements provider.ProviderV3 {
  final ProviderRegistryEntry entry;

  const _ProviderV3FromEntry(this.entry);

  @override
  ChatCapability languageModel(String modelId) {
    final factory = entry.languageModel;
    if (factory == null) {
      throw provider.NoSuchModelError(
        modelId: modelId,
        modelType: 'languageModel',
      );
    }
    return factory(modelId);
  }

  @override
  EmbeddingCapability embeddingModel(String modelId) {
    final factory = entry.embeddingModel;
    if (factory == null) {
      throw provider.NoSuchModelError(
        modelId: modelId,
        modelType: 'embeddingModel',
      );
    }
    return factory(modelId);
  }

  @override
  ImageGenerationCapability imageModel(String modelId) {
    final factory = entry.imageModel;
    if (factory == null) {
      throw provider.NoSuchModelError(
        modelId: modelId,
        modelType: 'imageModel',
      );
    }
    return factory(modelId);
  }

  @override
  ExperimentalVideoGenerationCapability videoModel(String modelId) {
    final factory = entry.videoModel;
    if (factory == null) {
      throw provider.NoSuchModelError(
        modelId: modelId,
        modelType: 'videoModel',
      );
    }
    return factory(modelId);
  }

  @override
  SpeechToTextCapability transcriptionModel(String modelId) {
    final factory = entry.transcriptionModel;
    if (factory == null) {
      throw provider.NoSuchModelError(
        modelId: modelId,
        modelType: 'transcriptionModel',
      );
    }
    return factory(modelId);
  }

  @override
  TextToSpeechCapability speechModel(String modelId) {
    final factory = entry.speechModel;
    if (factory == null) {
      throw provider.NoSuchModelError(
        modelId: modelId,
        modelType: 'speechModel',
      );
    }
    return factory(modelId);
  }

  @override
  RerankCapability rerankingModel(String modelId) {
    final factory = entry.rerankingModel;
    if (factory == null) {
      throw provider.NoSuchModelError(
        modelId: modelId,
        modelType: 'rerankingModel',
      );
    }
    return factory(modelId);
  }
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

  void registerProvider({
    required String id,
    required ProviderRegistryEntry provider,
  }) {
    _providers[id] = _ProviderV3FromEntry(provider);
  }

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
    final resolvedProvider = _getProvider(split.providerId, 'languageModel');
    ChatCapability model;
    try {
      model = resolvedProvider.languageModel(split.modelId);
    } on provider.NoSuchModelError catch (e) {
      throw NoSuchModelError(
          modelId: id, modelType: e.modelType, message: e.message);
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
      throw NoSuchModelError(
          modelId: id, modelType: e.modelType, message: e.message);
    }
  }

  ImageGenerationCapability imageModel(String id) {
    final split = _splitId(id, 'imageModel');
    final resolvedProvider = _getProvider(split.providerId, 'imageModel');
    try {
      return resolvedProvider.imageModel(split.modelId);
    } on provider.NoSuchModelError catch (e) {
      throw NoSuchModelError(
          modelId: id, modelType: e.modelType, message: e.message);
    }
  }

  /// Experimental: resolves a video model by registry id (e.g. `google:veo-2.0-generate-001`).
  ExperimentalVideoGenerationCapability videoModel(String id) {
    final split = _splitId(id, 'videoModel');
    final resolvedProvider = _getProvider(split.providerId, 'videoModel');
    try {
      return resolvedProvider.videoModel(split.modelId);
    } on provider.NoSuchModelError catch (e) {
      throw NoSuchModelError(
          modelId: id, modelType: e.modelType, message: e.message);
    }
  }

  SpeechToTextCapability transcriptionModel(String id) {
    final split = _splitId(id, 'transcriptionModel');
    final resolvedProvider =
        _getProvider(split.providerId, 'transcriptionModel');
    try {
      return resolvedProvider.transcriptionModel(split.modelId);
    } on provider.NoSuchModelError catch (e) {
      throw NoSuchModelError(
          modelId: id, modelType: e.modelType, message: e.message);
    }
  }

  TextToSpeechCapability speechModel(String id) {
    final split = _splitId(id, 'speechModel');
    final resolvedProvider = _getProvider(split.providerId, 'speechModel');
    try {
      return resolvedProvider.speechModel(split.modelId);
    } on provider.NoSuchModelError catch (e) {
      throw NoSuchModelError(
          modelId: id, modelType: e.modelType, message: e.message);
    }
  }

  RerankCapability rerankingModel(String id) {
    final split = _splitId(id, 'rerankingModel');
    final resolvedProvider = _getProvider(split.providerId, 'rerankingModel');
    try {
      return resolvedProvider.rerankingModel(split.modelId);
    } on provider.NoSuchModelError catch (e) {
      throw NoSuchModelError(
          modelId: id, modelType: e.modelType, message: e.message);
    }
  }
}
