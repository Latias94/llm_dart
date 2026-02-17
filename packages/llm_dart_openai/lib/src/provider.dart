import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'client.dart';
import 'config.dart';
import 'chat.dart';
import 'embeddings.dart';
import 'audio.dart';
import 'images.dart';
import 'package:llm_dart_openai_compatible/responses.dart';

const String _openaiChatProviderMetadataKey = 'openai.chat';
const String _openaiResponsesProviderMetadataKey = 'openai.responses';

/// OpenAI Provider implementation
///
/// This provider uses a modular architecture inspired by async-openai.
/// Instead of a monolithic class, capabilities are implemented in separate modules
/// and composed together in this main provider class.
///
/// **Benefits of this approach:**
/// - Single Responsibility: Each module handles one capability
/// - Easier Testing: Modules can be tested independently
/// - Better Maintainability: Changes to one capability don't affect others
/// - Cleaner Code: Smaller, focused classes instead of one giant class
/// - Reusability: Modules can be reused across different provider implementations
class OpenAIProvider
    implements
        ChatCapability,
        ChatCallOptionsCapability,
        ChatStreamPartsCapability,
        ChatStreamPartsCallOptionsCapability,
        PromptChatCapability,
        PromptChatCallOptionsCapability,
        PromptChatStreamPartsCapability,
        PromptChatStreamPartsCallOptionsCapability,
        EmbeddingCapability,
        EmbeddingCallOptionsCapability,
        TextToSpeechCapability,
        TextToSpeechCallOptionsCapability,
        VoiceListingCapability,
        SpeechToTextCapability,
        SpeechToTextCallOptionsCapability,
        AudioTranslationCapability,
        AudioTranslationCallOptionsCapability,
        TranscriptionLanguageListingCapability,
        ImageGenerationCapability,
        ImageGenerationCallOptionsCapability,
        ProviderCapabilities {
  final OpenAIClient _client;
  final OpenAIConfig config;

  // Capability modules
  late final OpenAIChat _chat;
  late final OpenAIEmbeddings _embeddings;
  late final OpenAIAudio _audio;
  late final OpenAIImages _images;
  late final OpenAIResponses? _responses;

  OpenAIProvider(
    this.config, {
    OpenAIClient? client,
  }) : _client = client ?? OpenAIClient(config) {
    // Initialize capability modules
    _chat = OpenAIChat(_client, config);
    _embeddings = OpenAIEmbeddings(_client, config);
    _audio = OpenAIAudio(_client, config);
    _images = OpenAIImages(_client, config);

    // Initialize Responses API module if enabled
    if (config.useResponsesAPI) {
      _responses = OpenAIResponses(_client, config);
    } else {
      _responses = null;
    }
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
      LLMCapability.audioTranslation,
      LLMCapability.toolCalling,
      LLMCapability.reasoning,
      LLMCapability.vision,
      LLMCapability.imageGeneration,
    };

    // Add OpenAI Responses API capability if enabled
    if (config.useResponsesAPI) {
      capabilities.add(LLMCapability.openaiResponses);
    }

    return capabilities;
  }

  @override
  bool supports(LLMCapability capability) {
    return supportedCapabilities.contains(capability);
  }

  // ========== ChatCapability (delegated to chat module) ==========

  void _assertProviderToolsSupported(List<ProviderTool>? providerTools) {
    if (providerTools == null || providerTools.isEmpty) return;
    if (config.useResponsesAPI) return;
    throw UnsupportedCapabilityError(
      'Provider-native tools require the OpenAI Responses API. '
      'Use providerId "openai" (Responses) instead of "${config.providerId}".',
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
      final responses = _responses ?? OpenAIResponses(_client, config);
      final response = await responses.chat(
        messages,
        providerTools: providerTools,
        cancelToken: cancelToken,
      );
      return _wrapResponseWithProviderMetadataAlias(
        response,
        baseKey: config.providerId,
        aliasKey: _openaiResponsesProviderMetadataKey,
      );
    }

    final response = await _chat.chat(messages, cancelToken: cancelToken);
    return _wrapResponseWithProviderMetadataAlias(
      response,
      baseKey: config.providerId,
      aliasKey: _openaiChatProviderMetadataKey,
    );
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
      final responses = _responses ?? OpenAIResponses(_client, config);
      final response = await responses.chatWithTools(
        messages,
        tools,
        providerTools: providerTools,
        cancelToken: cancelToken,
      );
      return _wrapResponseWithProviderMetadataAlias(
        response,
        baseKey: config.providerId,
        aliasKey: _openaiResponsesProviderMetadataKey,
      );
    }

    final response = await _chat.chatWithTools(
      messages,
      tools,
      cancelToken: cancelToken,
    );
    return _wrapResponseWithProviderMetadataAlias(
      response,
      baseKey: config.providerId,
      aliasKey: _openaiChatProviderMetadataKey,
    );
  }

  @override
  Future<ChatResponse> chatWithToolsWithCallOptions(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async {
    _assertProviderToolsSupported(providerTools);

    if (config.useResponsesAPI) {
      final responses = _responses ?? OpenAIResponses(_client, config);
      final response = await responses.chatWithToolsWithCallOptions(
        messages,
        tools,
        providerTools: providerTools,
        callOptions: callOptions,
        cancelToken: cancelToken,
      );
      return _wrapResponseWithProviderMetadataAlias(
        response,
        baseKey: config.providerId,
        aliasKey: _openaiResponsesProviderMetadataKey,
      );
    } else {
      final response = await _chat.chatWithToolsWithCallOptions(
        messages,
        tools,
        callOptions: callOptions,
        cancelToken: cancelToken,
      );
      return _wrapResponseWithProviderMetadataAlias(
        response,
        baseKey: config.providerId,
        aliasKey: _openaiChatProviderMetadataKey,
      );
    }
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
      final responses = _responses ?? OpenAIResponses(_client, config);
      return wrapStreamPartsWithProviderMetadataAlias(
        responses.chatStreamParts(
          messages,
          providerTools: providerTools,
          tools: tools,
          cancelToken: cancelToken,
        ),
        baseKey: config.providerId,
        aliasKey: _openaiResponsesProviderMetadataKey,
      );
    }

    return wrapStreamPartsWithProviderMetadataAlias(
      _chat.chatStreamParts(messages, tools: tools, cancelToken: cancelToken),
      baseKey: config.providerId,
      aliasKey: _openaiChatProviderMetadataKey,
    );
  }

  @override
  Stream<LLMStreamPart> chatStreamPartsWithCallOptions(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    final shouldUseResponses =
        (providerTools != null && providerTools.isNotEmpty) ||
            (config.useResponsesAPI && _responses != null);

    if (shouldUseResponses) {
      final responses = _responses ?? OpenAIResponses(_client, config);
      return wrapStreamPartsWithProviderMetadataAlias(
        responses.chatStreamPartsWithCallOptions(
          messages,
          providerTools: providerTools,
          tools: tools,
          callOptions: callOptions,
          cancelToken: cancelToken,
        ),
        baseKey: config.providerId,
        aliasKey: _openaiResponsesProviderMetadataKey,
      );
    }

    return wrapStreamPartsWithProviderMetadataAlias(
      _chat.chatStreamPartsWithCallOptions(
        messages,
        tools: tools,
        callOptions: callOptions,
        cancelToken: cancelToken,
      ),
      baseKey: config.providerId,
      aliasKey: _openaiChatProviderMetadataKey,
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
      final responses = _responses ?? OpenAIResponses(_client, config);
      final response = await responses.chatPrompt(
        prompt,
        providerTools: providerTools,
        tools: tools,
        cancelToken: cancelToken,
      );
      return _wrapResponseWithProviderMetadataAlias(
        response,
        baseKey: config.providerId,
        aliasKey: _openaiResponsesProviderMetadataKey,
      );
    }

    final response =
        await _chat.chatPrompt(prompt, tools: tools, cancelToken: cancelToken);
    return _wrapResponseWithProviderMetadataAlias(
      response,
      baseKey: config.providerId,
      aliasKey: _openaiChatProviderMetadataKey,
    );
  }

  @override
  Future<ChatResponse> chatPromptWithCallOptions(
    Prompt prompt, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async {
    _assertProviderToolsSupported(providerTools);

    if (config.useResponsesAPI) {
      final responses = _responses ?? OpenAIResponses(_client, config);
      final response = await responses.chatPromptWithCallOptions(
        prompt,
        tools: tools,
        providerTools: providerTools,
        callOptions: callOptions,
        cancelToken: cancelToken,
      );
      return _wrapResponseWithProviderMetadataAlias(
        response,
        baseKey: config.providerId,
        aliasKey: _openaiResponsesProviderMetadataKey,
      );
    }

    final response = await _chat.chatPromptWithCallOptions(
      prompt,
      tools: tools,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
    return _wrapResponseWithProviderMetadataAlias(
      response,
      baseKey: config.providerId,
      aliasKey: _openaiChatProviderMetadataKey,
    );
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
      final responses = _responses ?? OpenAIResponses(_client, config);
      return wrapStreamPartsWithProviderMetadataAlias(
        responses.chatPromptStreamParts(
          prompt,
          providerTools: providerTools,
          tools: tools,
          cancelToken: cancelToken,
        ),
        baseKey: config.providerId,
        aliasKey: _openaiResponsesProviderMetadataKey,
      );
    }

    return wrapStreamPartsWithProviderMetadataAlias(
      _chat.chatPromptStreamParts(
        prompt,
        tools: tools,
        cancelToken: cancelToken,
      ),
      baseKey: config.providerId,
      aliasKey: _openaiChatProviderMetadataKey,
    );
  }

  @override
  Stream<LLMStreamPart> chatPromptStreamPartsWithCallOptions(
    Prompt prompt, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    _assertProviderToolsSupported(providerTools);

    if (config.useResponsesAPI) {
      final responses = _responses ?? OpenAIResponses(_client, config);
      return wrapStreamPartsWithProviderMetadataAlias(
        responses.chatPromptStreamPartsWithCallOptions(
          prompt,
          providerTools: providerTools,
          tools: tools,
          callOptions: callOptions,
          cancelToken: cancelToken,
        ),
        baseKey: config.providerId,
        aliasKey: _openaiResponsesProviderMetadataKey,
      );
    }

    return wrapStreamPartsWithProviderMetadataAlias(
      _chat.chatPromptStreamPartsWithCallOptions(
        prompt,
        tools: tools,
        callOptions: callOptions,
        cancelToken: cancelToken,
      ),
      baseKey: config.providerId,
      aliasKey: _openaiChatProviderMetadataKey,
    );
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async {
    // Use Responses API if enabled, otherwise use Chat Completions API
    if (config.useResponsesAPI && _responses != null) {
      return _responses.memoryContents();
    } else {
      return _chat.memoryContents();
    }
  }

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    // Use Responses API if enabled, otherwise use Chat Completions API
    if (config.useResponsesAPI && _responses != null) {
      return _responses.summarizeHistory(messages);
    } else {
      return _chat.summarizeHistory(messages);
    }
  }

  // ========== EmbeddingCapability (delegated to embeddings module) ==========

  @override
  Future<EmbeddingResponse> embed(
    List<String> input, {
    CancelToken? cancelToken,
  }) async {
    return _embeddings.embed(input, cancelToken: cancelToken);
  }

  @override
  Future<EmbeddingResponse> embedWithCallOptions(
    List<String> input, {
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    if (_embeddings is! EmbeddingCallOptionsCapability) {
      throw const InvalidRequestError(
        'This provider does not support call-level overrides (headers/body) for embeddings.',
      );
    }

    return (_embeddings as EmbeddingCallOptionsCapability).embedWithCallOptions(
      input,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  // ========== Audio capabilities (delegated to audio module) ==========

  @override
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    CancelToken? cancelToken,
  }) async {
    return _audio.textToSpeech(request, cancelToken: cancelToken);
  }

  @override
  Future<TTSResponse> textToSpeechWithCallOptions(
    TTSRequest request, {
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    if (_audio is! TextToSpeechCallOptionsCapability) {
      throw const InvalidRequestError(
        'This provider does not support call-level overrides (headers/body) for text-to-speech.',
      );
    }

    return (_audio as TextToSpeechCallOptionsCapability)
        .textToSpeechWithCallOptions(
      request,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<VoiceInfo>> getVoices() async {
    return _audio.getVoices();
  }

  @override
  Future<STTResponse> speechToText(
    STTRequest request, {
    CancelToken? cancelToken,
  }) async {
    return _audio.speechToText(request, cancelToken: cancelToken);
  }

  @override
  Future<STTResponse> speechToTextWithCallOptions(
    STTRequest request, {
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    if (_audio is! SpeechToTextCallOptionsCapability) {
      throw const InvalidRequestError(
        'This provider does not support call-level overrides (headers/body) for transcription.',
      );
    }

    return (_audio as SpeechToTextCallOptionsCapability)
        .speechToTextWithCallOptions(
      request,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<STTResponse> translateAudio(
    AudioTranslationRequest request, {
    CancelToken? cancelToken,
  }) async {
    return _audio.translateAudio(request, cancelToken: cancelToken);
  }

  @override
  Future<STTResponse> translateAudioWithCallOptions(
    AudioTranslationRequest request, {
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    if (_audio is! AudioTranslationCallOptionsCapability) {
      throw const InvalidRequestError(
        'This provider does not support call-level overrides (headers/body) for audio translation.',
      );
    }

    return (_audio as AudioTranslationCallOptionsCapability)
        .translateAudioWithCallOptions(
      request,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<LanguageInfo>> getSupportedLanguages() async {
    return _audio.getSupportedLanguages();
  }

  // ========== ImageGenerationCapability (delegated to images module) ==========

  @override
  Future<ImageGenerationResponse> generateImages(
      ImageGenerationRequest request) async {
    return _images.generateImages(request);
  }

  @override
  Future<ImageGenerationResponse> generateImagesWithCallOptions(
    ImageGenerationRequest request, {
    required LLMCallOptions callOptions,
  }) {
    if (_images is! ImageGenerationCallOptionsCapability) {
      throw const InvalidRequestError(
        'This provider does not support call-level overrides (headers/body) for image generation.',
      );
    }

    return (_images as ImageGenerationCallOptionsCapability)
        .generateImagesWithCallOptions(
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
    if (_images is! ImageGenerationCallOptionsCapability) {
      throw const InvalidRequestError(
        'This provider does not support call-level overrides (headers/body) for image generation.',
      );
    }

    return (_images as ImageGenerationCallOptionsCapability)
        .editImageWithCallOptions(
      request,
      callOptions: callOptions,
    );
  }

  @override
  Future<ImageGenerationResponse> createVariation(
      ImageVariationRequest request) async {
    return _images.createVariation(request);
  }

  @override
  Future<ImageGenerationResponse> createVariationWithCallOptions(
    ImageVariationRequest request, {
    required LLMCallOptions callOptions,
  }) {
    if (_images is! ImageGenerationCallOptionsCapability) {
      throw const InvalidRequestError(
        'This provider does not support call-level overrides (headers/body) for image generation.',
      );
    }

    return (_images as ImageGenerationCallOptionsCapability)
        .createVariationWithCallOptions(
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

  /// Get embedding dimensions for the configured model
  Future<int> getEmbeddingDimensions() async {
    return _embeddings.getEmbeddingDimensions();
  }

  /// Check if a model is valid and accessible
  Future<({bool valid, String? error})> checkModel() async {
    try {
      final requestBody = {
        'model': config.model,
        'messages': [
          {'role': 'user', 'content': 'hi'}
        ],
        'stream': false,
        'max_tokens': 1, // Minimal tokens to reduce cost
      };

      await _client.postJson('chat/completions', requestBody);
      return (valid: true, error: null);
    } catch (e) {
      return (valid: false, error: e.toString());
    }
  }

  /// Generate suggestions for follow-up questions
  ///
  /// This method uses the standard chat API with a specialized prompt to generate
  /// relevant follow-up questions based on the conversation history.
  /// This is a common pattern used by many chatbot implementations.
  Future<List<String>> generateSuggestions(List<ChatMessage> messages) async {
    try {
      // Don't generate suggestions for empty conversations
      if (messages.isEmpty) {
        return [];
      }

      // Build conversation context (limit to recent messages to avoid token limits)
      final recentMessages = messages.length > 10
          ? messages.sublist(messages.length - 10)
          : messages;

      final conversationContext =
          recentMessages.map((m) => '${m.role.name}: ${m.content}').join('\n');

      final systemPrompt = '''
You are a helpful assistant that generates relevant follow-up questions based on conversation history.

Rules:
1. Generate 3-5 questions that naturally continue the conversation
2. Questions should be specific and actionable
3. Avoid repeating topics already covered
4. Return only the questions, one per line
5. No numbering, bullets, or extra formatting
6. Keep questions concise and clear
''';

      final userPrompt = '''
Based on this conversation, suggest follow-up questions:

$conversationContext
''';

      final response = await _chat.chatWithTools(
          [ChatMessage.system(systemPrompt), ChatMessage.user(userPrompt)],
          null);

      return _parseQuestions(response.text ?? '');
    } catch (e) {
      // Suggestions are optional, so we log the error but don't throw
      _client.logger.warning('Failed to generate suggestions: $e');
      return [];
    }
  }

  /// Parse questions from LLM response text
  List<String> _parseQuestions(String responseText) {
    return responseText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && line.contains('?'))
        .map((line) {
          // Remove common prefixes like "1.", "- ", "• ", etc.
          return line.replaceAll(RegExp(r'^[\d\-•\*\s]*'), '').trim();
        })
        .where((question) => question.isNotEmpty)
        .take(5) // Limit to 5 questions max
        .toList();
  }

  @override
  String toString() {
    return 'OpenAIProvider('
        'model: ${config.model}, '
        'baseUrl: ${config.baseUrl}'
        ')';
  }
}

ChatResponse _wrapResponseWithProviderMetadataAlias(
  ChatResponse response, {
  required String baseKey,
  required String aliasKey,
}) {
  return wrapChatResponseWithProviderMetadataAlias(
    response,
    baseKey: baseKey,
    aliasKey: aliasKey,
  );
}
