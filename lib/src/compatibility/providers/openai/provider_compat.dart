import '../../../../core/capability.dart';
import '../../../../models/chat_models.dart';
import '../../../../models/audio_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../models/image_models.dart';
import '../../../../models/file_models.dart';
import '../../../../models/moderation_models.dart';
import '../../../../models/assistant_models.dart';
import 'client.dart';
import '../../../../providers/openai/config.dart';
import 'chat.dart';
import 'embeddings.dart';
import 'audio.dart';
import 'images.dart';
import 'files.dart';
import 'models.dart';
import 'moderation.dart';
import 'assistants.dart';
import 'completion.dart';
import 'openai_provider_support.dart';
import 'responses.dart';
import 'provider_chat_facade.dart';

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

  // Capability modules
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
    // Initialize capability modules
    _chat = OpenAIChat(_client, config);
    _embeddings = OpenAIEmbeddings(_client, config);
    _audio = OpenAIAudio(_client, config);
    _images = OpenAIImages(_client, config);
    _files = OpenAIFiles(_client, config);
    _models = OpenAIModels(_client, config);
    _moderation = OpenAIModeration(_client, config);
    _assistants = OpenAIAssistants(_client, config);
    _completion = OpenAICompletion(_client, config);

    // Initialize Responses API module if enabled
    if (config.useResponsesAPI) {
      _responses = OpenAIResponses(_client, config);
    } else {
      _responses = null;
    }

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
    );
  }

  String get providerName => 'OpenAI';

  // ========== ProviderCapabilities ==========

  @override
  Set<LLMCapability> get supportedCapabilities {
    final capabilities = {
      LLMCapability.chat,
      LLMCapability.streaming,
      LLMCapability.embedding,
      LLMCapability.textToSpeech,
      LLMCapability.speechToText,
      LLMCapability.toolCalling,
      LLMCapability.reasoning,
      LLMCapability.vision,
      LLMCapability.imageGeneration,
      LLMCapability.fileManagement,
      LLMCapability.moderation,
      LLMCapability.assistants,
      LLMCapability.completion,
      LLMCapability.modelListing,
    };

    // Add OpenAI Responses API capability if enabled
    if (_responses != null) {
      capabilities.add(LLMCapability.openaiResponses);
    }

    return capabilities;
  }

  @override
  bool supports(LLMCapability capability) {
    return supportedCapabilities.contains(capability);
  }

  // ========== ChatCapability (delegated to chat module) ==========

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

  // ========== EmbeddingCapability (delegated to embeddings module) ==========

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    TransportCancellation? cancelToken,
  }) async {
    return _embeddings.embed(input, cancelToken: cancelToken);
  }

  // ========== AudioCapability (delegated to audio module) ==========

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

  @override
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
      RealtimeAudioConfig config) async {
    return _audio.startRealtimeSession(config);
  }

  @override
  List<String> getSupportedAudioFormats() {
    return _audio.getSupportedAudioFormats();
  }

  // AudioCapability convenience methods implementation
  @override
  Future<List<int>> speech(
    String text, {
    TransportCancellation? cancelToken,
  }) async {
    final response = await textToSpeech(
      TTSRequest(text: text),
      cancelToken: cancelToken,
    );
    return response.audioData;
  }

  @override
  Stream<List<int>> speechStream(String text) async* {
    await for (final event in textToSpeechStream(TTSRequest(text: text))) {
      if (event is AudioDataEvent) {
        yield event.data;
      }
    }
  }

  @override
  Future<String> transcribe(List<int> audio) async {
    final response = await speechToText(STTRequest.fromAudio(audio));
    return response.text;
  }

  @override
  Future<String> transcribeFile(String filePath) async {
    final response = await speechToText(STTRequest.fromFile(filePath));
    return response.text;
  }

  @override
  Future<String> translate(List<int> audio) async {
    final response =
        await translateAudio(AudioTranslationRequest.fromAudio(audio));
    return response.text;
  }

  @override
  Future<String> translateFile(String filePath) async {
    final response =
        await translateAudio(AudioTranslationRequest.fromFile(filePath));
    return response.text;
  }

  // ========== ImageGenerationCapability (delegated to images module) ==========

  @override
  Future<ImageGenerationResponse> generateImages(
      ImageGenerationRequest request) async {
    return _images.generateImages(request);
  }

  @override
  Future<ImageGenerationResponse> editImage(ImageEditRequest request) async {
    return _images.editImage(request);
  }

  @override
  Future<ImageGenerationResponse> createVariation(
      ImageVariationRequest request) async {
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

  // ========== FileManagementCapability (delegated to files module) ==========

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

  // ========== ModelListingCapability (delegated to models module) ==========

  @override
  Future<List<AIModel>> models({TransportCancellation? cancelToken}) async {
    return _models.models(cancelToken: cancelToken);
  }

  // ========== ModerationCapability (delegated to moderation module) ==========

  @override
  Future<ModerationResponse> moderate(ModerationRequest request) async {
    return _moderation.moderate(request);
  }

  // ========== AssistantCapability (delegated to assistants module) ==========

  @override
  Future<Assistant> createAssistant(CreateAssistantRequest request) async {
    return _assistants.createAssistant(request);
  }

  @override
  Future<ListAssistantsResponse> listAssistants(
      [ListAssistantsQuery? query]) async {
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

  // ========== CompletionCapability (delegated to completion module) ==========

  @override
  Future<CompletionResponse> complete(CompletionRequest request) async {
    return _completion.complete(request);
  }

  // ========== Additional Helper Methods ==========

  /// Get the underlying client for advanced usage
  OpenAIClient get client => _client;

  /// Get the Responses API module (only available when useResponsesAPI is enabled)
  OpenAIResponses? get responses => _responses;

  /// Get embedding dimensions for the configured model
  Future<int> getEmbeddingDimensions() async {
    return _support.getEmbeddingDimensions();
  }

  /// Check if a model is valid and accessible
  Future<({bool valid, String? error})> checkModel() async {
    return _support.checkModel();
  }

  /// Generate suggestions for follow-up questions
  ///
  /// This method uses the standard chat API with a specialized prompt to generate
  /// relevant follow-up questions based on the conversation history.
  /// This is a common pattern used by many chatbot implementations.
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
