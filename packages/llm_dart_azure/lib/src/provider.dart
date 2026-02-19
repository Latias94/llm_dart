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
        ChatStreamPartsCapability,
        PromptChatCapability,
        PromptChatStreamPartsCapability,
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
  late final OpenAIStyleImages _images;
  late final OpenAIStyleAudio _audio;

  AzureOpenAIProvider(
    this.config, {
    OpenAIClient? client,
  }) : _client = client ?? OpenAIClient(config) {
    _chat = OpenAIChat(_client, config);
    _embeddings = OpenAIEmbeddings(_client, config);
    _responses = OpenAIResponses(_client, config);
    _images = OpenAIStyleImages(_client, config);
    _audio = OpenAIStyleAudio(_client, config);
  }

  @override
  Set<LLMCapability> get supportedCapabilities {
    final capabilities = <LLMCapability>{
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
    };

    if (config.useResponsesAPI) {
      capabilities.add(LLMCapability.openaiResponses);
    }

    return capabilities;
  }

  @override
  bool supports(LLMCapability capability) =>
      supportedCapabilities.contains(capability);

  void _assertProviderToolsSupported(List<ProviderTool>? providerTools) {
    if (providerTools == null || providerTools.isEmpty) return;
    if (config.useResponsesAPI) return;
    throw UnsupportedCapabilityError(
      'Provider-native tools require the Azure/OpenAI Responses API. '
      'Use providerId "azure" (Responses) instead of "${config.providerId}".',
    );
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) async {
    _assertProviderToolsSupported(providerTools);

    if (config.useResponsesAPI) {
      final response = await _responses.chat(messages,
          providerTools: providerTools, cancelToken: cancelToken);
      return response;
    }

    final response = await _chat.chat(messages, cancelToken: cancelToken);
    return response;
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) async {
    _assertProviderToolsSupported(providerTools);

    if (config.useResponsesAPI) {
      final response = await _responses.chatWithTools(
        messages,
        tools,
        providerTools: providerTools,
        cancelToken: cancelToken,
      );
      return response;
    }

    final response = await _chat.chatWithTools(
      messages,
      tools,
      cancelToken: cancelToken,
    );
    return response;
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    _assertProviderToolsSupported(providerTools);

    if (config.useResponsesAPI) {
      return _responses.chatStreamParts(
        messages,
        providerTools: providerTools,
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
  Future<ChatResponse> chatPrompt(
    Prompt prompt, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async {
    _assertProviderToolsSupported(providerTools);

    if (config.useResponsesAPI) {
      final response = await _responses.chatPrompt(
        prompt,
        providerTools: providerTools,
        tools: tools,
        cancelToken: cancelToken,
      );
      return response;
    }

    final response =
        await _chat.chatPrompt(prompt, tools: tools, cancelToken: cancelToken);
    return response;
  }

  @override
  Stream<LLMStreamPart> chatPromptStreamParts(
    Prompt prompt, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    _assertProviderToolsSupported(providerTools);

    if (config.useResponsesAPI) {
      return _responses.chatPromptStreamParts(
        prompt,
        providerTools: providerTools,
        tools: tools,
        cancelToken: cancelToken,
      );
    }

    return _chat.chatPromptStreamParts(
      prompt,
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
  Future<EmbeddingResponse> embed(
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
  Future<ImageGenerationResponse> createVariation(
      ImageVariationRequest request) {
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
