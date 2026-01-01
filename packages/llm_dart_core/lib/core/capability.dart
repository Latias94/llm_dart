import '../models/chat_models.dart';
import '../models/tool_models.dart';
import '../models/audio_models.dart';
import '../models/image_models.dart';
import '../models/rerank_models.dart';
import '../prompt/prompt.dart';
import 'llm_error.dart';
import 'cancellation.dart';

/// Enumeration of LLM capabilities that providers can support
///
/// This enum provides a high-level categorization of AI provider capabilities
/// for documentation, selection, and informational purposes. Note that:
///
/// - Actual feature support may vary by specific model within the same provider
/// - OpenAI-compatible providers may have different capabilities than declared
/// - Some features are detected at runtime rather than through capability checks
/// - This is primarily for informational and selection purposes
enum LLMCapability {
  /// Basic chat functionality
  chat,

  /// Streaming chat responses
  streaming,

  /// Vector embeddings generation
  embedding,

  /// Reranking (query + documents → ranked results)
  rerank,

  /// Text-to-speech conversion
  textToSpeech,

  /// Streaming text-to-speech conversion
  streamingTextToSpeech,

  /// Speech-to-text conversion
  speechToText,

  /// Audio translation (speech to English text)
  audioTranslation,

  /// Real-time audio processing
  realtimeAudio,

  /// Model listing
  modelListing,

  /// Function/tool calling
  toolCalling,

  /// Reasoning/thinking capabilities
  ///
  /// This indicates the provider/model supports reasoning, but the actual
  /// thinking process output varies significantly between providers:
  ///
  /// - **OpenAI o1/o3 series**: Internal reasoning, no thinking output visible
  /// - **Anthropic Claude**: May output thinking process in responses
  /// - **DeepSeek Reasoner**: Outputs detailed reasoning steps
  /// - **Other providers**: Varies by implementation
  ///
  /// The actual reasoning content is detected at runtime through response
  /// parsing (e.g., `<think>` tags, `thinking` fields) rather than through
  /// this capability declaration.
  reasoning,

  /// Vision/image understanding capabilities
  vision,

  /// Text completion (non-chat)
  completion,

  /// Image generation capabilities
  imageGeneration,

  /// File management capabilities
  fileManagement,

  /// Content moderation capabilities
  moderation,

  /// Assistant capabilities
  assistants,

  /// Live search capabilities (real-time web search)
  ///
  /// This indicates the provider supports real-time web search functionality,
  /// allowing models to access current information from the internet.
  ///
  /// **Supported Providers:**
  /// - **xAI Grok**: Native live search with web and news sources
  /// - **Other providers**: May vary by implementation
  ///
  /// The actual search functionality is configured through provider-specific
  /// search parameters rather than through this capability declaration.
  liveSearch,

  /// OpenAI Responses API capabilities
  ///
  /// This indicates the provider supports OpenAI's stateful Responses API,
  /// which provides advanced features beyond standard chat completions:
  ///
  /// **Key Features:**
  /// - **Stateful conversations**: Automatic conversation history management
  /// - **Background processing**: Asynchronous response generation
  /// - **Response lifecycle**: Get, delete, cancel operations on responses
  /// - **Built-in tools**: Web search, file search, computer use
  /// - **Response chaining**: Continue conversations from previous responses
  ///
  /// **Usage:**
  /// ```dart
  /// if (provider.supports(LLMCapability.openaiResponses)) {
  ///   final openaiProvider = provider as OpenAIProvider;
  ///   final responsesAPI = openaiProvider.responses;
  ///   // Use advanced Responses API features
  /// }
  /// ```
  ///
  /// **Note**: This capability name refers to the *Responses API protocol*
  /// originally introduced by OpenAI. Other providers may implement the same
  /// API surface (e.g. xAI), and LLM Dart may expose it under their provider
  /// ids as best-effort support.
  openaiResponses,
}

/// Response from a chat provider
abstract class ChatResponse {
  /// Get the text content of the response
  String? get text;

  /// Get tool calls from the response
  List<ToolCall>? get toolCalls;

  /// Get thinking/reasoning content (for providers that support it)
  String? get thinking => null;

  /// Get usage information if available
  UsageInfo? get usage => null;

  /// Provider-specific metadata for the response (optional).
  ///
  /// Recommended shape: a provider-id namespaced map, e.g.
  /// `{'anthropic': {'id': 'msg_...', 'model': 'claude-...'}}`.
  Map<String, dynamic>? get providerMetadata => null;
}

/// Optional interface for responses that can provide an exact assistant message
/// that should be persisted into chat history.
///
/// This is important for providers/protocols where the next request needs the
/// *full* assistant content blocks (e.g. reasoning + tool_use blocks) to preserve
/// continuity across multi-step tool calls.
abstract class ChatResponseWithAssistantMessage extends ChatResponse {
  /// A message representing the assistant response, suitable for appending to
  /// the next request's message history.
  ChatMessage get assistantMessage;
}

/// Usage information for API calls
class UsageInfo {
  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;
  final int? reasoningTokens;

  const UsageInfo({
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.reasoningTokens,
  });

  /// Adds two UsageInfo instances together for token usage accumulation
  UsageInfo operator +(UsageInfo other) {
    return UsageInfo(
      promptTokens: (promptTokens ?? 0) + (other.promptTokens ?? 0),
      completionTokens: (completionTokens ?? 0) + (other.completionTokens ?? 0),
      totalTokens: (totalTokens ?? 0) + (other.totalTokens ?? 0),
      reasoningTokens: (reasoningTokens ?? 0) + (other.reasoningTokens ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
        if (promptTokens != null) 'prompt_tokens': promptTokens,
        if (completionTokens != null) 'completion_tokens': completionTokens,
        if (totalTokens != null) 'total_tokens': totalTokens,
        if (reasoningTokens != null) 'reasoning_tokens': reasoningTokens,
      };

  factory UsageInfo.fromJson(Map<String, dynamic> json) => UsageInfo(
        promptTokens: json['prompt_tokens'] as int?,
        completionTokens: json['completion_tokens'] as int?,
        totalTokens: json['total_tokens'] as int?,
        reasoningTokens: json['reasoning_tokens'] as int?,
      );

  @override
  String toString() {
    final parts = <String>[];
    if (promptTokens != null) parts.add('prompt: $promptTokens');
    if (completionTokens != null) parts.add('completion: $completionTokens');
    if (reasoningTokens != null) parts.add('reasoning: $reasoningTokens');
    if (totalTokens != null) parts.add('total: $totalTokens');
    return 'UsageInfo(${parts.join(', ')})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsageInfo &&
          runtimeType == other.runtimeType &&
          promptTokens == other.promptTokens &&
          completionTokens == other.completionTokens &&
          totalTokens == other.totalTokens &&
          reasoningTokens == other.reasoningTokens;

  @override
  int get hashCode =>
      Object.hash(promptTokens, completionTokens, totalTokens, reasoningTokens);
}

/// Core chat capability interface that most LLM providers implement
///
/// **API References:**
/// - OpenAI: https://platform.openai.com/docs/guides/tools
/// - Anthropic: https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/overview
/// - xAI: https://docs.x.ai/docs/guides/function-calling
abstract class ChatCapability {
  /// Sends a chat request to the provider with a sequence of messages.
  ///
  /// [messages] - The conversation history as a list of chat messages
  /// [cancelToken] - Optional token to cancel the request
  ///
  /// Returns the provider's response or throws an LLMError
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) async {
    return chatWithTools(messages, null, cancelToken: cancelToken);
  }

  /// Sends a chat request to the provider with a sequence of messages and tools.
  ///
  /// [messages] - The conversation history as a list of chat messages
  /// [tools] - Optional list of tools to use in the chat
  /// [cancelToken] - Optional token to cancel the request
  ///
  /// Returns the provider's response or throws an LLMError
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  });

  /// Sends a streaming chat request to the provider
  ///
  /// [messages] - The conversation history as a list of chat messages
  /// [tools] - Optional list of tools to use in the chat
  /// [cancelToken] - Optional token to cancel the stream
  ///
  /// Returns a stream of chat events
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  });

  /// Get current memory contents if provider supports memory
  Future<List<ChatMessage>?> memoryContents() async => null;

  /// Summarizes a conversation history into a concise 2-3 sentence summary
  ///
  /// [messages] - The conversation messages to summarize
  ///
  /// Returns a string containing the summary or throws an LLMError
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    final prompt =
        'Summarize in 2-3 sentences:\n${messages.map((m) => '${m.role.name}: ${m.content}').join('\n')}';
    final request = [ChatMessage.user(prompt)];
    final response = await chat(request);
    final text = response.text;
    if (text == null) {
      throw const GenericError('no text in summary response');
    }
    return text;
  }
}

/// Optional capability for providers to accept the `Prompt` IR directly.
///
/// Providers that implement this can preserve part/message structure without
/// forcing `Prompt.toChatMessages()` (which emits one `ChatMessage` per part).
///
/// This mirrors Vercel AI SDK's approach: prompts are compiled to provider
/// wire format as late as possible.
abstract class PromptChatCapability {
  Future<ChatResponse> chatPrompt(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  });

  Stream<ChatStreamEvent> chatPromptStream(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  });
}

/// Stream event for streaming chat responses
sealed class ChatStreamEvent {
  const ChatStreamEvent();
}

/// Text delta event
class TextDeltaEvent extends ChatStreamEvent {
  final String delta;

  const TextDeltaEvent(this.delta);
}

/// Tool call delta event
class ToolCallDeltaEvent extends ChatStreamEvent {
  final ToolCall toolCall;

  const ToolCallDeltaEvent(this.toolCall);
}

/// Completion event
class CompletionEvent extends ChatStreamEvent {
  final ChatResponse response;

  const CompletionEvent(this.response);
}

/// Thinking/reasoning delta event for reasoning models
class ThinkingDeltaEvent extends ChatStreamEvent {
  final String delta;

  const ThinkingDeltaEvent(this.delta);
}

/// Error event
class ErrorEvent extends ChatStreamEvent {
  final LLMError error;

  const ErrorEvent(this.error);
}

/// Completion request for text completion providers
class CompletionRequest {
  final String prompt;
  final int? maxTokens;
  final double? temperature;
  final double? topP;
  final int? topK;
  final List<String>? stop;

  const CompletionRequest({
    required this.prompt,
    this.maxTokens,
    this.temperature,
    this.topP,
    this.topK,
    this.stop,
  });

  Map<String, dynamic> toJson() => {
        'prompt': prompt,
        if (maxTokens != null) 'max_tokens': maxTokens,
        if (temperature != null) 'temperature': temperature,
        if (topP != null) 'top_p': topP,
        if (topK != null) 'top_k': topK,
        if (stop != null) 'stop': stop,
      };
}

/// Completion response from text completion providers
class CompletionResponse {
  final String text;
  final UsageInfo? usage;
  final String? thinking;

  const CompletionResponse({required this.text, this.usage, this.thinking});

  @override
  String toString() => text;
}

/// Capability interface for vector embeddings
abstract class EmbeddingCapability {
  /// Generate embeddings for the given input texts
  ///
  /// [input] - List of strings to generate embeddings for
  /// [cancelToken] - Optional token to cancel the request
  ///
  /// Returns a list of embedding vectors or throws an LLMError
  Future<List<List<double>>> embed(
    List<String> input, {
    CancelToken? cancelToken,
  });
}

/// Capability interface for reranking.
///
/// This models the "standard surface" task:
/// query + documents → ranked results.
abstract class RerankCapability {
  Future<RerankResponse> rerank(
    RerankRequest request, {
    CancelToken? cancelToken,
  });
}

/// Task-specific capability: text-to-speech (TTS).
abstract class TextToSpeechCapability {
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    CancelToken? cancelToken,
  });
}

/// Optional task-specific capability: streaming text-to-speech.
abstract class StreamingTextToSpeechCapability {
  Stream<AudioStreamEvent> textToSpeechStream(
    TTSRequest request, {
    CancelToken? cancelToken,
  });
}

/// Optional task-specific capability: voice listing.
abstract class VoiceListingCapability {
  Future<List<VoiceInfo>> getVoices();
}

/// Task-specific capability: speech-to-text (STT).
abstract class SpeechToTextCapability {
  Future<STTResponse> speechToText(
    STTRequest request, {
    CancelToken? cancelToken,
  });
}

/// Optional task-specific capability: audio translation (typically speech->English).
abstract class AudioTranslationCapability {
  Future<STTResponse> translateAudio(
    AudioTranslationRequest request, {
    CancelToken? cancelToken,
  });
}

/// Optional task-specific capability: transcription language listing.
abstract class TranscriptionLanguageListingCapability {
  Future<List<LanguageInfo>> getSupportedLanguages();
}

/// Optional task-specific capability: real-time audio sessions.
abstract class RealtimeAudioCapability {
  Future<RealtimeAudioSession> startRealtimeSession(RealtimeAudioConfig config);
}

/// Convenience extensions for task-specific audio capabilities.
///
/// These helpers provide "quick path" ergonomics without requiring the
/// legacy all-in-one audio interface.
extension TextToSpeechConvenienceX on TextToSpeechCapability {
  /// Convert plain text to audio bytes using default provider settings.
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
}

extension StreamingTextToSpeechConvenienceX on StreamingTextToSpeechCapability {
  /// Stream audio bytes for the given text using default provider settings.
  Stream<List<int>> speechStream(
    String text, {
    CancelToken? cancelToken,
  }) async* {
    await for (final event in textToSpeechStream(
      TTSRequest(text: text),
      cancelToken: cancelToken,
    )) {
      if (event is AudioDataEvent) {
        yield event.data;
      }
    }
  }
}

extension SpeechToTextConvenienceX on SpeechToTextCapability {
  /// Transcribe raw audio bytes to text using default provider settings.
  Future<String> transcribe(
    List<int> audioData, {
    CancelToken? cancelToken,
  }) async {
    final response = await speechToText(
      STTRequest.fromAudio(audioData),
      cancelToken: cancelToken,
    );
    return response.text;
  }

  /// Transcribe an audio file to text using default provider settings.
  Future<String> transcribeFile(
    String filePath, {
    CancelToken? cancelToken,
  }) async {
    final response = await speechToText(
      STTRequest.fromFile(filePath),
      cancelToken: cancelToken,
    );
    return response.text;
  }
}

extension AudioTranslationConvenienceX on AudioTranslationCapability {
  /// Translate raw audio bytes to English text using default provider settings.
  Future<String> translate(
    List<int> audioData, {
    CancelToken? cancelToken,
  }) async {
    final response = await translateAudio(
      AudioTranslationRequest.fromAudio(audioData),
      cancelToken: cancelToken,
    );
    return response.text;
  }

  /// Translate an audio file to English text using default provider settings.
  Future<String> translateFile(
    String filePath, {
    CancelToken? cancelToken,
  }) async {
    final response = await translateAudio(
      AudioTranslationRequest.fromFile(filePath),
      cancelToken: cancelToken,
    );
    return response.text;
  }
}

/// Configuration for real-time audio sessions
class RealtimeAudioConfig {
  /// Audio input format
  final String? inputFormat;

  /// Audio output format
  final String? outputFormat;

  /// Sample rate for audio processing
  final int? sampleRate;

  /// Enable voice activity detection
  final bool enableVAD;

  /// Enable echo cancellation
  final bool enableEchoCancellation;

  /// Enable noise suppression
  final bool enableNoiseSuppression;

  /// Session timeout in seconds
  final int? timeoutSeconds;

  /// Custom session parameters
  final Map<String, dynamic>? customParams;

  const RealtimeAudioConfig({
    this.inputFormat,
    this.outputFormat,
    this.sampleRate,
    this.enableVAD = true,
    this.enableEchoCancellation = true,
    this.enableNoiseSuppression = true,
    this.timeoutSeconds,
    this.customParams,
  });

  Map<String, dynamic> toJson() => {
        if (inputFormat != null) 'input_format': inputFormat,
        if (outputFormat != null) 'output_format': outputFormat,
        if (sampleRate != null) 'sample_rate': sampleRate,
        'enable_vad': enableVAD,
        'enable_echo_cancellation': enableEchoCancellation,
        'enable_noise_suppression': enableNoiseSuppression,
        if (timeoutSeconds != null) 'timeout_seconds': timeoutSeconds,
        if (customParams != null) 'custom_params': customParams,
      };

  factory RealtimeAudioConfig.fromJson(Map<String, dynamic> json) =>
      RealtimeAudioConfig(
        inputFormat: json['input_format'] as String?,
        outputFormat: json['output_format'] as String?,
        sampleRate: json['sample_rate'] as int?,
        enableVAD: json['enable_vad'] as bool? ?? true,
        enableEchoCancellation:
            json['enable_echo_cancellation'] as bool? ?? true,
        enableNoiseSuppression:
            json['enable_noise_suppression'] as bool? ?? true,
        timeoutSeconds: json['timeout_seconds'] as int?,
        customParams: json['custom_params'] as Map<String, dynamic>?,
      );
}

/// A stateful real-time audio session
abstract class RealtimeAudioSession {
  /// Send audio data to the session
  void sendAudio(List<int> audioData);

  /// Receive events from the session
  Stream<RealtimeAudioEvent> get events;

  /// Close the session gracefully
  Future<void> close();

  /// Check if the session is still active
  bool get isActive;

  /// Session ID for tracking
  String get sessionId;
}

/// Events from real-time audio sessions
abstract class RealtimeAudioEvent {
  /// Timestamp of the event
  final DateTime timestamp;

  const RealtimeAudioEvent({required this.timestamp});
}

/// Real-time transcription event
class RealtimeTranscriptionEvent extends RealtimeAudioEvent {
  /// Transcribed text
  final String text;

  /// Whether this is a final transcription
  final bool isFinal;

  /// Confidence score
  final double? confidence;

  const RealtimeTranscriptionEvent({
    required super.timestamp,
    required this.text,
    required this.isFinal,
    this.confidence,
  });
}

/// Real-time audio response event
class RealtimeAudioResponseEvent extends RealtimeAudioEvent {
  /// Audio response data
  final List<int> audioData;

  /// Whether this is the final chunk
  final bool isFinal;

  const RealtimeAudioResponseEvent({
    required super.timestamp,
    required this.audioData,
    required this.isFinal,
  });
}

/// Real-time session status event
class RealtimeSessionStatusEvent extends RealtimeAudioEvent {
  /// Session status
  final String status;

  /// Additional status information
  final Map<String, dynamic>? details;

  const RealtimeSessionStatusEvent({
    required super.timestamp,
    required this.status,
    this.details,
  });
}

/// Real-time error event
class RealtimeErrorEvent extends RealtimeAudioEvent {
  /// Error message
  final String message;

  /// Error code
  final String? code;

  const RealtimeErrorEvent({
    required super.timestamp,
    required this.message,
    this.code,
  });
}

/// Capability interface for image generation
///
/// Supports image generation, editing, and variation creation across different providers.
/// Reference: https://platform.openai.com/docs/api-reference/images
abstract class ImageGenerationCapability {
  /// Generate images from text prompts
  ///
  /// Creates one or more images based on a text description.
  Future<ImageGenerationResponse> generateImages(
    ImageGenerationRequest request,
  );

  /// Edit an existing image based on a prompt
  ///
  /// Creates an edited or extended image given an original image and a prompt.
  /// The original image must have transparent areas that indicate where to edit.
  Future<ImageGenerationResponse> editImage(
    ImageEditRequest request,
  );

  /// Create variations of an existing image
  ///
  /// Creates variations of a given image without requiring a text prompt.
  Future<ImageGenerationResponse> createVariation(
    ImageVariationRequest request,
  );

  /// Get supported image sizes for this provider
  List<String> getSupportedSizes();

  /// Get supported response formats for this provider
  List<String> getSupportedFormats();

  /// Check if the provider supports image editing
  bool get supportsImageEditing => true;

  /// Check if the provider supports image variations
  bool get supportsImageVariations => true;

  /// Simple image generation (convenience method)
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
    final response = await generateImages(
      ImageGenerationRequest(
        prompt: prompt,
        model: model,
        negativePrompt: negativePrompt,
        size: imageSize,
        count: batchSize,
        seed: seed != null ? int.tryParse(seed) : null,
        steps: numInferenceSteps,
        guidanceScale: guidanceScale,
        enhancePrompt: promptEnhancement,
      ),
    );

    return response.images
        .map((img) => img.url)
        .where((url) => url != null)
        .cast<String>()
        .toList();
  }
}

/// Provider capability declaration interface
///
/// This interface provides a high-level overview of provider capabilities
/// for documentation, selection, and informational purposes.
///
/// **Important Notes:**
///
/// 1. **Model Variations**: Actual feature support may vary by specific model
///    within the same provider (e.g., GPT-4 vs GPT-3.5, Claude Sonnet vs Haiku)
///
/// 2. **OpenAI-Compatible Providers**: Providers using OpenAI-compatible APIs
///    may have different capabilities than what's declared here, as they're
///    accessed through baseUrl/apiKey configuration
///
/// 3. **Runtime Detection**: Some features (like reasoning output format) are
///    detected at runtime through response parsing rather than capability checks
///
/// 4. **Informational Purpose**: This is primarily for provider selection and
///    documentation, not strict runtime validation
///
/// **Usage Examples:**
/// ```dart
/// // Provider selection based on capabilities
/// if (provider.supports(LLMCapability.vision)) {
///   // This provider generally supports vision
/// }
///
/// // But always handle runtime variations gracefully
/// final response = await provider.chat(messagesWithImage);
/// if (response.text != null) {
///   // Process response regardless of capability declaration
/// }
/// ```
abstract class ProviderCapabilities {
  /// Set of capabilities this provider supports
  ///
  /// This represents the general capabilities of the provider, but actual
  /// support may vary by specific model or configuration.
  Set<LLMCapability> get supportedCapabilities;

  /// Check if this provider supports a specific capability
  ///
  /// **Note**: This is a general indication based on provider capabilities.
  /// Actual support may vary by specific model, configuration, or runtime
  /// conditions. Always implement graceful error handling.
  ///
  /// For critical features, consider testing with actual API calls rather
  /// than relying solely on capability declarations.
  bool supports(LLMCapability capability) =>
      supportedCapabilities.contains(capability);
}

/// Basic LLM provider with just chat capability
abstract class BasicLLMProvider
    implements ChatCapability, ProviderCapabilities {}

/// LLM provider with chat and embedding capabilities
abstract class EmbeddingLLMProvider
    implements ChatCapability, EmbeddingCapability, ProviderCapabilities {}

/// Full-featured LLM provider with all common capabilities
abstract class FullLLMProvider
    implements ChatCapability, EmbeddingCapability, ProviderCapabilities {}

/// Tool execution capability for providers that support client-side tool execution
///
/// This capability allows providers to execute tools locally and return results
/// to the model for further processing.
abstract class ToolExecutionCapability {
  /// Execute multiple tools in parallel and return results
  ///
  /// [toolCalls] - List of tool calls to execute
  /// [config] - Optional parallel execution configuration
  ///
  /// Returns a list of tool results
  Future<List<ToolResult>> executeToolsParallel(
    List<ToolCall> toolCalls, {
    ParallelToolConfig? config,
  }) async {
    // Default implementation executes sequentially
    final results = <ToolResult>[];
    final effectiveConfig = config ?? const ParallelToolConfig();

    for (final toolCall in toolCalls) {
      try {
        final result = await executeTool(toolCall);
        results.add(result);
      } catch (e) {
        results.add(ToolResult.error(
          toolCallId: toolCall.id,
          errorMessage: 'Tool execution failed: $e',
        ));
        if (!effectiveConfig.continueOnError) break;
      }
    }
    return results;
  }

  /// Execute a single tool call
  ///
  /// [toolCall] - The tool call to execute
  ///
  /// Returns the tool result
  Future<ToolResult> executeTool(ToolCall toolCall);

  /// Register a tool executor function
  ///
  /// [toolName] - Name of the tool
  /// [executor] - Function that executes the tool
  void registerToolExecutor(
    String toolName,
    Future<ToolResult> Function(ToolCall toolCall) executor,
  );

  /// Get registered tool executors
  Map<String, Future<ToolResult> Function(ToolCall toolCall)> get toolExecutors;
}

/// Enhanced chat capability with advanced tool and output control
///
/// This extends the basic ChatCapability with advanced features like:
/// - Tool choice strategies (auto, required, specific tool, none)
/// - Structured output formats (JSON schema, etc.)
/// - Advanced streaming with tool choice support
///
/// **When to use:**
/// - When you need precise control over tool selection
/// - When you need structured/typed responses
/// - When working with providers that support advanced tool features
///
/// **API References:**
/// - OpenAI: https://platform.openai.com/docs/guides/tools/tool-choice
/// - Anthropic: https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/overview
abstract class EnhancedChatCapability extends ChatCapability {
  /// Sends a chat request with advanced tool and output configuration
  ///
  /// [messages] - The conversation history as a list of chat messages
  /// [tools] - Optional list of tools to use in the chat
  /// [toolChoice] - Optional tool choice strategy (auto, required, specific, none)
  /// [structuredOutput] - Optional structured output format for typed responses
  ///
  /// Returns the provider's response or throws an LLMError
  Future<ChatResponse> chatWithAdvancedTools(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    ToolChoice? toolChoice,
    StructuredOutputFormat? structuredOutput,
  });

  /// Sends a streaming chat request with advanced tool and output configuration
  ///
  /// [messages] - The conversation history as a list of chat messages
  /// [tools] - Optional list of tools to use in the chat
  /// [toolChoice] - Optional tool choice strategy (auto, required, specific, none)
  /// [structuredOutput] - Optional structured output format for typed responses
  ///
  /// Returns a stream of chat events
  Stream<ChatStreamEvent> chatStreamWithAdvancedTools(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    ToolChoice? toolChoice,
    StructuredOutputFormat? structuredOutput,
  });
}
