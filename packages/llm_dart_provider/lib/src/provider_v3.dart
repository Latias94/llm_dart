import 'package:llm_dart_core/llm_dart_core.dart';

import 'errors/no_such_model_error.dart';

/// Transport-agnostic provider interface (AI SDK v3 style).
///
/// Mirrors Vercel AI SDK's `ProviderV3` from `@ai-sdk/provider`.
abstract interface class ProviderV3 {
  /// The provider specification version.
  ///
  /// Always `'v3'` for this interface.
  String get specificationVersion;

  /// Returns the language model with the given id.
  ChatCapability languageModel(String modelId);

  /// Returns the embedding model with the given id.
  EmbeddingCapability embeddingModel(String modelId);

  /// Deprecated alias for `embeddingModel` (upstream parity).
  @Deprecated('Use embeddingModel instead.')
  EmbeddingCapability textEmbeddingModel(String modelId);

  /// Returns the image model with the given id.
  ImageGenerationCapability imageModel(String modelId);

  /// Returns the transcription model with the given id.
  SpeechToTextCapability transcriptionModel(String modelId);

  /// Returns the speech model with the given id.
  TextToSpeechCapability speechModel(String modelId);

  /// Returns the reranking model with the given id.
  RerankCapability rerankingModel(String modelId);

  /// Experimental: returns the video model with the given id.
  ExperimentalVideoGenerationCapability videoModel(String modelId);
}

/// Default implementations for optional/unimplemented models.
///
/// The upstream `ProviderV3` marks several model getters as optional. Dart
/// interfaces do not support optional members, so we provide a `mixin` with
/// consistent default behavior (throwing [NoSuchModelError]).
mixin ProviderV3Defaults implements ProviderV3 {
  @override
  String get specificationVersion => 'v3';

  @override
  ChatCapability languageModel(String modelId) =>
      throw NoSuchModelError(modelId: modelId, modelType: 'languageModel');

  @override
  EmbeddingCapability embeddingModel(String modelId) =>
      throw NoSuchModelError(modelId: modelId, modelType: 'embeddingModel');

  @override
  EmbeddingCapability textEmbeddingModel(String modelId) =>
      embeddingModel(modelId);

  @override
  ImageGenerationCapability imageModel(String modelId) =>
      throw NoSuchModelError(modelId: modelId, modelType: 'imageModel');

  @override
  SpeechToTextCapability transcriptionModel(String modelId) =>
      throw NoSuchModelError(modelId: modelId, modelType: 'transcriptionModel');

  @override
  TextToSpeechCapability speechModel(String modelId) =>
      throw NoSuchModelError(modelId: modelId, modelType: 'speechModel');

  @override
  RerankCapability rerankingModel(String modelId) =>
      throw NoSuchModelError(modelId: modelId, modelType: 'rerankingModel');

  @override
  ExperimentalVideoGenerationCapability videoModel(String modelId) =>
      throw NoSuchModelError(modelId: modelId, modelType: 'videoModel');
}
