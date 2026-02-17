import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_openai_compatible/client.dart';

import 'config.dart';
import 'images.dart';
import 'video.dart';

class XAIProvider
    implements
        ChatCapability,
        ModelIdentityCapability,
        ChatStreamPartsCapability,
        ChatStreamPartsCallOptionsCapability,
        PromptChatCapability,
        PromptChatStreamPartsCapability,
        PromptChatStreamPartsCallOptionsCapability,
        ChatCallOptionsCapability,
        PromptChatCallOptionsCapability,
        EmbeddingCapability,
        ImageGenerationCapability,
        ImageGenerationCallOptionsCapability,
        ImageGenerationMaxImagesPerCallCapability,
        ExperimentalVideoGenerationCapability,
        ExperimentalVideoGenerationCallOptionsCapability,
        ExperimentalVideoGenerationMaxVideosPerCallCapability,
        ProviderCapabilities {
  final XAIConfig config;

  final OpenAICompatibleConfig _openAIConfig;
  final OpenAIClient _client;
  late final OpenAICompatibleChatEmbeddingProvider _provider;
  late final XAIImages _images;
  late final XAIVideo _video;

  factory XAIProvider(
    XAIConfig config, {
    OpenAIClient? client,
  }) {
    final openAIConfig = _toOpenAICompatibleConfig(config);
    final effectiveClient = client ?? OpenAIClient(openAIConfig);
    return XAIProvider._(config, openAIConfig, effectiveClient);
  }

  XAIProvider._(
    this.config,
    this._openAIConfig,
    this._client,
  ) {
    _provider = OpenAICompatibleChatEmbeddingProvider(
      _client,
      _openAIConfig,
      supportedCapabilities,
    );
    _images = XAIImages(_client, config);
    _video = XAIVideo(_client, config);
  }

  @override
  String get providerId => _openAIConfig.providerId;

  @override
  String get modelId => _openAIConfig.model;

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) {
    return _provider.chat(
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
  }) {
    return _provider.chatWithTools(
      messages,
      tools,
      providerTools: providerTools,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chatWithToolsWithCallOptions(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    return _provider.chatWithToolsWithCallOptions(
      messages,
      tools,
      providerTools: providerTools,
      callOptions: callOptions,
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
    return _provider.chatStreamParts(
      messages,
      providerTools: providerTools,
      tools: tools,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<LLMStreamPart> chatStreamPartsWithCallOptions(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    List<ProviderTool>? providerTools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    return _provider.chatStreamPartsWithCallOptions(
      messages,
      tools: tools,
      providerTools: providerTools,
      callOptions: callOptions,
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
    return _provider.chatPrompt(
      prompt,
      providerTools: providerTools,
      tools: tools,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chatPromptWithCallOptions(
    Prompt prompt, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    return _provider.chatPromptWithCallOptions(
      prompt,
      providerTools: providerTools,
      tools: tools,
      callOptions: callOptions,
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
    return _provider.chatPromptStreamParts(
      prompt,
      providerTools: providerTools,
      tools: tools,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<LLMStreamPart> chatPromptStreamPartsWithCallOptions(
    Prompt prompt, {
    List<Tool>? tools,
    List<ProviderTool>? providerTools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    return _provider.chatPromptStreamPartsWithCallOptions(
      prompt,
      tools: tools,
      providerTools: providerTools,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<ChatMessage>?> memoryContents() {
    return _provider.memoryContents();
  }

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) {
    return _provider.summarizeHistory(messages);
  }

  @override
  Future<EmbeddingResponse> embed(
    List<String> input, {
    CancelToken? cancelToken,
  }) {
    return _provider.embed(input, cancelToken: cancelToken);
  }

  // ========== ImageGenerationCapability ==========

  @override
  Future<ImageGenerationResponse> generateImages(
    ImageGenerationRequest request,
  ) {
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
  Future<ImageGenerationResponse> editImage(ImageEditRequest request) {
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
  ) {
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

  @override
  List<String> getSupportedSizes() => _images.getSupportedSizes();

  @override
  List<String> getSupportedFormats() => _images.getSupportedFormats();

  @override
  bool get supportsImageEditing => _images.supportsImageEditing;

  @override
  bool get supportsImageVariations => _images.supportsImageVariations;

  @override
  int get maxImagesPerCall => _images.maxImagesPerCall;

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
  int get maxVideosPerCall => _video.maxVideosPerCall;

  String get providerName => 'xAI';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
        LLMCapability.reasoning,
        LLMCapability.liveSearch,
        LLMCapability.embedding,
        LLMCapability.imageGeneration,
        LLMCapability.experimentalVideoGeneration,
        // Intentionally optimistic: do not maintain a model capability matrix.
        LLMCapability.vision,
      };

  @override
  bool supports(LLMCapability capability) {
    return supportedCapabilities.contains(capability);
  }
}

OpenAICompatibleConfig _toOpenAICompatibleConfig(XAIConfig config) {
  final base = config.originalConfig;
  final mergedProviderOptions = <String, Map<String, dynamic>>{
    ...?base?.providerOptions,
    'xai': {
      ...?base?.providerOptions['xai'],
      if (config.jsonSchema != null) 'jsonSchema': config.jsonSchema,
      if (config.embeddingEncodingFormat != null)
        'embeddingEncodingFormat': config.embeddingEncodingFormat,
      if (config.embeddingDimensions != null)
        'embeddingDimensions': config.embeddingDimensions,
      if (config.liveSearch != null) 'liveSearch': config.liveSearch,
      if (config.searchParameters != null)
        'searchParameters': config.searchParameters!.toJson(),
    },
  };

  final llmConfig = LLMConfig(
    apiKey: config.apiKey,
    baseUrl: config.baseUrl,
    model: config.model,
    maxTokens: config.maxTokens,
    temperature: config.temperature,
    systemPrompt: config.systemPrompt ?? base?.systemPrompt,
    timeout: config.timeout ?? base?.timeout,
    topP: config.topP,
    topK: config.topK,
    tools: config.tools ?? base?.tools,
    providerTools: base?.providerTools,
    toolChoice: config.toolChoice ?? base?.toolChoice,
    stopSequences: base?.stopSequences,
    user: base?.user,
    serviceTier: base?.serviceTier,
    transportOptions: base?.transportOptions ?? const {},
    providerOptions: mergedProviderOptions,
  );

  return OpenAICompatibleConfig.fromLLMConfig(
    llmConfig,
    providerId: 'xai',
    providerName: 'xAI',
  );
}
