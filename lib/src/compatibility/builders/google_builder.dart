import '../../../builder/llm_builder.dart';
import '../../../core/capability.dart';
import '../../../core/llm_error.dart';
import '../../../models/chat_models.dart';
import '../../../providers/google/config.dart';
import '../../config/legacy_config_keys.dart';

/// Google-specific legacy builder DSL layered on top of [LLMBuilder].
class GoogleLLMBuilder {
  final LLMBuilder _baseBuilder;

  GoogleLLMBuilder(this._baseBuilder);

  /// Sets the task type for embeddings.
  GoogleLLMBuilder embeddingTaskType(String taskType) {
    _baseBuilder.extension(LegacyExtensionKeys.embeddingTaskType, taskType);
    return this;
  }

  /// Sets the title for embedding documents.
  GoogleLLMBuilder embeddingTitle(String title) {
    _baseBuilder.extension(LegacyExtensionKeys.embeddingTitle, title);
    return this;
  }

  /// Sets the output dimensionality for embeddings.
  GoogleLLMBuilder embeddingDimensions(int dimensions) {
    _baseBuilder.extension(LegacyExtensionKeys.embeddingDimensions, dimensions);
    return this;
  }

  /// Sets the reasoning effort for models that support it.
  GoogleLLMBuilder reasoningEffort(ReasoningEffort effort) {
    _baseBuilder.extension(LegacyExtensionKeys.reasoningEffort, effort.value);
    return this;
  }

  /// Sets thinking budget tokens for reasoning models.
  GoogleLLMBuilder thinkingBudgetTokens(int tokens) {
    _baseBuilder.extension(LegacyExtensionKeys.thinkingBudgetTokens, tokens);
    return this;
  }

  /// Enables or disables including thoughts in the response.
  GoogleLLMBuilder includeThoughts(bool include) {
    _baseBuilder.extension(LegacyExtensionKeys.includeThoughts, include);
    return this;
  }

  /// Enables image generation capability.
  GoogleLLMBuilder enableImageGeneration(bool enable) {
    _baseBuilder.extension(LegacyExtensionKeys.enableImageGeneration, enable);
    return this;
  }

  /// Sets response modalities.
  GoogleLLMBuilder responseModalities(List<String> modalities) {
    _baseBuilder.extension(LegacyExtensionKeys.responseModalities, modalities);
    return this;
  }

  /// Sets safety settings for content filtering.
  GoogleLLMBuilder safetySettings(List<SafetySetting> settings) {
    _baseBuilder.extension(LegacyExtensionKeys.safetySettings, settings);
    return this;
  }

  /// Sets maximum inline data size.
  GoogleLLMBuilder maxInlineDataSize(int size) {
    _baseBuilder.extension(LegacyExtensionKeys.maxInlineDataSize, size);
    return this;
  }

  /// Sets candidate count for response generation.
  GoogleLLMBuilder candidateCount(int count) {
    _baseBuilder.extension(LegacyExtensionKeys.candidateCount, count);
    return this;
  }

  /// Sets stop sequences for response generation.
  GoogleLLMBuilder stopSequences(List<String> sequences) {
    _baseBuilder.extension('stopSequences', sequences);
    return this;
  }

  /// Configure for semantic similarity tasks.
  GoogleLLMBuilder forSemanticSimilarity({int? dimensions}) {
    embeddingTaskType('SEMANTIC_SIMILARITY');
    if (dimensions != null) {
      embeddingDimensions(dimensions);
    }
    return this;
  }

  /// Configure for document retrieval.
  GoogleLLMBuilder forDocumentRetrieval({String? title, int? dimensions}) {
    embeddingTaskType('RETRIEVAL_DOCUMENT');
    if (title != null) {
      embeddingTitle(title);
    }
    if (dimensions != null) {
      embeddingDimensions(dimensions);
    }
    return this;
  }

  /// Configure for search queries.
  GoogleLLMBuilder forSearchQuery({int? dimensions}) {
    embeddingTaskType('RETRIEVAL_QUERY');
    if (dimensions != null) {
      embeddingDimensions(dimensions);
    }
    return this;
  }

  /// Configure for classification tasks.
  GoogleLLMBuilder forClassification({int? dimensions}) {
    embeddingTaskType('CLASSIFICATION');
    if (dimensions != null) {
      embeddingDimensions(dimensions);
    }
    return this;
  }

  /// Configure for clustering tasks.
  GoogleLLMBuilder forClustering({int? dimensions}) {
    embeddingTaskType('CLUSTERING');
    if (dimensions != null) {
      embeddingDimensions(dimensions);
    }
    return this;
  }

  /// Builds and returns a configured LLM provider instance.
  Future<ChatCapability> build() async {
    return _baseBuilder.build();
  }

  /// Builds a provider with EmbeddingCapability.
  Future<EmbeddingCapability> buildEmbedding() async {
    return _baseBuilder.buildEmbedding();
  }

  /// Builds a provider with ModelListingCapability.
  Future<ModelListingCapability> buildModelListing() async {
    return _baseBuilder.buildModelListing();
  }

  /// Builds a provider with ImageGenerationCapability.
  Future<ImageGenerationCapability> buildImageGeneration() async {
    return _baseBuilder.buildImageGeneration();
  }

  /// Builds a provider with GoogleTTSCapability.
  Future<GoogleTTSCapability> buildGoogleTTS() async {
    final provider = await build();
    if (provider is! GoogleTTSCapability) {
      throw UnsupportedCapabilityError(
        'Provider does not support Google TTS capabilities. '
        'Make sure you are using a Google provider with a TTS-compatible model.',
      );
    }
    return provider as GoogleTTSCapability;
  }

  /// Sets the TTS model to use.
  GoogleLLMBuilder ttsModel(String model) {
    _baseBuilder.model(model);
    return this;
  }

  /// Configure for single-speaker TTS.
  GoogleLLMBuilder singleSpeakerTTS({
    String voiceName = 'Kore',
    String? model,
  }) {
    if (model != null) {
      ttsModel(model);
    }
    _baseBuilder.extension('defaultVoiceName', voiceName);
    return this;
  }

  /// Configure for multi-speaker TTS.
  GoogleLLMBuilder multiSpeakerTTS({
    Map<String, String>? defaultSpeakerVoices,
    String? model,
  }) {
    if (model != null) {
      ttsModel(model);
    }
    if (defaultSpeakerVoices != null) {
      _baseBuilder.extension('defaultSpeakerVoices', defaultSpeakerVoices);
    }
    return this;
  }

  /// Enable audio response modality for TTS.
  GoogleLLMBuilder enableAudioOutput() {
    responseModalities(['AUDIO']);
    return this;
  }

  /// Configure TTS with specific voice.
  GoogleLLMBuilder voice(String voiceName) {
    _baseBuilder.extension('defaultVoiceName', voiceName);
    return this;
  }
}
