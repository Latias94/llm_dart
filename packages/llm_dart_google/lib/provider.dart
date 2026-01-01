import 'package:llm_dart_core/llm_dart_core.dart';
import 'client.dart';
import 'config.dart';
import 'chat.dart';
import 'embeddings.dart';
import 'images.dart';
import 'tts.dart';

/// Google provider implementation
///
/// This provider implements the ChatCapability, EmbeddingCapability, ImageGenerationCapability,
/// and GoogleTTSCapability interfaces and delegates to specialized capability modules for different functionalities.
class GoogleProvider
    implements
        ChatCapability,
        ChatStreamPartsCapability,
        EmbeddingCapability,
        ImageGenerationCapability,
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
  late final GoogleTTS _tts;

  GoogleProvider(this.config) : _client = GoogleClient(config) {
    // Initialize capability modules
    _chat = GoogleChat(_client, config);
    _embeddings = GoogleEmbeddings(_client, config);
    _images = GoogleImages(_client, config);
    _tts = GoogleTTS(_client, config);
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) async {
    return _chat.chat(messages, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    return _chat.chatWithTools(messages, tools, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    return _chat.chatStream(messages, tools: tools, cancelToken: cancelToken);
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    return _chat.chatStreamParts(messages,
        tools: tools, cancelToken: cancelToken);
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
  Future<List<List<double>>> embed(
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
  Future<ImageGenerationResponse> editImage(ImageEditRequest request) async {
    return _images.editImage(request);
  }

  @override
  Future<ImageGenerationResponse> createVariation(
    ImageVariationRequest request,
  ) async {
    return _images.createVariation(request);
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

  // ========== Task-specific audio capabilities ==========

  @override
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    CancelToken? cancelToken,
  }) async {
    final voiceName = request.voice ?? 'Kore';
    final model = request.model ?? _tts.defaultTTSModel;

    final response = await _tts.generateSpeech(
      GoogleTTSRequest.singleSpeaker(
        text: request.text,
        voiceName: voiceName,
        model: model,
      ),
    );

    return TTSResponse(
      audioData: response.audioData,
      contentType: response.contentType,
      voice: voiceName,
      model: model,
      usage: response.usage,
      duration: null,
      sampleRate: null,
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
        LLMCapability.embedding,
        LLMCapability.textToSpeech,
        LLMCapability.streamingTextToSpeech,
      };

  @override
  bool supports(LLMCapability capability) {
    return supportedCapabilities.contains(capability);
  }
}
