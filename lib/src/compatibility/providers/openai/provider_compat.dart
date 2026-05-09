import '../../../../core/capability.dart';
import '../../../../models/chat_models.dart';
import '../../../../models/audio_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../models/image_models.dart';
import '../../../../models/file_models.dart';
import '../../../../models/moderation_models.dart';
import '../../../../providers/openai/config.dart';
import 'assistant_capability.dart';
import 'assistant_models.dart';
import 'assistants.dart';
import 'audio.dart';
import 'chat.dart';
import 'client.dart';
import 'completion.dart';
import 'embeddings.dart';
import 'files.dart';
import 'images.dart';
import 'models.dart';
import 'moderation.dart';
import 'openai_audio_translation_models.dart';
import 'openai_provider_support.dart';
import 'provider_chat_facade.dart';
import 'responses.dart';

/// Compatibility-first root OpenAI provider shell.
///
/// New shared-capability mainlines should prefer the package-owned modern
/// surfaces in `llm_dart_openai` where possible. This root provider remains
/// the migration-era adapter that still hosts residual legacy capability
/// modules and compatibility-facing helper APIs.
class OpenAIProvider
    implements
        ChatCapability,
        EmbeddingCapability,
        AudioCapability,
        ImageGenerationCapability,
        FileManagementCapability,
        ModelListingCapability,
        ModerationCapability,
        AssistantCapability,
        CompletionCapability,
        ProviderCapabilities {
  final OpenAIClient _client;
  final OpenAIConfig config;

  late final OpenAIChat _chat;
  late final OpenAIProviderChatFacade _chatFacade;
  late final OpenAIEmbeddings _embeddings;
  late final OpenAIAudio _audio;
  late final OpenAIImages _images;
  late final OpenAIFiles _files;
  late final OpenAIModels _models;
  late final OpenAIModeration _moderation;
  late final OpenAIAssistants _assistants;
  late final OpenAICompletion _completion;
  late final OpenAIResponses? _responses;
  late final OpenAIProviderSupport _support;

  OpenAIProvider(this.config) : _client = OpenAIClient(config) {
    _chat = OpenAIChat(_client, config);
    _embeddings = OpenAIEmbeddings(_client, config);
    _audio = OpenAIAudio(_client, config);
    _images = OpenAIImages(_client, config);
    _files = OpenAIFiles(_client, config);
    _models = OpenAIModels(_client, config);
    _moderation = OpenAIModeration(_client, config);
    _assistants = OpenAIAssistants(_client, config);
    _completion = OpenAICompletion(_client, config);

    _responses =
        config.useResponsesAPI ? OpenAIResponses(_client, config) : null;

    _chatFacade = OpenAIProviderChatFacade(
      config: config,
      chat: _chat,
      responses: _responses,
    );
    _support = OpenAIProviderSupport(
      config: config,
      client: _client,
      chat: _chat,
      embeddings: _embeddings,
      audio: _audio,
    );
  }

  String get providerName => 'OpenAI';

  OpenAIClient get client => _client;

  OpenAIResponses? get responses => _responses;

  bool get supportsResponsesApi => _responses != null;

  @override
  Set<LLMCapability> get supportedCapabilities =>
      _support.supportedCapabilities;

  @override
  bool supports(LLMCapability capability) {
    return _support.supports(capability);
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    TransportCancellation? cancelToken,
  }) async {
    return _chatFacade.chat(
      messages,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) async {
    return _chatFacade.chatWithTools(
      messages,
      tools,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) {
    return _chatFacade.chatStream(
      messages,
      tools: tools,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async {
    return _chatFacade.memoryContents();
  }

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    return _chatFacade.summarizeHistory(messages);
  }

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    TransportCancellation? cancelToken,
  }) async {
    return _embeddings.embed(input, cancelToken: cancelToken);
  }

  @override
  Set<AudioFeature> get supportedFeatures => _audio.supportedFeatures;

  @override
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    return _audio.textToSpeech(request, cancelToken: cancelToken);
  }

  @override
  Stream<AudioStreamEvent> textToSpeechStream(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) {
    return _audio.textToSpeechStream(request, cancelToken: cancelToken);
  }

  @override
  Future<List<VoiceInfo>> getVoices() async {
    return _audio.getVoices();
  }

  @override
  Future<STTResponse> speechToText(
    STTRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    return _audio.speechToText(request, cancelToken: cancelToken);
  }

  Future<STTResponse> translateAudio(
    AudioTranslationRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    return _audio.translateAudio(request, cancelToken: cancelToken);
  }

  @override
  Future<List<LanguageInfo>> getSupportedLanguages() async {
    return _audio.getSupportedLanguages();
  }

  @override
  Future<RealtimeAudioSession> startRealtimeSession(
    RealtimeAudioConfig config,
  ) async {
    return _audio.startRealtimeSession(config);
  }

  @override
  List<String> getSupportedAudioFormats() {
    return _audio.getSupportedAudioFormats();
  }

  @override
  Future<List<int>> speech(
    String text, {
    TransportCancellation? cancelToken,
  }) async {
    return _support.speech(
      text,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<List<int>> speechStream(String text) {
    return _support.speechStream(text);
  }

  @override
  Future<String> transcribe(List<int> audio) async {
    return _support.transcribe(audio);
  }

  @override
  Future<String> transcribeFile(String filePath) async {
    return _support.transcribeFile(filePath);
  }

  Future<String> translate(List<int> audio) async {
    return _support.translate(audio);
  }

  Future<String> translateFile(String filePath) async {
    return _support.translateFile(filePath);
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
  Future<FileObject> uploadFile(FileUploadRequest request) async {
    return _files.uploadFile(request);
  }

  @override
  Future<FileListResponse> listFiles([FileListQuery? query]) async {
    return _files.listFiles(query);
  }

  @override
  Future<FileObject> retrieveFile(String fileId) async {
    return _files.retrieveFile(fileId);
  }

  @override
  Future<FileDeleteResponse> deleteFile(String fileId) async {
    return _files.deleteFile(fileId);
  }

  @override
  Future<List<int>> getFileContent(String fileId) async {
    return _files.getFileContent(fileId);
  }

  @override
  Future<List<AIModel>> models({TransportCancellation? cancelToken}) async {
    return _models.models(cancelToken: cancelToken);
  }

  @override
  Future<ModerationResponse> moderate(ModerationRequest request) async {
    return _moderation.moderate(request);
  }

  @override
  Future<Assistant> createAssistant(CreateAssistantRequest request) async {
    return _assistants.createAssistant(request);
  }

  @override
  Future<ListAssistantsResponse> listAssistants([
    ListAssistantsQuery? query,
  ]) async {
    return _assistants.listAssistants(query);
  }

  @override
  Future<Assistant> retrieveAssistant(String assistantId) async {
    return _assistants.retrieveAssistant(assistantId);
  }

  @override
  Future<Assistant> modifyAssistant(
    String assistantId,
    ModifyAssistantRequest request,
  ) async {
    return _assistants.modifyAssistant(assistantId, request);
  }

  @override
  Future<DeleteAssistantResponse> deleteAssistant(String assistantId) async {
    return _assistants.deleteAssistant(assistantId);
  }

  @override
  Future<CompletionResponse> complete(CompletionRequest request) async {
    return _completion.complete(request);
  }

  Future<int> getEmbeddingDimensions() async {
    return _support.getEmbeddingDimensions();
  }

  Future<({bool valid, String? error})> checkModel() async {
    return _support.checkModel();
  }

  Future<List<String>> generateSuggestions(List<ChatMessage> messages) async {
    return _support.generateSuggestions(messages);
  }

  @override
  String toString() {
    return 'OpenAIProvider('
        'model: ${config.model}, '
        'baseUrl: ${config.baseUrl}'
        ')';
  }
}
