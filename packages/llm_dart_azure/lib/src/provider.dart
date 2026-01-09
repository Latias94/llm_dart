import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/audio.dart';
import 'package:llm_dart_openai_compatible/chat.dart';
import 'package:llm_dart_openai_compatible/client.dart';
import 'package:llm_dart_openai_compatible/embeddings.dart';
import 'package:llm_dart_openai_compatible/images.dart';
import 'package:llm_dart_openai_compatible/responses.dart';

import 'config.dart';

/// Azure OpenAI provider implementation.
class AzureOpenAIProvider
    implements
        ChatCapability,
        EmbeddingCapability,
        ImageGenerationCapability,
        TextToSpeechCapability,
        VoiceListingCapability,
        SpeechToTextCapability,
        AudioTranslationCapability,
        TranscriptionLanguageListingCapability,
        ProviderCapabilities {
  final OpenAIClient _client;
  final AzureOpenAIConfig config;

  late final OpenAIChat _chat;
  late final OpenAIEmbeddings _embeddings;
  late final OpenAIResponses _responses;
  late final OpenAIImages _images;
  late final OpenAIAudio _audio;

  AzureOpenAIProvider(this.config) : _client = OpenAIClient(config) {
    _chat = OpenAIChat(_client, config);
    _embeddings = OpenAIEmbeddings(_client, config);
    _responses = OpenAIResponses(_client, config);
    _images = OpenAIImages(_client, config);
    _audio = OpenAIAudio(_client, config);
  }

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.embedding,
        LLMCapability.toolCalling,
        LLMCapability.reasoning,
        LLMCapability.vision,
        LLMCapability.imageGeneration,
        LLMCapability.textToSpeech,
        LLMCapability.speechToText,
        LLMCapability.audioTranslation,
        LLMCapability.openaiResponses,
      };

  @override
  bool supports(LLMCapability capability) =>
      supportedCapabilities.contains(capability);

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) {
    if (config.useResponsesAPI) {
      return _responses.chat(messages, cancelToken: cancelToken);
    }
    return _chat.chat(messages, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) {
    if (config.useResponsesAPI) {
      return _responses.chatWithTools(messages, tools,
          cancelToken: cancelToken);
    }
    return _chat.chatWithTools(messages, tools, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    if (config.useResponsesAPI) {
      return _responses.chatStream(messages,
          tools: tools, cancelToken: cancelToken);
    }
    return _chat.chatStream(messages, tools: tools, cancelToken: cancelToken);
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    if (config.useResponsesAPI) {
      return _responses.chatStreamParts(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      );
    }
    return _chat.chatStreamParts(
      messages,
      tools: tools,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<ChatMessage>?> memoryContents() {
    if (config.useResponsesAPI) return _responses.memoryContents();
    return _chat.memoryContents();
  }

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) {
    if (config.useResponsesAPI) return _responses.summarizeHistory(messages);
    return _chat.summarizeHistory(messages);
  }

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancelToken? cancelToken,
  }) {
    return _embeddings.embed(input, cancelToken: cancelToken);
  }

  // ========== ImageGenerationCapability ==========

  @override
  Future<ImageGenerationResponse> generateImages(
    ImageGenerationRequest request,
  ) {
    return _images.generateImages(request);
  }

  @override
  Future<ImageGenerationResponse> editImage(ImageEditRequest request) {
    return _images.editImage(request);
  }

  @override
  Future<ImageGenerationResponse> createVariation(ImageVariationRequest request) {
    return _images.createVariation(request);
  }

  @override
  List<String> getSupportedSizes() => _images.getSupportedSizes();

  @override
  List<String> getSupportedFormats() => _images.getSupportedFormats();

  @override
  bool get supportsImageEditing => _images.supportsImageEditing;

  @override
  bool get supportsImageVariations => _images.supportsImageVariations;

  @override
  Future<List<String>> generateImage({
    required String prompt,
    String? model,
    String? negativePrompt,
    String? imageSize,
    int? batchSize,
    String? seed,
    int? numInferenceSteps,
    double? guidanceScale,
    bool? promptEnhancement,
  }) {
    return _images.generateImage(
      prompt: prompt,
      model: model,
      negativePrompt: negativePrompt,
      imageSize: imageSize,
      batchSize: batchSize,
      seed: seed,
      numInferenceSteps: numInferenceSteps,
      guidanceScale: guidanceScale,
      promptEnhancement: promptEnhancement,
    );
  }

  // ========== Audio capabilities ==========

  @override
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    CancelToken? cancelToken,
  }) {
    return _audio.textToSpeech(request, cancelToken: cancelToken);
  }

  @override
  Future<List<VoiceInfo>> getVoices() => _audio.getVoices();

  @override
  Future<STTResponse> speechToText(
    STTRequest request, {
    CancelToken? cancelToken,
  }) {
    return _audio.speechToText(request, cancelToken: cancelToken);
  }

  @override
  Future<STTResponse> translateAudio(
    AudioTranslationRequest request, {
    CancelToken? cancelToken,
  }) {
    return _audio.translateAudio(request, cancelToken: cancelToken);
  }

  @override
  Future<List<LanguageInfo>> getSupportedLanguages() {
    return _audio.getSupportedLanguages();
  }
}
