import 'package:llm_dart_core/llm_dart_core.dart';

import '../assistants/openai_assistants.dart';
import '../audio/openai_audio.dart';
import '../chat/openai_chat.dart';
import '../client/openai_client.dart';
import '../completion/openai_completion.dart';
import '../config/openai_config.dart';
import '../embeddings/openai_embeddings.dart';
import '../files/openai_files.dart';
import '../images/openai_images.dart';
import '../models/openai_models.dart';
import '../moderation/openai_moderation.dart';
import '../responses/openai_responses.dart';

/// OpenAI Provider implementation for the llm_dart_openai subpackage.
///
/// This mirrors the main package's OpenAIProvider but only composes
/// the capabilities that have been migrated into this subpackage
/// (chat, embeddings, audio, images, files, moderation, completion,
/// model listing).
class OpenAIProvider
    implements
        ChatCapability,
        EmbeddingCapability,
        AudioCapability,
        FileManagementCapability,
        ImageGenerationCapability,
        ModelListingCapability,
        ModerationCapability,
        CompletionCapability,
        AssistantCapability,
        ProviderCapabilities {
  final OpenAIClient _client;
  final OpenAIConfig config;

  // Capability modules
  late final OpenAIChat _chat;
  late final OpenAIEmbeddings _embeddings;
  late final OpenAIAudio _audio;
  late final OpenAIFiles _files;
  late final OpenAIImages _images;
  late final OpenAIModels _models;
  late final OpenAIModeration _moderation;
  late final OpenAICompletion _completion;
  late final OpenAIAssistants _assistants;
  late final OpenAIResponses? _responses;

  OpenAIProvider(this.config) : _client = OpenAIClient(config) {
    _chat = OpenAIChat(_client, config);
    _embeddings = OpenAIEmbeddings(_client, config);
    _audio = OpenAIAudio(_client, config);
    _files = OpenAIFiles(_client, config);
    _images = OpenAIImages(_client, config);
    _models = OpenAIModels(_client, config);
    _moderation = OpenAIModeration(_client, config);
    _completion = OpenAICompletion(_client, config);
    _assistants = OpenAIAssistants(_client, config);

    if (config.useResponsesAPI) {
      _responses = OpenAIResponses(_client, config);
    } else {
      _responses = null;
    }
  }

  String get providerName => 'OpenAI';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.embedding,
        LLMCapability.textToSpeech,
        LLMCapability.speechToText,
        LLMCapability.imageGeneration,
        LLMCapability.modelListing,
        LLMCapability.moderation,
        LLMCapability.fileManagement,
        LLMCapability.completion,
        LLMCapability.assistants,
        if (config.useResponsesAPI) LLMCapability.openaiResponses,
      };

  @override
  bool supports(LLMCapability capability) {
    return supportedCapabilities.contains(capability);
  }

  // ===== ChatCapability =====

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) {
    if (config.useResponsesAPI && _responses != null) {
      return _responses!.chat(messages, cancelToken: cancelToken);
    }
    return _chat.chat(messages, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) {
    if (config.useResponsesAPI && _responses != null) {
      return _responses!.chatWithTools(
        messages,
        tools,
        cancelToken: cancelToken,
      );
    }
    return _chat.chatWithTools(messages, tools, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    if (config.useResponsesAPI && _responses != null) {
      return _responses!.chatStream(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      );
    }

    return _chat.chatStream(
      messages,
      tools: tools,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<ChatMessage>?> memoryContents() {
    if (config.useResponsesAPI && _responses != null) {
      return _responses!.memoryContents();
    }
    return _chat.memoryContents();
  }

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) {
    if (config.useResponsesAPI && _responses != null) {
      return _responses!.summarizeHistory(messages);
    }
    return _chat.summarizeHistory(messages);
  }

  // ===== EmbeddingCapability =====

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancelToken? cancelToken,
  }) {
    return _embeddings.embed(input, cancelToken: cancelToken);
  }

  // ===== AudioCapability =====

  @override
  Set<AudioFeature> get supportedFeatures => _audio.supportedFeatures;

  @override
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    CancelToken? cancelToken,
  }) {
    return _audio.textToSpeech(request, cancelToken: cancelToken);
  }

  @override
  Stream<AudioStreamEvent> textToSpeechStream(
    TTSRequest request, {
    CancelToken? cancelToken,
  }) {
    return _audio.textToSpeechStream(request, cancelToken: cancelToken);
  }

  @override
  Future<List<VoiceInfo>> getVoices() {
    return _audio.getVoices();
  }

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

  @override
  Future<RealtimeAudioSession> startRealtimeSession(
    RealtimeAudioConfig config,
  ) {
    return _audio.startRealtimeSession(config);
  }

  @override
  List<String> getSupportedAudioFormats() {
    return _audio.getSupportedAudioFormats();
  }

  // Audio convenience methods

  @override
  Future<List<int>> speech(
    String text, {
    CancelToken? cancelToken,
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

  // ===== FileManagementCapability =====

  @override
  Future<FileObject> uploadFile(FileUploadRequest request) {
    return _files.uploadFile(request);
  }

  @override
  Future<FileListResponse> listFiles([FileListQuery? query]) {
    return _files.listFiles(query);
  }

  @override
  Future<FileObject> retrieveFile(String fileId) {
    return _files.retrieveFile(fileId);
  }

  @override
  Future<FileDeleteResponse> deleteFile(String fileId) {
    return _files.deleteFile(fileId);
  }

  @override
  Future<List<int>> getFileContent(String fileId) {
    return _files.getFileContent(fileId);
  }

  // ===== ModerationCapability =====

  @override
  Future<ModerationResponse> moderate(ModerationRequest request) {
    return _moderation.moderate(request);
  }

  // Convenience helpers (not part of interface but useful).

  Future<ModerationResult> moderateText(String text, {String? model}) {
    return _moderation.moderateText(text, model: model);
  }

  Future<List<ModerationResult>> moderateTexts(
    List<String> texts, {
    String? model,
  }) {
    return _moderation.moderateTexts(texts, model: model);
  }

  Future<bool> isTextSafe(String text, {String? model}) {
    return _moderation.isTextSafe(text, model: model);
  }

  Future<bool> hasUnsafeContent(
    List<String> texts, {
    String? model,
  }) {
    return _moderation.hasUnsafeContent(texts, model: model);
  }

  Future<ModerationAnalysis> analyzeContent(
    String text, {
    String? model,
  }) {
    return _moderation.analyzeContent(text, model: model);
  }

  Future<List<ModerationAnalysis>> analyzeMultipleContents(
    List<String> texts, {
    String? model,
  }) {
    return _moderation.analyzeMultipleContents(texts, model: model);
  }

  Future<List<String>> filterSafeContent(
    List<String> texts, {
    String? model,
  }) {
    return _moderation.filterSafeContent(texts, model: model);
  }

  Future<ModerationStats> getModerationStats(
    List<String> texts, {
    String? model,
  }) {
    return _moderation.getModerationStats(texts, model: model);
  }

  // ===== ImageGenerationCapability =====

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
  Future<ImageGenerationResponse> createVariation(
    ImageVariationRequest request,
  ) {
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

  // ===== ModelListingCapability =====

  @override
  Future<List<AIModel>> models({CancelToken? cancelToken}) {
    return _models.models(cancelToken: cancelToken);
  }

  // ===== CompletionCapability =====

  @override
  Future<CompletionResponse> complete(CompletionRequest request) {
    return _completion.complete(request);
  }

  Stream<String> completeStream(CompletionRequest request) {
    return _completion.completeStream(request);
  }

  Future<List<CompletionResponse>> generateMultiple(
    CompletionRequest request,
    int count,
  ) {
    return _completion.generateMultiple(request, count);
  }

  Future<CompletionResponse> completeWithParams({
    required String prompt,
    String? model,
    int? maxTokens,
    double? temperature,
    double? topP,
    List<String>? stop,
    double? presencePenalty,
    double? frequencyPenalty,
    String? suffix,
    bool echo = false,
  }) {
    return _completion.completeWithParams(
      prompt: prompt,
      model: model,
      maxTokens: maxTokens,
      temperature: temperature,
      topP: topP,
      stop: stop,
      presencePenalty: presencePenalty,
      frequencyPenalty: frequencyPenalty,
      suffix: suffix,
      echo: echo,
    );
  }

  Future<CompletionResponse> completeForUseCase(
    String prompt,
    CompletionUseCase useCase,
  ) {
    return _completion.completeForUseCase(prompt, useCase);
  }

  Future<CompletionResponse> completeWithRetry(
    CompletionRequest request, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) {
    return _completion.completeWithRetry(
      request,
      maxRetries: maxRetries,
      delay: delay,
    );
  }

  Future<List<CompletionResponse>> batchComplete(
    List<String> prompts, {
    String? model,
    int? maxTokens,
    double? temperature,
    int? concurrency = 5,
  }) {
    return _completion.batchComplete(
      prompts,
      model: model,
      maxTokens: maxTokens,
      temperature: temperature,
      concurrency: concurrency,
    );
  }

  int estimateTokenCount(String text) {
    return _completion.estimateTokenCount(text);
  }

  bool isPromptWithinLimits(String prompt, {int? maxTokens}) {
    return _completion.isPromptWithinLimits(prompt, maxTokens: maxTokens);
  }

  String truncatePrompt(String prompt, {int? maxTokens}) {
    return _completion.truncatePrompt(prompt, maxTokens: maxTokens);
  }

  /// Access the OpenAI Responses API module when enabled.
  OpenAIResponses? get responses => _responses;

  /// Get the underlying client for advanced usage.
  OpenAIClient get client => _client;

  /// Get embedding dimensions for the configured model.
  Future<int> getEmbeddingDimensions() {
    return _embeddings.getEmbeddingDimensions();
  }

  // ===== AssistantCapability =====

  @override
  Future<Assistant> createAssistant(CreateAssistantRequest request) {
    return _assistants.createAssistant(request);
  }

  @override
  Future<ListAssistantsResponse> listAssistants(
      [ListAssistantsQuery? query]) {
    return _assistants.listAssistants(query);
  }

  @override
  Future<Assistant> retrieveAssistant(String assistantId) {
    return _assistants.retrieveAssistant(assistantId);
  }

  @override
  Future<Assistant> modifyAssistant(
    String assistantId,
    ModifyAssistantRequest request,
  ) {
    return _assistants.modifyAssistant(assistantId, request);
  }

  @override
  Future<DeleteAssistantResponse> deleteAssistant(String assistantId) {
    return _assistants.deleteAssistant(assistantId);
  }

  @override
  String toString() {
    return 'OpenAIProvider('
        'model: ${config.model}, '
        'baseUrl: ${config.baseUrl}'
        ')';
  }
}
