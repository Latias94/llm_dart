import 'dart:convert';

import '../models/chat_models.dart';
import '../models/tool_models.dart';
import '../models/audio_models.dart';
import '../models/image_models.dart';
import '../models/file_models.dart';
import '../models/moderation_models.dart';
import '../models/assistant_models.dart';
import 'llm_error.dart';
import 'cancellation.dart';
import 'config.dart';

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
  /// **Note**: This is currently OpenAI-specific as other providers don't
  /// yet support similar stateful conversation APIs.
  openaiResponses,
}

/// Warning information for an LLM call.
///
/// This is used to surface non-fatal issues to callers in a structured way,
/// such as:
/// - Unsupported parameters for a given model
/// - Parameters that were accepted but had no effect
/// - Provider-specific downgrades or fallbacks
class CallWarning {
  /// Machine-readable warning code.
  ///
  /// Examples:
  /// - `UNSUPPORTED_PARAMETER`
  /// - `PARAMETER_NO_EFFECT`
  /// - `PROVIDER_FALLBACK`
  final String code;

  /// Human-readable warning message.
  final String message;

  /// Optional provider-specific details for debugging or telemetry.
  final Map<String, dynamic>? details;

  const CallWarning({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'CallWarning(code: $code, message: $message)';
}

/// Audio features that providers can support
enum AudioFeature {
  /// Basic text-to-speech conversion
  textToSpeech,

  /// Streaming text-to-speech conversion
  streamingTTS,

  /// Basic speech-to-text conversion
  speechToText,

  /// Audio translation (speech to English text)
  audioTranslation,

  /// Real-time audio processing
  realtimeProcessing,

  /// Speaker diarization (identifying different speakers)
  speakerDiarization,

  /// Character-level timing information
  characterTiming,

  /// Audio event detection (laughter, applause, etc.)
  audioEventDetection,

  /// Voice cloning capabilities
  voiceCloning,

  /// Audio enhancement and noise reduction
  audioEnhancement,

  /// Multi-modal audio-visual processing
  multimodalAudio,
}

/// Structured metadata for a single model call.
///
/// This provides a typed view over the loosely-typed [ChatResponse.metadata]
/// map so that callers can rely on common fields like [provider] and [model]
/// while still allowing providers to attach arbitrary, provider-specific
/// information via [providerMetadata].
class CallMetadata {
  /// Logical provider identifier (e.g. `openai`, `anthropic`, `deepseek`).
  final String? provider;

  /// Provider-specific model identifier (e.g. `gpt-4o`, `claude-3.7-sonnet`).
  final String? model;

  /// Additional provider-specific metadata.
  ///
  /// Examples:
  /// - Reasoning flags (`hasThinking`, `reasonerModel`, ...)
  /// - Safety or moderation summaries
  /// - Provider-specific feature toggles
  final Map<String, dynamic>? providerMetadata;

  /// Optional request information for telemetry/debugging.
  ///
  /// This should contain only non-sensitive, redacted information such as
  /// high-level request shape or size, never raw API keys or full payloads.
  final Map<String, dynamic>? request;

  /// Optional response information for telemetry/debugging.
  ///
  /// This can include high-level response characteristics such as HTTP
  /// status code, selected headers, or a redacted body summary.
  final Map<String, dynamic>? response;

  const CallMetadata({
    this.provider,
    this.model,
    this.providerMetadata,
    this.request,
    this.response,
  });

  /// Convert this metadata back to a JSON-serializable map.
  ///
  /// This is intentionally compatible with [ChatResponse.metadata] so that
  /// existing call sites that rely on a loose map can continue to work.
  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{};

    if (provider != null) result['provider'] = provider;
    if (model != null) result['model'] = model;
    if (request != null) result['request'] = request;
    if (response != null) result['response'] = response;

    if (providerMetadata != null) {
      result.addAll(providerMetadata!);
    }

    return result;
  }

  /// Build [CallMetadata] from a loosely-typed metadata map.
  ///
  /// The following keys are interpreted specially if present:
  /// - `provider` → [provider]
  /// - `model` → [model]
  /// - `request` → [request] (must be a Map)
  /// - `response` → [response] (must be a Map)
  ///
  /// All remaining top-level keys are treated as [providerMetadata].
  factory CallMetadata.fromJson(Map<String, dynamic> json) {
    final provider = json['provider'] as String?;
    final model = json['model'] as String?;

    final rawRequest = json['request'];
    final rawResponse = json['response'];

    Map<String, dynamic>? request;
    if (rawRequest is Map<String, dynamic>) {
      request = rawRequest;
    } else if (rawRequest is Map) {
      request = Map<String, dynamic>.from(rawRequest);
    }

    Map<String, dynamic>? response;
    if (rawResponse is Map<String, dynamic>) {
      response = rawResponse;
    } else if (rawResponse is Map) {
      response = Map<String, dynamic>.from(rawResponse);
    }

    final providerMetadata = <String, dynamic>{};
    json.forEach((key, value) {
      if (key == 'provider' ||
          key == 'model' ||
          key == 'request' ||
          key == 'response') {
        return;
      }
      providerMetadata[key] = value;
    });

    return CallMetadata(
      provider: provider,
      model: model,
      providerMetadata: providerMetadata.isEmpty
          ? null
          : Map<String, dynamic>.from(providerMetadata),
      request: request,
      response: response,
    );
  }
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

  /// Non-fatal warnings for this call (if any).
  ///
  /// Examples include:
  /// - Unsupported parameters that were ignored
  /// - Parameters that were accepted but had no effect
  /// - Provider-specific fallbacks or degradations
  ///
  /// By default, responses have no warnings.
  List<CallWarning> get warnings => const [];

  /// Provider-specific metadata for this call, if available.
  ///
  /// This can include safe debugging/observability information such as:
  /// - Provider identifier
  /// - Model identifier
  /// - High-level request/response characteristics (never raw API keys)
  ///
  /// By default, responses do not expose metadata.
  Map<String, dynamic>? get metadata => null;

  /// Strongly-typed view over [metadata] for observability use cases.
  ///
  /// Implementations that already populate [metadata] automatically get
  /// a best-effort [CallMetadata] instance based on that map. Providers
  /// that want more control can override this getter explicitly.
  CallMetadata? get callMetadata {
    final data = metadata;
    if (data == null) return null;
    return CallMetadata.fromJson(data);
  }
}

/// High-level result for text generation helpers.
///
/// This provides a provider-agnostic view over a [ChatResponse] for
/// typical text use cases while still exposing the full underlying
/// response for advanced scenarios.
class GenerateTextResult {
  /// The main text content returned by the model, if any.
  final String? text;

  /// Optional reasoning/thinking content for providers that support it.
  final String? thinking;

  /// Tool calls requested by the model, if any.
  final List<ToolCall>? toolCalls;

  /// Usage information for this call (tokens, etc.), if available.
  final UsageInfo? usage;

  /// Non-fatal warnings attached to this call.
  final List<CallWarning> warnings;

  /// Structured metadata about the call for observability.
  final CallMetadata? metadata;

  /// The underlying raw [ChatResponse] returned by the provider.
  final ChatResponse rawResponse;

  const GenerateTextResult({
    required this.rawResponse,
    this.text,
    this.thinking,
    this.toolCalls,
    this.usage,
    this.warnings = const [],
    this.metadata,
  });

  /// Convenience flag indicating whether reasoning content is present.
  bool get hasThinking => thinking != null && thinking!.trim().isNotEmpty;
}

/// High-level result for structured object generation helpers.
///
/// This combines a strongly-typed [object] parsed from the model's
/// JSON output with the underlying [GenerateTextResult] used to
/// produce it.
class GenerateObjectResult<T> {
  /// Parsed structured object produced by the model.
  final T object;

  /// Underlying text generation result used to produce [object].
  final GenerateTextResult textResult;

  const GenerateObjectResult({
    required this.object,
    required this.textResult,
  });
}

/// Output specification combining JSON schema and a parser.
///
/// This abstraction mirrors the Vercel AI SDK's `output` concept:
/// it provides both a JSON schema (via [format]) and a function
/// to convert the decoded JSON map into a strongly-typed Dart
/// object of type [T].
class OutputSpec<T> {
  /// Structured output format (JSON schema) for this output.
  final StructuredOutputFormat format;

  /// Function that converts the decoded JSON map into [T].
  final T Function(Map<String, dynamic> json) fromJson;

  const OutputSpec({
    required this.format,
    required this.fromJson,
  });

  /// Convenience factory for object-shaped outputs.
  ///
  /// This method builds an [OutputSpec] from a property map using
  /// the existing [ParameterProperty] schema model. It is suitable
  /// for simple object outputs where fields are known in advance.
  factory OutputSpec.object({
    required String name,
    String? description,
    required Map<String, ParameterProperty> properties,
    required T Function(Map<String, dynamic> json) fromJson,
    List<String>? required,
    bool strict = true,
  }) {
    final schema = <String, dynamic>{
      'type': 'object',
      'properties':
          properties.map((key, value) => MapEntry(key, value.toJson())),
      'required': required ?? properties.keys.toList(),
    };

    final format = StructuredOutputFormat(
      name: name,
      description: description,
      schema: schema,
      strict: strict,
    );

    return OutputSpec<T>(
      format: format,
      fromJson: fromJson,
    );
  }

  /// Convenience spec for `{"value": string}` outputs.
  static OutputSpec<String> stringValue({
    String name = 'StringValue',
    String? description,
    String fieldName = 'value',
  }) {
    final properties = {
      fieldName: ParameterProperty(
        propertyType: 'string',
        description: 'String value',
      ),
    };

    return OutputSpec<String>.object(
      name: name,
      description: description,
      properties: properties,
      fromJson: (json) => json[fieldName] as String,
      required: [fieldName],
    );
  }

  /// Convenience spec for `{"value": integer}` outputs.
  static OutputSpec<int> intValue({
    String name = 'IntValue',
    String? description,
    String fieldName = 'value',
  }) {
    final properties = {
      fieldName: ParameterProperty(
        propertyType: 'integer',
        description: 'Integer value',
      ),
    };

    return OutputSpec<int>.object(
      name: name,
      description: description,
      properties: properties,
      fromJson: (json) => json[fieldName] as int,
      required: [fieldName],
    );
  }

  /// Convenience spec for `{"value": number}` (double) outputs.
  static OutputSpec<double> doubleValue({
    String name = 'DoubleValue',
    String? description,
    String fieldName = 'value',
  }) {
    final properties = {
      fieldName: ParameterProperty(
        propertyType: 'number',
        description: 'Double value',
      ),
    };

    return OutputSpec<double>.object(
      name: name,
      description: description,
      properties: properties,
      fromJson: (json) => (json[fieldName] as num).toDouble(),
      required: [fieldName],
    );
  }

  /// Convenience spec for `{"value": boolean}` outputs.
  static OutputSpec<bool> boolValue({
    String name = 'BoolValue',
    String? description,
    String fieldName = 'value',
  }) {
    final properties = {
      fieldName: ParameterProperty(
        propertyType: 'boolean',
        description: 'Boolean value',
      ),
    };

    return OutputSpec<bool>.object(
      name: name,
      description: description,
      properties: properties,
      fromJson: (json) => json[fieldName] as bool,
      required: [fieldName],
    );
  }

  /// Convenience spec for `{"items": [...]}` list outputs.
  ///
  /// The underlying schema uses an object with a single `items` array
  /// property, where each element is expected to match [itemOutput].
  static OutputSpec<List<T>> listOf<T>({
    required OutputSpec<T> itemOutput,
    String name = 'ListOutput',
    String? description,
    String fieldName = 'items',
  }) {
    final itemSchema = itemOutput.format.schema ??
        {
          'type': 'object',
        };

    final schema = <String, dynamic>{
      'type': 'object',
      'properties': {
        fieldName: {
          'type': 'array',
          'items': itemSchema,
        },
      },
      'required': [fieldName],
    };

    final format = StructuredOutputFormat(
      name: name,
      description: description,
      schema: schema,
      strict: true,
    );

    return OutputSpec<List<T>>(
      format: format,
      fromJson: (json) {
        final list = json[fieldName] as List;
        return list
            .map((e) => itemOutput.fromJson(
                  (e as Map).cast<String, dynamic>(),
                ))
            .toList(growable: false);
      },
    );
  }
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

/// High-level language model interface used by helper functions.
///
/// This interface is intentionally aligned with the Vercel AI SDK's
/// "language model" concept: a provider + model pair that can generate
/// and stream text based on chat-style messages, while remaining
/// provider-agnostic.
abstract class LanguageModel {
  /// Logical provider identifier as registered in the LLM provider registry.
  String get providerId;

  /// Provider-specific model identifier (e.g. `gpt-4o`, `claude-3.7-sonnet`).
  String get modelId;

  /// Effective configuration used when creating this model.
  LLMConfig get config;

  /// Generate a single non-streaming text result.
  ///
  /// This is a high-level wrapper over the underlying [ChatCapability]
  /// that returns a [GenerateTextResult] for convenience.
  Future<GenerateTextResult> generateText(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  });

  /// Stream text deltas, thinking deltas, tool calls, and the final
  /// completion event.
  ///
  /// This is a high-level wrapper over the underlying [ChatCapability]
  /// that exposes the raw [ChatStreamEvent] stream.
  Stream<ChatStreamEvent> streamText(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  });

  /// Generate a structured object based on the given [output] spec.
  ///
  /// This method assumes the underlying provider/model has been
  /// configured to produce structured JSON matching [output.format]
  /// (for example via provider-specific configuration or builder
  /// helpers). It wraps [generateText] and parses the JSON response
  /// into a [GenerateObjectResult].
  Future<GenerateObjectResult<T>> generateObject<T>(
    OutputSpec<T> output,
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  });
}

/// Default language model implementation that wraps a [ChatCapability].
///
/// This class adapts any provider that implements [ChatCapability] to
/// the high-level [LanguageModel] interface used by helper functions.
class DefaultLanguageModel implements LanguageModel {
  @override
  final String providerId;

  @override
  final String modelId;

  @override
  final LLMConfig config;

  final ChatCapability _chat;

  DefaultLanguageModel({
    required this.providerId,
    required this.modelId,
    required this.config,
    required ChatCapability chat,
  }) : _chat = chat;

  @override
  Future<GenerateTextResult> generateText(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) async {
    final response = await _chat.chat(
      messages,
      cancelToken: cancelToken,
    );

    return GenerateTextResult(
      rawResponse: response,
      text: response.text,
      thinking: response.thinking,
      toolCalls: response.toolCalls,
      usage: response.usage,
      warnings: response.warnings,
      metadata: response.callMetadata,
    );
  }

  @override
  Stream<ChatStreamEvent> streamText(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) {
    return _chat.chatStream(
      messages,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<GenerateObjectResult<T>> generateObject<T>(
    OutputSpec<T> output,
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) async {
    final textResult = await generateText(
      messages,
      cancelToken: cancelToken,
    );

    final rawText = textResult.text;
    if (rawText == null || rawText.trim().isEmpty) {
      throw const ResponseFormatError(
        'Structured output is empty or missing JSON content',
        '',
      );
    }

    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(rawText);
      if (decoded is Map<String, dynamic>) {
        json = decoded;
      } else if (decoded is Map) {
        json = Map<String, dynamic>.from(decoded);
      } else {
        throw const FormatException('Top-level JSON value is not an object');
      }
    } catch (e) {
      throw ResponseFormatError(
        'Failed to parse structured JSON output: $e',
        rawText,
      );
    }

    final object = output.fromJson(json);

    return GenerateObjectResult<T>(
      object: object,
      textResult: textResult,
    );
  }
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

/// Kind of chat operation for middleware.
///
/// This distinguishes between non-streaming chat calls and streaming
/// chat calls so that middleware can adapt behavior if needed.
enum ChatOperationKind {
  /// Standard non-streaming chat call that returns a [ChatResponse].
  chat,

  /// Streaming chat call that returns a [Stream] of [ChatStreamEvent]s.
  stream,
}

/// Context information for a chat call executed through middleware.
///
/// This provides middlewares with a provider-agnostic view of the
/// current chat invocation, including provider/model identifiers,
/// configuration, and the messages/tools involved in the call.
class ChatCallContext {
  /// Provider identifier as registered in the LLMProviderRegistry.
  final String providerId;

  /// Model identifier for this call.
  final String model;

  /// Effective configuration used to create the provider.
  ///
  /// Note: Most providers read configuration at construction time,
  /// so changing [config] inside middleware will typically not
  /// affect the underlying provider for this call. It is exposed
  /// primarily for observability and policy decisions.
  final LLMConfig config;

  /// Conversation history messages for this call.
  final List<ChatMessage> messages;

  /// Optional tools available for this call.
  final List<Tool>? tools;

  /// Optional cancellation token for this call.
  final CancelToken? cancelToken;

  /// Operation kind for this call (chat vs stream).
  final ChatOperationKind operationKind;

  const ChatCallContext({
    required this.providerId,
    required this.model,
    required this.config,
    required this.messages,
    this.tools,
    this.cancelToken,
    this.operationKind = ChatOperationKind.chat,
  });

  /// Creates a copy of this context with the given fields replaced.
  ChatCallContext copyWith({
    String? providerId,
    String? model,
    LLMConfig? config,
    List<ChatMessage>? messages,
    List<Tool>? tools,
    CancelToken? cancelToken,
    ChatOperationKind? operationKind,
  }) {
    return ChatCallContext(
      providerId: providerId ?? this.providerId,
      model: model ?? this.model,
      config: config ?? this.config,
      messages: messages ?? this.messages,
      tools: tools ?? this.tools,
      cancelToken: cancelToken ?? this.cancelToken,
      operationKind: operationKind ?? this.operationKind,
    );
  }
}

/// Middleware specification for chat operations.
///
/// This design is intentionally symmetric for non-streaming and streaming
/// chat operations and is conceptually aligned with the Vercel AI SDK
/// middleware model:
///
/// - [transform] allows middlewares to adjust parameters before the call.
/// - [wrapChat] wraps non-streaming chat calls.
/// - [wrapStream] wraps streaming chat calls.
///
/// All fields are optional so that simple middlewares can implement only
/// the hooks they need.
class ChatMiddleware {
  /// Middleware specification version for forward-compatibility.
  ///
  /// The current version is `v1`. Future versions may extend the
  /// context shape or add additional hooks.
  final String specificationVersion;

  /// Transform the call context before it is passed to the provider.
  ///
  /// This hook is invoked before [wrapChat] / [wrapStream] and can be
  /// used to adjust messages, tools, or other context fields.
  final Future<ChatCallContext> Function(ChatCallContext context)? transform;

  /// Wrap non-streaming chat calls.
  ///
  /// The [next] function executes the rest of the middleware chain and
  /// eventually the underlying provider. Middlewares can:
  /// - Inspect/modify the context before calling [next]
  /// - Short-circuit the call by not invoking [next]
  final Future<ChatResponse> Function(
    Future<ChatResponse> Function(ChatCallContext) next,
    ChatCallContext context,
  )? wrapChat;

  /// Wrap streaming chat calls.
  ///
  /// The [next] function executes the rest of the middleware chain and
  /// eventually the underlying provider. Middlewares can:
  /// - Inspect/modify the context before calling [next]
  /// - Transform the output stream
  /// - Short-circuit the call by not invoking [next]
  final Stream<ChatStreamEvent> Function(
    Stream<ChatStreamEvent> Function(ChatCallContext) next,
    ChatCallContext context,
  )? wrapStream;

  const ChatMiddleware({
    this.specificationVersion = 'v1',
    this.transform,
    this.wrapChat,
    this.wrapStream,
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

/// Context information for an embedding call executed through middleware.
class EmbeddingCallContext {
  /// Provider identifier as registered in the LLMProviderRegistry.
  final String providerId;

  /// Model identifier for this call.
  final String model;

  /// Effective configuration used to create the provider.
  final LLMConfig config;

  /// Input texts for this embedding call.
  final List<String> input;

  /// Optional cancellation token for this call.
  final CancelToken? cancelToken;

  const EmbeddingCallContext({
    required this.providerId,
    required this.model,
    required this.config,
    required this.input,
    this.cancelToken,
  });

  /// Creates a copy of this context with the given fields replaced.
  EmbeddingCallContext copyWith({
    String? providerId,
    String? model,
    LLMConfig? config,
    List<String>? input,
    CancelToken? cancelToken,
  }) {
    return EmbeddingCallContext(
      providerId: providerId ?? this.providerId,
      model: model ?? this.model,
      config: config ?? this.config,
      input: input ?? this.input,
      cancelToken: cancelToken ?? this.cancelToken,
    );
  }
}

/// Middleware specification for embedding operations.
///
/// This design mirrors the shape of [ChatMiddleware] but is focused
/// on embedding calls. Middlewares can:
/// - Transform the call context via [transform]
/// - Wrap the embed operation via [wrapEmbed]
class EmbeddingMiddleware {
  /// Middleware specification version for forward-compatibility.
  ///
  /// The current version is `v1`. Future versions may extend the
  /// context shape or add additional hooks.
  final String specificationVersion;

  /// Transform the call context before it is passed to the provider.
  ///
  /// This hook is invoked before [wrapEmbed] and can be used to
  /// adjust input texts or make policy decisions.
  final Future<EmbeddingCallContext> Function(EmbeddingCallContext context)?
      transform;

  /// Wrap the embed operation.
  ///
  /// The [next] function executes the rest of the middleware chain and
  /// eventually the underlying provider. Middlewares can:
  /// - Inspect/modify the context before calling [next]
  /// - Short-circuit the call by not invoking [next]
  final Future<List<List<double>>> Function(
    Future<List<List<double>>> Function(EmbeddingCallContext) next,
    EmbeddingCallContext context,
  )? wrapEmbed;

  const EmbeddingMiddleware({
    this.specificationVersion = 'v1',
    this.transform,
    this.wrapEmbed,
  });
}

/// Unified audio processing capability interface
///
/// This interface provides a single entry point for all audio-related functionality,
/// including text-to-speech, speech-to-text, audio translation, and real-time processing.
/// Use the `supportedFeatures` property to discover which features are available.
abstract class AudioCapability {
  // === Feature Discovery ===

  /// Get all audio features supported by this provider
  Set<AudioFeature> get supportedFeatures;

  // === Audio Generation (Text-to-Speech) ===

  /// Convert text to speech with full configuration support
  ///
  /// [request] - The text-to-speech request
  /// [cancelToken] - Optional token to cancel the request
  ///
  /// Throws [UnsupportedError] if not supported. Check [supportedFeatures] first.
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    CancelToken? cancelToken,
  }) {
    throw UnsupportedError('Text-to-speech not supported by this provider');
  }

  /// Convert text to speech with streaming output
  ///
  /// [request] - The text-to-speech request
  /// [cancelToken] - Optional token to cancel the stream
  ///
  /// Throws [UnsupportedError] if not supported. Check [supportedFeatures] first.
  Stream<AudioStreamEvent> textToSpeechStream(
    TTSRequest request, {
    CancelToken? cancelToken,
  }) {
    throw UnsupportedError(
        'Streaming text-to-speech not supported by this provider');
  }

  /// Get available voices for this provider
  Future<List<VoiceInfo>> getVoices() {
    throw UnsupportedError('Voice listing not supported by this provider');
  }

  // === Audio Understanding (Speech-to-Text) ===

  /// Convert speech to text with full configuration support
  ///
  /// [request] - The speech-to-text request
  /// [cancelToken] - Optional token to cancel the request
  ///
  /// Throws [UnsupportedError] if not supported. Check [supportedFeatures] first.
  Future<STTResponse> speechToText(
    STTRequest request, {
    CancelToken? cancelToken,
  }) {
    throw UnsupportedError('Speech-to-text not supported by this provider');
  }

  /// Translate audio to English text
  ///
  /// [request] - The audio translation request
  /// [cancelToken] - Optional token to cancel the request
  ///
  /// Throws [UnsupportedError] if not supported. Check [supportedFeatures] first.
  Future<STTResponse> translateAudio(
    AudioTranslationRequest request, {
    CancelToken? cancelToken,
  }) {
    throw UnsupportedError('Audio translation not supported by this provider');
  }

  /// Get supported languages for transcription and translation
  Future<List<LanguageInfo>> getSupportedLanguages() {
    throw UnsupportedError('Language listing not supported by this provider');
  }

  // === Real-time Audio Processing ===

  /// Create and start a real-time audio session
  ///
  /// Returns a session object for managing the real-time interaction.
  /// Throws [UnsupportedError] if not supported. Check [supportedFeatures] first.
  Future<RealtimeAudioSession> startRealtimeSession(
      RealtimeAudioConfig config) {
    throw UnsupportedError('Real-time audio not supported by this provider');
  }

  // === Metadata ===

  /// Get supported input/output audio formats
  List<String> getSupportedAudioFormats() {
    return ['mp3', 'wav', 'ogg']; // Default formats
  }

  // === Convenience Methods ===

  /// Simple text-to-speech conversion (convenience method)
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

  /// Simple streaming text-to-speech conversion (convenience method)
  Stream<List<int>> speechStream(String text) async* {
    await for (final event in textToSpeechStream(TTSRequest(text: text))) {
      if (event is AudioDataEvent) {
        yield event.data;
      }
    }
  }

  /// Simple audio transcription (convenience method)
  Future<String> transcribe(List<int> audio) async {
    final response = await speechToText(STTRequest.fromAudio(audio));
    return response.text;
  }

  /// Simple file transcription (convenience method)
  Future<String> transcribeFile(String filePath) async {
    final response = await speechToText(STTRequest.fromFile(filePath));
    return response.text;
  }

  /// Simple audio translation (convenience method)
  Future<String> translate(List<int> audio) async {
    final response =
        await translateAudio(AudioTranslationRequest.fromAudio(audio));
    return response.text;
  }

  /// Simple file translation (convenience method)
  Future<String> translateFile(String filePath) async {
    final response =
        await translateAudio(AudioTranslationRequest.fromFile(filePath));
    return response.text;
  }
}

/// Base implementation of AudioCapability with convenience methods
abstract class BaseAudioCapability implements AudioCapability {
  // Convenience methods with default implementations

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

/// Capability interface for model listing
abstract class ModelListingCapability {
  /// Get available models from the provider
  ///
  /// [cancelToken] - Optional token to cancel the request
  ///
  /// Returns a list of available models or throws an LLMError
  Future<List<AIModel>> models({CancelToken? cancelToken});
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

/// Capability interface for text completion (non-chat)
abstract class CompletionCapability {
  /// Sends a completion request to generate text
  ///
  /// [request] - The completion request parameters
  ///
  /// Returns the generated completion text or throws an LLMError
  Future<CompletionResponse> complete(CompletionRequest request);
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

/// LLM provider with voice capabilities
abstract class VoiceLLMProvider
    implements ChatCapability, AudioCapability, ProviderCapabilities {}

/// Full-featured LLM provider with all common capabilities
abstract class FullLLMProvider
    implements
        ChatCapability,
        EmbeddingCapability,
        ModelListingCapability,
        ProviderCapabilities {}

/// File management capability for uploading and managing files
///
/// This interface provides a unified API for file operations across different
/// providers (OpenAI, Anthropic, etc.).
abstract class FileManagementCapability {
  /// Upload a file
  ///
  /// Uploads a file to the provider's storage. The file can then be
  /// referenced in other API calls.
  Future<FileObject> uploadFile(FileUploadRequest request);

  /// List files
  ///
  /// Returns a paginated list of files. Supports both OpenAI-style
  /// and Anthropic-style pagination parameters.
  Future<FileListResponse> listFiles([FileListQuery? query]);

  /// Retrieve file metadata
  ///
  /// Returns metadata for a specific file including size, type, and creation date.
  Future<FileObject> retrieveFile(String fileId);

  /// Delete a file
  ///
  /// Permanently deletes a file from the provider's storage.
  Future<FileDeleteResponse> deleteFile(String fileId);

  /// Get file content
  ///
  /// Downloads the raw content of a file as bytes.
  Future<List<int>> getFileContent(String fileId);
}

/// Content moderation capability
abstract class ModerationCapability {
  /// Moderate content for policy violations
  Future<ModerationResponse> moderate(ModerationRequest request);
}

/// Assistant management capability
abstract class AssistantCapability {
  /// Create an assistant
  Future<Assistant> createAssistant(CreateAssistantRequest request);

  /// List assistants
  Future<ListAssistantsResponse> listAssistants([ListAssistantsQuery? query]);

  /// Retrieve an assistant
  Future<Assistant> retrieveAssistant(String assistantId);

  /// Modify an assistant
  Future<Assistant> modifyAssistant(
    String assistantId,
    ModifyAssistantRequest request,
  );

  /// Delete an assistant
  Future<DeleteAssistantResponse> deleteAssistant(String assistantId);
}

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
