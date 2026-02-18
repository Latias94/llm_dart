import 'package:llm_dart_core/llm_dart_core.dart';

import 'errors/no_such_model_error.dart';
import 'provider_v3.dart';

/// Creates a [ProviderV3] from a set of model factory functions.
///
/// This is the Dart equivalent of the upstream AI SDK provider functions that
/// are callable and expose `languageModel(...)`, `embeddingModel(...)`, etc.
ProviderV3 createProviderV3({
  ChatCapability Function(String modelId)? languageModel,
  EmbeddingCapability Function(String modelId)? embeddingModel,
  ImageGenerationCapability Function(String modelId)? imageModel,
  ExperimentalVideoGenerationCapability Function(String modelId)? videoModel,
  SpeechToTextCapability Function(String modelId)? transcriptionModel,
  TextToSpeechCapability Function(String modelId)? speechModel,
  RerankCapability Function(String modelId)? rerankingModel,
}) {
  return _FactoryProviderV3(
    languageModel: languageModel,
    embeddingModel: embeddingModel,
    imageModel: imageModel,
    videoModel: videoModel,
    transcriptionModel: transcriptionModel,
    speechModel: speechModel,
    rerankingModel: rerankingModel,
  );
}

class _FactoryProviderV3 with ProviderV3Defaults implements ProviderV3 {
  final ChatCapability Function(String modelId)? _languageModel;
  final EmbeddingCapability Function(String modelId)? _embeddingModel;
  final ImageGenerationCapability Function(String modelId)? _imageModel;
  final ExperimentalVideoGenerationCapability Function(String modelId)?
      _videoModel;
  final SpeechToTextCapability Function(String modelId)? _transcriptionModel;
  final TextToSpeechCapability Function(String modelId)? _speechModel;
  final RerankCapability Function(String modelId)? _rerankingModel;

  const _FactoryProviderV3({
    required ChatCapability Function(String modelId)? languageModel,
    required EmbeddingCapability Function(String modelId)? embeddingModel,
    required ImageGenerationCapability Function(String modelId)? imageModel,
    required ExperimentalVideoGenerationCapability Function(String modelId)?
        videoModel,
    required SpeechToTextCapability Function(String modelId)?
        transcriptionModel,
    required TextToSpeechCapability Function(String modelId)? speechModel,
    required RerankCapability Function(String modelId)? rerankingModel,
  })  : _languageModel = languageModel,
        _embeddingModel = embeddingModel,
        _imageModel = imageModel,
        _videoModel = videoModel,
        _transcriptionModel = transcriptionModel,
        _speechModel = speechModel,
        _rerankingModel = rerankingModel;

  @override
  ChatCapability languageModel(String modelId) {
    final factory = _languageModel;
    if (factory == null) {
      throw NoSuchModelError(modelId: modelId, modelType: 'languageModel');
    }
    return factory(modelId);
  }

  @override
  EmbeddingCapability embeddingModel(String modelId) {
    final factory = _embeddingModel;
    if (factory == null) {
      throw NoSuchModelError(modelId: modelId, modelType: 'embeddingModel');
    }
    return factory(modelId);
  }

  @override
  ImageGenerationCapability imageModel(String modelId) {
    final factory = _imageModel;
    if (factory == null) {
      throw NoSuchModelError(modelId: modelId, modelType: 'imageModel');
    }
    return factory(modelId);
  }

  @override
  ExperimentalVideoGenerationCapability videoModel(String modelId) {
    final factory = _videoModel;
    if (factory == null) {
      throw NoSuchModelError(modelId: modelId, modelType: 'videoModel');
    }
    return factory(modelId);
  }

  @override
  SpeechToTextCapability transcriptionModel(String modelId) {
    final factory = _transcriptionModel;
    if (factory == null) {
      throw NoSuchModelError(modelId: modelId, modelType: 'transcriptionModel');
    }
    return factory(modelId);
  }

  @override
  TextToSpeechCapability speechModel(String modelId) {
    final factory = _speechModel;
    if (factory == null) {
      throw NoSuchModelError(modelId: modelId, modelType: 'speechModel');
    }
    return factory(modelId);
  }

  @override
  RerankCapability rerankingModel(String modelId) {
    final factory = _rerankingModel;
    if (factory == null) {
      throw NoSuchModelError(modelId: modelId, modelType: 'rerankingModel');
    }
    return factory(modelId);
  }
}
