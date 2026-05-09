import '../../../../core/capability.dart';
import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../models/image_models.dart';
import '../../../../providers/google/config.dart';
import 'client.dart';
import 'chat.dart';
import 'embeddings.dart';
import 'images.dart';
import 'tts.dart';

/// Compatibility-first root Google provider shell.
///
/// New shared-capability mainlines should prefer the package-owned modern
/// surfaces in `llm_dart_google` where possible. This root provider remains the
/// migration-era adapter that preserves legacy capability interfaces and the
/// residual Google-specific capability modules still hosted by the root
/// package.
class GoogleProvider
    implements
        ChatCapability,
        EmbeddingCapability,
        ImageGenerationCapability,
        GoogleTTSCapability,
        ProviderCapabilities {
  final GoogleClient _client;
  final GoogleConfig config;

  late final GoogleChat _chat;
  late final GoogleEmbeddings _embeddings;
  late final GoogleImages _images;
  late final GoogleTTS _tts;

  GoogleProvider(this.config) : _client = GoogleClient(config) {
    _chat = GoogleChat(_client, config);
    _embeddings = GoogleEmbeddings(_client, config);
    _images = GoogleImages(_client, config);
    _tts = GoogleTTS(_client, config);
  }

  String get providerName => 'Google';

  bool get _supportsTTS => config.supportsTTS;

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
        if (config.supportsVision) LLMCapability.vision,
        if (config.supportsReasoning) LLMCapability.reasoning,
        if (config.supportsImageGeneration) LLMCapability.imageGeneration,
        if (config.supportsEmbeddings) LLMCapability.embedding,
        if (_supportsTTS) LLMCapability.textToSpeech,
        if (_supportsTTS) LLMCapability.streamingTextToSpeech,
      };

  @override
  bool supports(LLMCapability capability) {
    return supportedCapabilities.contains(capability);
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    TransportCancellation? cancelToken,
  }) async {
    return _chat.chat(messages, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) async {
    return _chat.chatWithTools(messages, tools, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) {
    return _chat.chatStream(messages, tools: tools, cancelToken: cancelToken);
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async {
    return _chat.memoryContents();
  }

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    return _chat.summarizeHistory(messages);
  }

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    TransportCancellation? cancelToken,
  }) async {
    return _embeddings.embed(input, cancelToken: cancelToken);
  }

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
  Future<List<String>> getSupportedLanguages() async {
    return _tts.getSupportedLanguages();
  }
}
