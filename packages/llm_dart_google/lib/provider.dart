import 'package:llm_dart_core/llm_dart_core.dart';
import 'client.dart';
import 'config.dart';
import 'chat.dart';
import 'embeddings.dart';
import 'images.dart';
import 'model_path.dart';
import 'tts.dart';
import 'video.dart';

/// Google provider implementation
///
/// This provider implements the ChatCapability, EmbeddingCapability, ImageGenerationCapability,
/// and GoogleTTSCapability interfaces and delegates to specialized capability modules for different functionalities.
class GoogleProvider
    implements
        ChatCapability,
        ModelIdentityCapability,
        ChatStreamPartsCapability,
        PromptChatCapability,
        PromptChatStreamPartsCapability,
        EmbeddingCapability,
        ImageGenerationCapability,
        ImageGenerationCallOptionsCapability,
        ExperimentalVideoGenerationCapability,
        ExperimentalVideoGenerationCallOptionsCapability,
        ExperimentalVideoGenerationMaxVideosPerCallCapability,
        TextToSpeechCapability,
        StreamingTextToSpeechCapability,
        VoiceListingCapability,
        GoogleTTSCapability,
        ProviderCapabilities {
  final GoogleClient _client;
  final GoogleConfig config;

  // Capability modules
  late final GoogleChat _chat;
  late final GoogleEmbeddings _embeddings;
  late final GoogleImages _images;
  late final GoogleVideo _video;
  late final GoogleTTS _tts;

  GoogleProvider(
    this.config, {
    GoogleClient? client,
  }) : _client = client ?? GoogleClient(config) {
    // Initialize capability modules
    _chat = GoogleChat(_client, config);
    _embeddings = GoogleEmbeddings(_client, config);
    _images = GoogleImages(_client, config);
    _video = GoogleVideo(_client, config);
    _tts = GoogleTTS(_client, config);
  }

  @override
  String get providerId => config.providerId;

  @override
  String get modelId => config.model;

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) async {
    return _chat.chat(
      messages,
      providerTools: providerTools,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) async {
    return _chat.chatWithTools(
      messages,
      tools,
      providerTools: providerTools,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    return _chat.chatStreamParts(
      messages,
      providerTools: providerTools,
      tools: tools,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chatPrompt(
    Prompt prompt, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    return _chat.chatPrompt(
      prompt,
      providerTools: providerTools,
      tools: tools,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<LLMStreamPart> chatPromptStreamParts(
    Prompt prompt, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    return _chat.chatPromptStreamParts(
      prompt,
      providerTools: providerTools,
      tools: tools,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async {
    return _chat.memoryContents();
  }

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    return _chat.summarizeHistory(messages);
  }

  // ========== EmbeddingCapability ==========

  @override
  Future<EmbeddingResponse> embed(
    List<String> input, {
    CancelToken? cancelToken,
  }) async {
    return _embeddings.embed(input, cancelToken: cancelToken);
  }

  // ========== ImageGenerationCapability (delegated to images module) ==========

  @override
  Future<ImageGenerationResponse> generateImages(
    ImageGenerationRequest request,
  ) async {
    return _images.generateImages(request);
  }

  @override
  Future<ImageGenerationResponse> generateImagesWithCallOptions(
    ImageGenerationRequest request, {
    required LLMCallOptions callOptions,
  }) {
    return _images.generateImagesWithCallOptions(
      request,
      callOptions: callOptions,
    );
  }

  @override
  Future<ImageGenerationResponse> editImage(ImageEditRequest request) async {
    return _images.editImage(request);
  }

  @override
  Future<ImageGenerationResponse> editImageWithCallOptions(
    ImageEditRequest request, {
    required LLMCallOptions callOptions,
  }) {
    return _images.editImageWithCallOptions(
      request,
      callOptions: callOptions,
    );
  }

  @override
  Future<ImageGenerationResponse> createVariation(
    ImageVariationRequest request,
  ) async {
    return _images.createVariation(request);
  }

  @override
  Future<ImageGenerationResponse> createVariationWithCallOptions(
    ImageVariationRequest request, {
    required LLMCallOptions callOptions,
  }) {
    return _images.createVariationWithCallOptions(
      request,
      callOptions: callOptions,
    );
  }

  @override
  List<String> getSupportedSizes() {
    return _images.getSupportedSizes();
  }

  @override
  List<String> getSupportedFormats() {
    return _images.getSupportedFormats();
  }

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
  }) async {
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

  // ========== ExperimentalVideoGenerationCapability ==========

  @override
  Future<ExperimentalVideoGenerationResponse> generateVideos(
    ExperimentalVideoGenerationRequest request, {
    CancelToken? cancelToken,
  }) {
    return _video.generateVideos(request, cancelToken: cancelToken);
  }

  @override
  Future<ExperimentalVideoGenerationResponse> generateVideosWithCallOptions(
    ExperimentalVideoGenerationRequest request, {
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    return _video.generateVideosWithCallOptions(
      request,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  @override
  int get maxVideosPerCall => 4;

  // ========== Task-specific audio capabilities ==========

  @override
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    CancelToken? cancelToken,
  }) async {
    final voiceName = request.voice ?? 'Kore';
    final model = request.model ?? _tts.defaultTTSModel;

    final startedAt = DateTime.now().toUtc();
    final response = await _tts.generateSpeech(
      GoogleTTSRequest.singleSpeaker(
        text: request.text,
        voiceName: voiceName,
        model: model,
      ),
    );

    final endpoint = '${googleModelPath(model)}:generateContent';
    final providerMetadata = <String, dynamic>{
      'google': {
        'model': model,
        'endpoint': endpoint,
      },
      'google.speech': {
        'model': model,
        'endpoint': endpoint,
      },
    };

    return TTSResponse(
      audioData: response.audioData,
      contentType: response.contentType,
      voice: voiceName,
      model: model,
      usage: response.usage,
      duration: null,
      sampleRate: null,
      responses: [
        SpeechModelResponseMetadata(
          timestamp: startedAt,
          modelId: model,
        ),
      ],
      providerMetadata: providerMetadata,
    );
  }

  @override
  Stream<AudioStreamEvent> textToSpeechStream(
    TTSRequest request, {
    CancelToken? cancelToken,
  }) async* {
    final voiceName = request.voice ?? 'Kore';
    final model = request.model ?? _tts.defaultTTSModel;

    final stream = _tts.generateSpeechStream(
      GoogleTTSRequest.singleSpeaker(
        text: request.text,
        voiceName: voiceName,
        model: model,
      ),
    );

    await for (final event in stream) {
      if (event is GoogleTTSAudioDataEvent) {
        yield AudioDataEvent(data: event.data, isFinal: event.isFinal);
        continue;
      }
      if (event is GoogleTTSCompletionEvent) {
        yield AudioMetadataEvent(contentType: event.response.contentType);
        yield AudioDataEvent(data: const <int>[], isFinal: true);
        continue;
      }
      if (event is GoogleTTSErrorEvent) {
        yield AudioErrorEvent(message: event.message, code: event.code);
        continue;
      }
      if (event is GoogleTTSMetadataEvent) {
        yield AudioMetadataEvent(contentType: event.contentType);
        continue;
      }
    }
  }

  @override
  Future<List<VoiceInfo>> getVoices() async {
    final voices = await _tts.getAvailableVoices();
    return voices
        .map(
          (v) => VoiceInfo(
            id: v.name,
            name: v.name,
            description: v.description,
          ),
        )
        .toList(growable: false);
  }

  List<String> getSupportedAudioFormats() {
    // Gemini audio output is returned as inlineData with a mimeType.
    // We expose a conservative default here.
    return const ['pcm'];
  }

  // ========== GoogleTTSCapability ==========

  @override
  Future<GoogleTTSResponse> generateSpeech(GoogleTTSRequest request) async {
    return _tts.generateSpeech(request);
  }

  @override
  Stream<GoogleTTSStreamEvent> generateSpeechStream(GoogleTTSRequest request) {
    return _tts.generateSpeechStream(request);
  }

  @override
  Future<List<GoogleVoiceInfo>> getAvailableVoices() async {
    return _tts.getAvailableVoices();
  }

  @override
  Future<List<String>> getSupportedTtsLanguageCodes() async {
    return _tts.getSupportedTtsLanguageCodes();
  }

  /// Check if TTS is supported
  /// Get provider name
  String get providerName => 'Google';

  // ========== ProviderCapabilities ==========

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
        // Intentionally optimistic: do not maintain a model capability matrix.
        LLMCapability.vision,
        LLMCapability.reasoning,
        LLMCapability.imageGeneration,
        LLMCapability.experimentalVideoGeneration,
        LLMCapability.embedding,
        LLMCapability.textToSpeech,
        LLMCapability.streamingTextToSpeech,
      };

  @override
  bool supports(LLMCapability capability) {
    return supportedCapabilities.contains(capability);
  }
}
