import 'package:llm_dart_core/llm_dart_core.dart';
import 'client.dart';
import 'config.dart';
import 'chat.dart';
import 'embeddings.dart';
import 'audio.dart';
import 'images.dart';
import 'package:llm_dart_openai_compatible/responses.dart';

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
        EmbeddingCapability,
        TextToSpeechCapability,
        VoiceListingCapability,
        SpeechToTextCapability,
        AudioTranslationCapability,
        TranscriptionLanguageListingCapability,
        ImageGenerationCapability,
        ProviderCapabilities {
  final OpenAIClient _client;
  final OpenAIConfig config;

  // Capability modules
  late final OpenAIChat _chat;
  late final OpenAIEmbeddings _embeddings;
  late final OpenAIAudio _audio;
  late final OpenAIImages _images;
  late final OpenAIResponses? _responses;

  OpenAIProvider(this.config) : _client = OpenAIClient(config) {
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

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) async {
    // Use Responses API if enabled, otherwise use Chat Completions API
    if (config.useResponsesAPI && _responses != null) {
      return _responses.chat(messages, cancelToken: cancelToken);
    } else {
      return _chat.chat(messages, cancelToken: cancelToken);
    }
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    // Use Responses API if enabled, otherwise use Chat Completions API
    if (config.useResponsesAPI && _responses != null) {
      return _responses.chatWithTools(messages, tools,
          cancelToken: cancelToken);
    } else {
      return _chat.chatWithTools(messages, tools, cancelToken: cancelToken);
    }
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    // Use Responses API if enabled, otherwise use Chat Completions API
    if (config.useResponsesAPI && _responses != null) {
      return _responses.chatStream(messages,
          tools: tools, cancelToken: cancelToken);
    } else {
      return _chat.chatStream(messages, tools: tools, cancelToken: cancelToken);
    }
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
  Future<List<List<double>>> embed(
    List<String> input, {
    CancelToken? cancelToken,
  }) async {
    return _embeddings.embed(input, cancelToken: cancelToken);
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
  Future<STTResponse> translateAudio(
    AudioTranslationRequest request, {
    CancelToken? cancelToken,
  }) async {
    return _audio.translateAudio(request, cancelToken: cancelToken);
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
