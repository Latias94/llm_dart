import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/core/capability.dart';
import 'package:llm_dart_core/core/llm_error.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_google/llm_dart_google.dart';

/// Google-specific LLM builder with provider-specific configuration methods.
///
/// This wrapper is provided by the **umbrella** `llm_dart` package. Provider
/// subpackages do not depend on `llm_dart_builder`.
class GoogleLLMBuilder {
  final LLMBuilder _baseBuilder;

  GoogleLLMBuilder(this._baseBuilder);

  GoogleLLMBuilder embeddingTaskType(String taskType) {
    _baseBuilder.option('embeddingTaskType', taskType);
    return this;
  }

  GoogleLLMBuilder embeddingTitle(String title) {
    _baseBuilder.option('embeddingTitle', title);
    return this;
  }

  GoogleLLMBuilder embeddingDimensions(int dimensions) {
    _baseBuilder.option('embeddingDimensions', dimensions);
    return this;
  }

  GoogleLLMBuilder reasoningEffort(ReasoningEffort effort) {
    _baseBuilder.reasoningEffort(effort);
    return this;
  }

  GoogleLLMBuilder thinkingBudgetTokens(int tokens) {
    _baseBuilder.option('thinkingBudgetTokens', tokens);
    return this;
  }

  GoogleLLMBuilder includeThoughts(bool include) {
    _baseBuilder.option('includeThoughts', include);
    return this;
  }

  GoogleLLMBuilder enableImageGeneration(bool enable) {
    _baseBuilder.option('enableImageGeneration', enable);
    return this;
  }

  GoogleLLMBuilder responseModalities(List<String> modalities) {
    _baseBuilder.option('responseModalities', modalities);
    return this;
  }

  GoogleLLMBuilder safetySettings(List<SafetySetting> settings) {
    _baseBuilder.option('safetySettings', settings);
    return this;
  }

  GoogleLLMBuilder maxInlineDataSize(int size) {
    _baseBuilder.option('maxInlineDataSize', size);
    return this;
  }

  GoogleLLMBuilder candidateCount(int count) {
    _baseBuilder.option('candidateCount', count);
    return this;
  }

  GoogleLLMBuilder stopSequences(List<String> sequences) {
    _baseBuilder.stopSequences(sequences);
    return this;
  }

  GoogleLLMBuilder webSearchTool({
    GoogleWebSearchToolOptions? options,
  }) {
    _baseBuilder.providerTool(GoogleProviderTools.webSearch(options: options));
    return this;
  }

  Future<ChatCapability> build() async => _baseBuilder.build();

  Future<EmbeddingCapability> buildEmbedding() async =>
      _baseBuilder.buildEmbedding();

  Future<ImageGenerationCapability> buildImageGeneration() async =>
      _baseBuilder.buildImageGeneration();

  Future<GoogleTTSCapability> buildGoogleTTS() async {
    final provider = await build();
    if (provider is! GoogleTTSCapability) {
      throw UnsupportedCapabilityError(
        'Google provider does not support TTS capabilities.',
      );
    }
    return provider as GoogleTTSCapability;
  }
}
