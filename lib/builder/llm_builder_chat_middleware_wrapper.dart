part of 'llm_builder.dart';

/// Internal wrapper that applies chat middlewares while delegating
/// all other capabilities to the underlying provider.
class _MiddlewareWrappedProvider extends BaseAudioCapability
    implements
        ChatCapability,
        EmbeddingCapability,
        ImageGenerationCapability,
        ModelListingCapability,
        FileManagementCapability,
        ModerationCapability,
        AssistantCapability,
        ProviderCapabilities {
  final ChatCapability _chat;
  final dynamic _inner;
  final String _providerId;
  final LLMConfig _config;
  final List<ChatMiddleware> _middlewares;

  _MiddlewareWrappedProvider(
    ChatCapability inner,
    this._providerId,
    this._config,
    List<ChatMiddleware> middlewares,
  )   : _chat = inner,
        _inner = inner,
        _middlewares = middlewares;

  Future<ChatResponse> _executeChatWithMiddlewares(
    ChatCallContext context,
  ) async {
    // Apply transform chain (if any)
    var ctx = context;
    for (final middleware in _middlewares) {
      final transform = middleware.transform;
      if (transform != null) {
        ctx = await transform(ctx);
      }
    }

    // Base chat function
    var next = (ChatCallContext c) => _chat.chat(
          c.messages,
          tools: c.tools,
          options: c.options,
          cancelToken: c.cancelToken,
        );

    // Wrap chat in reverse order
    for (final middleware in _middlewares.reversed) {
      final wrap = middleware.wrapChat;
      if (wrap != null) {
        final currentNext = next;
        next = (c) => wrap(currentNext, c);
      }
    }

    return next(ctx);
  }

  Stream<ChatStreamEvent> _executeStreamWithMiddlewares(
    ChatCallContext context,
  ) async* {
    // Apply transform chain (if any)
    var ctx = context;
    for (final middleware in _middlewares) {
      final transform = middleware.transform;
      if (transform != null) {
        ctx = await transform(ctx);
      }
    }

    // Base stream function
    var next = (ChatCallContext c) => _chat.chatStream(
          c.messages,
          tools: c.tools,
          options: c.options,
          cancelToken: c.cancelToken,
        );

    // Wrap stream in reverse order
    for (final middleware in _middlewares.reversed) {
      final wrap = middleware.wrapStream;
      if (wrap != null) {
        final currentNext = next;
        next = (c) => wrap(currentNext, c);
      }
    }

    yield* next(ctx);
  }

  @override
  Future<ChatResponse> chat(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    final context = ChatCallContext(
      providerId: _providerId,
      model: _config.model,
      config: _config,
      messages: messages,
      tools: tools,
      options: options,
      cancelToken: cancelToken,
      operationKind: ChatOperationKind.chat,
    );
    return _executeChatWithMiddlewares(context);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    final context = ChatCallContext(
      providerId: _providerId,
      model: _config.model,
      config: _config,
      messages: messages,
      tools: tools,
      options: options,
      cancelToken: cancelToken,
      operationKind: ChatOperationKind.stream,
    );
    return _executeStreamWithMiddlewares(context);
  }

  // === AudioCapability delegation ===

  @override
  Set<AudioFeature> get supportedFeatures {
    final inner = _inner;
    if (inner is AudioCapability) {
      return inner.supportedFeatures;
    }
    return const <AudioFeature>{};
  }

  @override
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    CancellationToken? cancelToken,
  }) {
    final inner = _inner;
    if (inner is AudioCapability) {
      return inner.textToSpeech(request, cancelToken: cancelToken);
    }
    throw UnsupportedError(
      'Text-to-speech not supported by provider $_providerId',
    );
  }

  @override
  Stream<AudioStreamEvent> textToSpeechStream(
    TTSRequest request, {
    CancellationToken? cancelToken,
  }) {
    final inner = _inner;
    if (inner is AudioCapability) {
      return inner.textToSpeechStream(request, cancelToken: cancelToken);
    }
    throw UnsupportedError(
      'Streaming text-to-speech not supported by provider $_providerId',
    );
  }

  @override
  Future<List<VoiceInfo>> getVoices() {
    final inner = _inner;
    if (inner is AudioCapability) {
      return inner.getVoices();
    }
    throw UnsupportedError(
        'Voice listing not supported by provider $_providerId');
  }

  @override
  Future<STTResponse> speechToText(
    STTRequest request, {
    CancellationToken? cancelToken,
  }) {
    final inner = _inner;
    if (inner is AudioCapability) {
      return inner.speechToText(request, cancelToken: cancelToken);
    }
    throw UnsupportedError(
      'Speech-to-text not supported by provider $_providerId',
    );
  }

  @override
  Future<STTResponse> translateAudio(
    AudioTranslationRequest request, {
    CancellationToken? cancelToken,
  }) {
    final inner = _inner;
    if (inner is AudioCapability) {
      return inner.translateAudio(request, cancelToken: cancelToken);
    }
    throw UnsupportedError(
      'Audio translation not supported by provider $_providerId',
    );
  }

  @override
  Future<List<LanguageInfo>> getSupportedLanguages() {
    final inner = _inner;
    if (inner is AudioCapability) {
      return inner.getSupportedLanguages();
    }
    throw UnsupportedError(
      'Language listing not supported by provider $_providerId',
    );
  }

  @override
  Future<RealtimeAudioSession> startRealtimeSession(
    RealtimeAudioConfig config,
  ) {
    final inner = _inner;
    if (inner is AudioCapability) {
      return inner.startRealtimeSession(config);
    }
    throw UnsupportedError(
      'Real-time audio not supported by provider $_providerId',
    );
  }

  @override
  List<String> getSupportedAudioFormats() {
    final inner = _inner;
    if (inner is AudioCapability) {
      return inner.getSupportedAudioFormats();
    }
    return const ['mp3', 'wav', 'ogg'];
  }

  // === EmbeddingCapability delegation ===

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancellationToken? cancelToken,
  }) {
    final inner = _inner;
    if (inner is EmbeddingCapability) {
      return inner.embed(input, cancelToken: cancelToken);
    }
    throw UnsupportedError('Embeddings not supported by provider $_providerId');
  }

  // === ImageGenerationCapability delegation ===

  @override
  Future<ImageGenerationResponse> generateImages(
    ImageGenerationRequest request,
  ) {
    final inner = _inner;
    if (inner is ImageGenerationCapability) {
      return inner.generateImages(request);
    }
    throw UnsupportedError(
        'Image generation not supported by provider $_providerId');
  }

  @override
  Future<ImageGenerationResponse> editImage(ImageEditRequest request) {
    final inner = _inner;
    if (inner is ImageGenerationCapability) {
      return inner.editImage(request);
    }
    throw UnsupportedError(
        'Image editing not supported by provider $_providerId');
  }

  @override
  Future<ImageGenerationResponse> createVariation(
    ImageVariationRequest request,
  ) {
    final inner = _inner;
    if (inner is ImageGenerationCapability) {
      return inner.createVariation(request);
    }
    throw UnsupportedError(
      'Image variation not supported by provider $_providerId',
    );
  }

  @override
  List<String> getSupportedSizes() {
    final inner = _inner;
    if (inner is ImageGenerationCapability) {
      return inner.getSupportedSizes();
    }
    return const <String>[];
  }

  @override
  List<String> getSupportedFormats() {
    final inner = _inner;
    if (inner is ImageGenerationCapability) {
      return inner.getSupportedFormats();
    }
    return const <String>[];
  }

  @override
  bool get supportsImageEditing {
    final inner = _inner;
    if (inner is ImageGenerationCapability) {
      return inner.supportsImageEditing;
    }
    return false;
  }

  @override
  bool get supportsImageVariations {
    final inner = _inner;
    if (inner is ImageGenerationCapability) {
      return inner.supportsImageVariations;
    }
    return false;
  }

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
    final inner = _inner;
    if (inner is ImageGenerationCapability) {
      return inner.generateImage(
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
    throw UnsupportedError(
        'Image generation not supported by provider $_providerId');
  }

  // === ModelListingCapability delegation ===

  @override
  Future<List<AIModel>> models({CancellationToken? cancelToken}) {
    final inner = _inner;
    if (inner is ModelListingCapability) {
      return inner.models(cancelToken: cancelToken);
    }
    throw UnsupportedError(
        'Model listing not supported by provider $_providerId');
  }

  // === FileManagementCapability delegation ===

  @override
  Future<FileObject> uploadFile(FileUploadRequest request) {
    final inner = _inner;
    if (inner is FileManagementCapability) {
      return inner.uploadFile(request);
    }
    throw UnsupportedError(
        'File management not supported by provider $_providerId');
  }

  @override
  Future<FileListResponse> listFiles([FileListQuery? query]) {
    final inner = _inner;
    if (inner is FileManagementCapability) {
      return inner.listFiles(query);
    }
    throw UnsupportedError(
        'File management not supported by provider $_providerId');
  }

  @override
  Future<FileObject> retrieveFile(String fileId) {
    final inner = _inner;
    if (inner is FileManagementCapability) {
      return inner.retrieveFile(fileId);
    }
    throw UnsupportedError(
        'File management not supported by provider $_providerId');
  }

  @override
  Future<FileDeleteResponse> deleteFile(String fileId) {
    final inner = _inner;
    if (inner is FileManagementCapability) {
      return inner.deleteFile(fileId);
    }
    throw UnsupportedError(
        'File management not supported by provider $_providerId');
  }

  @override
  Future<List<int>> getFileContent(String fileId) {
    final inner = _inner;
    if (inner is FileManagementCapability) {
      return inner.getFileContent(fileId);
    }
    throw UnsupportedError(
        'File management not supported by provider $_providerId');
  }

  // === ModerationCapability delegation ===

  @override
  Future<ModerationResponse> moderate(ModerationRequest request) {
    final inner = _inner;
    if (inner is ModerationCapability) {
      return inner.moderate(request);
    }
    throw UnsupportedError('Moderation not supported by provider $_providerId');
  }

  // === AssistantCapability delegation ===

  @override
  Future<Assistant> createAssistant(CreateAssistantRequest request) {
    final inner = _inner;
    if (inner is AssistantCapability) {
      return inner.createAssistant(request);
    }
    throw UnsupportedError('Assistants not supported by provider $_providerId');
  }

  @override
  Future<Assistant> retrieveAssistant(String assistantId) {
    final inner = _inner;
    if (inner is AssistantCapability) {
      return inner.retrieveAssistant(assistantId);
    }
    throw UnsupportedError('Assistants not supported by provider $_providerId');
  }

  @override
  Future<Assistant> modifyAssistant(
    String assistantId,
    ModifyAssistantRequest request,
  ) {
    final inner = _inner;
    if (inner is AssistantCapability) {
      return inner.modifyAssistant(assistantId, request);
    }
    throw UnsupportedError('Assistants not supported by provider $_providerId');
  }

  @override
  Future<ListAssistantsResponse> listAssistants([ListAssistantsQuery? query]) {
    final inner = _inner;
    if (inner is AssistantCapability) {
      return inner.listAssistants(query);
    }
    throw UnsupportedError('Assistants not supported by provider $_providerId');
  }

  @override
  Future<DeleteAssistantResponse> deleteAssistant(String assistantId) {
    final inner = _inner;
    if (inner is AssistantCapability) {
      return inner.deleteAssistant(assistantId);
    }
    throw UnsupportedError('Assistants not supported by provider $_providerId');
  }

  // === ProviderCapabilities delegation ===

  @override
  Set<LLMCapability> get supportedCapabilities {
    final inner = _inner;
    if (inner is ProviderCapabilities) {
      return inner.supportedCapabilities;
    }
    return const {LLMCapability.chat, LLMCapability.streaming};
  }

  @override
  bool supports(LLMCapability capability) {
    final inner = _inner;
    if (inner is ProviderCapabilities) {
      return inner.supports(capability);
    }
    return capability == LLMCapability.chat ||
        capability == LLMCapability.streaming;
  }
}

/// Internal wrapper that applies embedding middlewares while delegating
/// all other capabilities to the underlying provider.
class _EmbeddingMiddlewareWrappedProvider
    implements EmbeddingCapability, ProviderCapabilities {
  final EmbeddingCapability _embedding;
  final dynamic _inner;
  final String _providerId;
  final LLMConfig _config;
  final List<EmbeddingMiddleware> _middlewares;

  _EmbeddingMiddlewareWrappedProvider(
    EmbeddingCapability inner,
    this._providerId,
    this._config,
    List<EmbeddingMiddleware> middlewares,
  )   : _embedding = inner,
        _inner = inner,
        _middlewares = middlewares;

  Future<List<List<double>>> _executeEmbedWithMiddlewares(
    EmbeddingCallContext context,
  ) async {
    var ctx = context;
    for (final middleware in _middlewares) {
      final transform = middleware.transform;
      if (transform != null) {
        ctx = await transform(ctx);
      }
    }

    var next = (EmbeddingCallContext c) =>
        _embedding.embed(c.input, cancelToken: c.cancelToken);

    for (final middleware in _middlewares.reversed) {
      final wrap = middleware.wrapEmbed;
      if (wrap != null) {
        final currentNext = next;
        next = (c) => wrap(currentNext, c);
      }
    }

    return next(ctx);
  }

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancellationToken? cancelToken,
  }) {
    final context = EmbeddingCallContext(
      providerId: _providerId,
      model: _config.model,
      config: _config,
      input: input,
      cancelToken: cancelToken,
    );
    return _executeEmbedWithMiddlewares(context);
  }

  @override
  Set<LLMCapability> get supportedCapabilities {
    final inner = _inner;
    if (inner is ProviderCapabilities) {
      return inner.supportedCapabilities;
    }
    return const {LLMCapability.embedding};
  }

  @override
  bool supports(LLMCapability capability) {
    final inner = _inner;
    if (inner is ProviderCapabilities) {
      return inner.supports(capability);
    }
    return capability == LLMCapability.embedding;
  }
}
