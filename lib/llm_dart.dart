/// LLM Dart Library - A modular Dart library for AI provider interactions
///
/// This library provides a unified interface for interacting with different
/// AI providers, starting with OpenAI. It's designed to be modular and
/// extensible
library;

import 'dart:async';
import 'dart:convert';

// Core exports (forwarded from llm_dart_core).
//
// The root package now re-exports a curated SDK surface from
// `llm_dart_core` instead of the entire core API. This keeps the
// default import:
//   import 'package:llm_dart/llm_dart.dart';
// focused on high-level usage (messages, tools, language models,
// agents, and helper functions).
//
// For full access to all core types (capabilities, low-level models,
// registry, etc.), prefer importing `llm_dart_core` directly:
//   import 'package:llm_dart_core/llm_dart_core.dart';
export 'package:llm_dart_core/llm_dart_core.dart'
    show
        // Core error / cancellation
        LLMError,
        HttpError,
        GenericError,
        InvalidRequestError,
        AuthError,
        ProviderError,
        ResponseFormatError,
        TimeoutError,
        NotFoundError,
        JsonError,
        ToolConfigError,
        ToolExecutionError,
        ToolValidationError,
        StructuredOutputError,
        RateLimitError,
        QuotaExceededError,
        ModelNotAvailableError,
        CancelledError,
        ContentFilterError,
        ServerError,
        UnsupportedCapabilityError,
        OpenAIResponsesError,
        CancellationToken,
        CancellationTokenSource,

        // Core config & capabilities (high-level)
        LLMConfig,
        LLMCapability,
        LanguageModel,
        ChatCapability,
        EmbeddingCapability,
        CompletionCapability,
        ToolExecutionCapability,
        ModerationCapability,
        ModelListingCapability,
        ProviderCapabilities,
        ChatResponse,
        Agent,
        AgentInput,
        ToolLoopAgent,
        ToolLoopConfig,

        // Chat models & stream types
        ChatRole,
        ChatMessage,
        ModelMessage,
        MessageBuilder,
        MessageType,
        TextMessage,
        ImageMessage,
        FileMessage,
        ImageUrlMessage,
        ToolUseMessage,
        ToolResultMessage,
        ImageMime,
        ImageMimeExtension,
        FileMime,
        ChatStreamEvent,
        TextDeltaEvent,
        ThinkingDeltaEvent,
        ToolCallDeltaEvent,
        CompletionEvent,
        ErrorEvent,
        StreamTextPart,
        StreamTextStart,
        StreamTextDelta,
        StreamTextEnd,
        StreamThinkingDelta,
        StreamToolInputStart,
        StreamToolInputDelta,
        StreamToolInputEnd,
        StreamToolCall,
        StreamFinish,
        GenerateTextResult,
        GenerateObjectResult,

        // Chat / embedding middleware & contexts
        ChatOperationKind,
        ChatCallContext,
        ChatMiddleware,
        EmbeddingCallContext,
        EmbeddingMiddleware,

        // Tools & structured output
        Tool,
        ExecutableTool,
        ToolCall,
        ToolResult,
        FunctionCall,
        FunctionTool,
        ParameterProperty,
        ParametersSchema,
        ToolChoice,
        AutoToolChoice,
        AnyToolChoice,
        NoneToolChoice,
        SpecificToolChoice,
        ParallelToolConfig,
        ToolValidator,
        OutputSpec,
        StructuredOutputFormat,

        // Model capability configuration
        ModelCapabilityConfig,
        LLMConfigKeys,

        // Cancellation helpers
        CancellationHelper,

        // Call options and metadata
        LanguageModelCallOptions,
        CallWarning,
        UsageInfo,
        CallMetadata,
        ServiceTier,
        ReasoningEffort,
        Verbosity,

        // Audio capabilities & models
        AudioFeature,
        AudioCapability,
        BaseAudioCapability,
        AudioProcessingMode,
        AudioQuality,
        AudioFormat,
        TextNormalization,
        AudioStreamEvent,
        AudioDataEvent,
        AudioMetadataEvent,
        AudioTimingEvent,
        AudioErrorEvent,
        TTSRequest,
        TTSResponse,
        STTRequest,
        STTResponse,
        AudioTranslationRequest,
        TimestampGranularity,
        EnhancedWordTiming,
        VoiceInfo,
        RealtimeAudioSession,
        RealtimeAudioEvent,
        RealtimeAudioConfig,
        RealtimeTranscriptionEvent,
        RealtimeAudioResponseEvent,
        RealtimeSessionStatusEvent,
        RealtimeErrorEvent,

        // Image generation capabilities & models
        ImageGenerationCapability,
        ImageGenerationRequest,
        ImageEditRequest,
        ImageVariationRequest,
        ImageGenerationResponse,
        ImageInput,
        ImageDimensions,
        ImageStyle,
        ImageQuality,
        ImageSize,

        // Stream helpers
        adaptStreamText,

        // File capabilities & models
        FileManagementCapability,
        FilePurpose,
        FileStatus,
        FileObject,
        FileUploadRequest,
        FileListResponse,
        FileListQuery,

        // Moderation models
        ModerationRequest,
        ModerationCategories,
        ModerationCategoryScores,
        ModerationResult,
        ModerationResponse,

        // Model listing
        AIModel,

        // Responses API models
        ResponseInputItemsList,
        ResponseInputItem,

        // Web search configuration
        WebSearchConfig,
        WebSearchType,
        WebSearchContextSize,
        WebSearchStrategy,
        WebSearchLocation,

        // Assistant capabilities & models
        AssistantCapability,
        AssistantToolType,
        AssistantTool,
        CodeInterpreterTool,
        FileSearchTool,
        AssistantFunctionTool,
        AssistantResponseFormat,
        Assistant,
        CreateAssistantRequest,
        ModifyAssistantRequest,
        ListAssistantsResponse,
        DeleteAssistantResponse,
        ListAssistantsQuery;

// Provider utils exports (HTTP config, error handling, UTF-8 decoding).
//
// These utilities live in the llm_dart_provider_utils package but are
// re-exported here for convenience so that common SDK usage only needs
// `package:llm_dart/llm_dart.dart`.
export 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart'
    show
        HttpConfigUtils,
        DioErrorHandler,
        Utf8StreamDecoder,
        Utf8StreamDecoderExtension;

// Core registry & defaults (still live in this package)
export 'core/provider_defaults.dart';
export 'core/registry.dart';
export 'core/base_http_provider.dart';

// Provider exports
export 'providers/openai/openai.dart'
    hide createDeepSeekProvider, createGroqProvider;
export 'providers/anthropic/anthropic.dart';
export 'providers/anthropic/client.dart';
export 'providers/anthropic/models.dart';
export 'providers/google/google.dart';
export 'providers/google/tts.dart';
export 'providers/deepseek/deepseek.dart';
export 'providers/deepseek/client.dart';
export 'providers/ollama/ollama.dart';
export 'providers/xai/xai.dart';
export 'providers/phind/phind.dart';
export 'providers/groq/groq.dart';
export 'providers/elevenlabs/elevenlabs.dart';

// Factory exports
export 'providers/factories/base_factory.dart';

// Builder exports
export 'builder/llm_builder.dart';
export 'builder/chat_prompt_builder.dart';
export 'builder/http_config.dart';
export 'builder/audio_config.dart';
export 'builder/image_config.dart';
export 'builder/provider_config.dart';

// Utility exports
export 'utils/config_utils.dart';
export 'utils/capability_utils.dart';
export 'utils/provider_registry.dart';
export 'utils/logging_middleware.dart';
export 'utils/default_settings_middleware.dart';

// Convenience functions for creating providers
import 'package:llm_dart_core/llm_dart_core.dart';

import 'builder/llm_builder.dart';
import 'utils/message_resolver.dart';

/// Create a new LLM builder instance
///
/// This is the main entry point for creating AI providers.
///
/// Example:
/// ```dart
/// final provider = await ai()
///     .openai()
///     .apiKey('your-key')
///     .model('gpt-4')
///     .build();
/// ```
LLMBuilder ai() => LLMBuilder();

/// Create a provider with the given configuration
///
/// Convenience function for quickly creating providers with common settings.
///
/// Example:
/// ```dart
/// final provider = await createProvider(
///   providerId: 'openai',
///   apiKey: 'your-key',
///   model: 'gpt-4',
/// );
/// ```
Future<ChatCapability> createProvider({
  required String providerId,
  required String apiKey,
  required String model,
  String? baseUrl,
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
  Duration? timeout,
  bool stream = false,
  double? topP,
  int? topK,
  Map<String, dynamic>? extensions,
}) async {
  var builder = LLMBuilder().provider(providerId).apiKey(apiKey).model(model);

  if (baseUrl != null) builder = builder.baseUrl(baseUrl);
  if (temperature != null) builder = builder.temperature(temperature);
  if (maxTokens != null) builder = builder.maxTokens(maxTokens);
  if (systemPrompt != null) builder = builder.systemPrompt(systemPrompt);
  if (timeout != null) builder = builder.timeout(timeout);
  if (topP != null) builder = builder.topP(topP);
  if (topK != null) builder = builder.topK(topK);

  // Add extensions if provided
  if (extensions != null) {
    for (final entry in extensions.entries) {
      builder = builder.extension(entry.key, entry.value);
    }
  }

  return await builder.build();
}

/// High-level generateText helper (Vercel AI SDK-style).
///
/// This function provides a model-centric API where [model] is in the form
/// `"provider:model"`, for example:
///
/// - `"openai:gpt-4o"`
/// - `"deepseek:deepseek-chat"`
/// - `"deepseek:deepseek-reasoner"`
/// - `"ollama:llama3.2"`
///
/// Under the hood it uses [LLMBuilder] and the provider registry, and
/// returns a provider-agnostic [GenerateTextResult].
Future<GenerateTextResult> generateText({
  required String model,
  String? apiKey,
  String? baseUrl,
  String? prompt,
  List<ChatMessage>? messages,
  ModelMessage? structuredPrompt,
  List<ModelMessage>? promptMessages,
  CancellationToken? cancelToken,
  LanguageModelCallOptions? options,
}) {
  var builder = LLMBuilder().use(model);

  if (apiKey != null) {
    builder = builder.apiKey(apiKey);
  }
  if (baseUrl != null) {
    builder = builder.baseUrl(baseUrl);
  }

  builder = _applyCallOptions(builder, options);

  return builder.generateText(
    prompt: prompt,
    messages: messages,
    structuredPrompt: structuredPrompt,
    promptMessages: promptMessages,
    cancelToken: cancelToken,
  );
}

/// Generate text using an existing [LanguageModel] instance.
///
/// This helper mirrors [generateText] but operates on a pre-configured
/// [LanguageModel], which is useful when you want to:
/// - Reuse the same model across multiple calls.
/// - Pass models through dependency injection.
/// - Decouple higher-level code from concrete providers.
Future<GenerateTextResult> generateTextWithModel(
  LanguageModel model, {
  String? prompt,
  List<ChatMessage>? messages,
  ModelMessage? structuredPrompt,
  List<ModelMessage>? promptMessages,
  CancellationToken? cancelToken,
  LanguageModelCallOptions? options,
}) {
  final resolvedMessages = resolveMessagesForTextGeneration(
    prompt: prompt,
    messages: messages,
    structuredPrompt: structuredPrompt,
    promptMessages: promptMessages,
  );
  return model.generateTextWithOptions(
    resolvedMessages,
    options: options,
    cancelToken: cancelToken,
  );
}

/// High-level streamText helper (Vercel AI SDK-style).
///
/// This function mirrors [generateText] but returns a stream of
/// [ChatStreamEvent] values (thinking deltas, text deltas, tool call
/// deltas, and the final completion event).
Stream<ChatStreamEvent> streamText({
  required String model,
  String? apiKey,
  String? baseUrl,
  String? prompt,
  List<ChatMessage>? messages,
  ModelMessage? structuredPrompt,
  List<ModelMessage>? promptMessages,
  CancellationToken? cancelToken,
  LanguageModelCallOptions? options,
}) async* {
  var builder = LLMBuilder().use(model);

  if (apiKey != null) {
    builder = builder.apiKey(apiKey);
  }
  if (baseUrl != null) {
    builder = builder.baseUrl(baseUrl);
  }

  builder = _applyCallOptions(builder, options);

  yield* builder.streamText(
    prompt: prompt,
    messages: messages,
    structuredPrompt: structuredPrompt,
    promptMessages: promptMessages,
    cancelToken: cancelToken,
  );
}

/// Stream text using an existing [LanguageModel] instance.
///
/// This helper mirrors [streamText] but operates on a pre-configured
/// [LanguageModel].
Stream<ChatStreamEvent> streamTextWithModel(
  LanguageModel model, {
  String? prompt,
  List<ChatMessage>? messages,
  ModelMessage? structuredPrompt,
  List<ModelMessage>? promptMessages,
  CancellationToken? cancelToken,
  LanguageModelCallOptions? options,
}) async* {
  final resolvedMessages = resolveMessagesForTextGeneration(
    prompt: prompt,
    messages: messages,
    structuredPrompt: structuredPrompt,
    promptMessages: promptMessages,
  );
  yield* model.streamTextWithOptions(
    resolvedMessages,
    options: options,
    cancelToken: cancelToken,
  );
}

/// Stream high-level text parts using an existing [LanguageModel] instance.
///
/// This helper mirrors [streamTextParts] but operates on a pre-configured
/// [LanguageModel] and accepts [LanguageModelCallOptions] for per-call
/// configuration.
Stream<StreamTextPart> streamTextPartsWithModel(
  LanguageModel model, {
  String? prompt,
  List<ChatMessage>? messages,
  ModelMessage? structuredPrompt,
  List<ModelMessage>? promptMessages,
  CancellationToken? cancelToken,
  LanguageModelCallOptions? options,
}) async* {
  final resolvedMessages = resolveMessagesForTextGeneration(
    prompt: prompt,
    messages: messages,
    structuredPrompt: structuredPrompt,
    promptMessages: promptMessages,
  );
  yield* model.streamTextPartsWithOptions(
    resolvedMessages,
    options: options,
    cancelToken: cancelToken,
  );
}

/// High-level helper that returns provider-agnostic stream parts.
///
/// This mirrors [streamText] but adapts the low-level [ChatStreamEvent]
/// values into [StreamTextPart] values (text start/delta/end, thinking
/// deltas, tool input lifecycle, and final completion).
Stream<StreamTextPart> streamTextParts({
  required String model,
  String? apiKey,
  String? baseUrl,
  String? prompt,
  List<ChatMessage>? messages,
  ModelMessage? structuredPrompt,
  List<ModelMessage>? promptMessages,
  CancellationToken? cancelToken,
  LanguageModelCallOptions? options,
}) async* {
  var builder = LLMBuilder().use(model);

  if (apiKey != null) {
    builder = builder.apiKey(apiKey);
  }
  if (baseUrl != null) {
    builder = builder.baseUrl(baseUrl);
  }

  // For now, streamTextParts follows the same per-call configuration
  // surface as streamText (maxTokens, sampling, tools, etc.) via
  // [LanguageModelCallOptions]. This keeps the API consistent while
  // we evaluate whether additional stream-specific settings are needed.
  builder = _applyCallOptions(builder, options);

  yield* builder.streamTextParts(
    prompt: prompt,
    messages: messages,
    structuredPrompt: structuredPrompt,
    promptMessages: promptMessages,
    cancelToken: cancelToken,
  );
}

/// High-level structured object generation helper.
///
/// This helper configures structured outputs via [StructuredOutputFormat]
/// and returns a strongly-typed object parsed from the model's JSON
/// response. It is conceptually similar to the Vercel AI SDK's
/// `generateObject` helper.
///
/// The [model] identifier must be in the form `"provider:model"`, e.g.:
/// - `"openai:gpt-4o-mini"`
/// - `"deepseek:deepseek-chat"`
/// - `"ollama:llama3.2"`
///
/// The [output] spec is forwarded to providers that support structured
/// outputs (OpenAI, Google, Groq, Ollama, etc.) via their native JSON
/// schema integration, and its [OutputSpec.fromJson] function is used
/// to convert the decoded JSON map into the desired Dart type [T].
Future<GenerateObjectResult<T>> generateObject<T>({
  required String model,
  required OutputSpec<T> output,
  String? apiKey,
  String? baseUrl,
  String? prompt,
  List<ChatMessage>? messages,
  ModelMessage? structuredPrompt,
  List<ModelMessage>? promptMessages,
  CancellationToken? cancelToken,
  LanguageModelCallOptions? options,
}) async {
  var builder = LLMBuilder().use(model).jsonSchema(output.format);

  if (apiKey != null) {
    builder = builder.apiKey(apiKey);
  }
  if (baseUrl != null) {
    builder = builder.baseUrl(baseUrl);
  }

  builder = _applyCallOptions(builder, options);

  final textResult = await builder.generateText(
    prompt: prompt,
    messages: messages,
    structuredPrompt: structuredPrompt,
    promptMessages: promptMessages,
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

/// Streaming structured object helper (MVP).
///
/// This helper streams [ChatStreamEvent]s while concurrently
/// accumulating text deltas to reconstruct a JSON string at the end
/// of the stream, which is then parsed using the given [output]
/// specification.
class StreamObjectResult<T> {
  /// Stream of chat events (thinking, text deltas, tool calls, completion).
  final Stream<ChatStreamEvent> events;

  /// Future that resolves to the structured object result once the
  /// stream completes and JSON parsing succeeds.
  final Future<GenerateObjectResult<T>> asObject;

  const StreamObjectResult({
    required this.events,
    required this.asObject,
  });
}

/// Generate a structured object using an existing [LanguageModel].
///
/// This helper assumes the given [model] has already been configured
/// to produce structured JSON matching [output.format] and mirrors
/// the behavior of [generateObject].
Future<GenerateObjectResult<T>> generateObjectWithModel<T>({
  required LanguageModel model,
  required OutputSpec<T> output,
  String? prompt,
  List<ChatMessage>? messages,
  ModelMessage? structuredPrompt,
  List<ModelMessage>? promptMessages,
  CancellationToken? cancelToken,
  LanguageModelCallOptions? options,
}) async {
  final resolvedMessages = resolveMessagesForTextGeneration(
    prompt: prompt,
    messages: messages,
    structuredPrompt: structuredPrompt,
    promptMessages: promptMessages,
  );

  return model.generateObjectWithOptions<T>(
    output,
    resolvedMessages,
    options: options,
    cancelToken: cancelToken,
  );
}

/// Run a text-only agent loop using the given [model] and [tools].
///
/// This helper constructs an [AgentInput] and delegates to the provided
/// [agent] (defaults to [ToolLoopAgent]). The loop will:
/// - Call the language model with the current messages.
/// - Execute any requested tools and append their results.
/// - Repeat until no tool calls remain or [ToolLoopConfig.maxIterations]
///   is reached.
Future<GenerateTextResult> runAgentText({
  required LanguageModel model,
  required List<ChatMessage> messages,
  required Map<String, ExecutableTool> tools,
  ToolLoopConfig loopConfig = const ToolLoopConfig(),
  CancellationToken? cancelToken,
  Agent? agent,
  LanguageModelCallOptions? options,
}) async {
  final input = AgentInput(
    model: model,
    messages: messages,
    tools: tools,
    loopConfig: loopConfig,
    cancelToken: cancelToken,
    callOptions: options,
  );

  final effectiveAgent = agent ?? const ToolLoopAgent();
  return effectiveAgent.runText(input);
}

/// Run a text-only agent loop using structured prompt messages.
///
/// This variant accepts the initial conversation as a list of
/// [ModelMessage]s and bridges them to [ChatMessage] internally so
/// that providers can still recover the full structured content model.
Future<GenerateTextResult> runAgentPromptText({
  required LanguageModel model,
  required List<ModelMessage> promptMessages,
  required Map<String, ExecutableTool> tools,
  ToolLoopConfig loopConfig = const ToolLoopConfig(),
  CancellationToken? cancelToken,
  Agent? agent,
  LanguageModelCallOptions? options,
}) async {
  final initialMessages = promptMessages
      .map((prompt) => ChatMessage.fromPromptMessage(prompt))
      .toList();

  final input = AgentInput(
    model: model,
    messages: initialMessages,
    promptMessages: promptMessages,
    tools: tools,
    loopConfig: loopConfig,
    cancelToken: cancelToken,
    callOptions: options,
  );

  final effectiveAgent = agent ?? const ToolLoopAgent();
  return effectiveAgent.runText(input);
}

/// Run a text-only agent loop and return both the final result and steps.
Future<AgentTextRunWithSteps> runAgentTextWithSteps({
  required LanguageModel model,
  required List<ChatMessage> messages,
  required Map<String, ExecutableTool> tools,
  ToolLoopConfig loopConfig = const ToolLoopConfig(),
  CancellationToken? cancelToken,
  Agent? agent,
  LanguageModelCallOptions? options,
}) {
  final input = AgentInput(
    model: model,
    messages: messages,
    tools: tools,
    loopConfig: loopConfig,
    cancelToken: cancelToken,
    callOptions: options,
  );

  final effectiveAgent = agent ?? const ToolLoopAgent();
  return effectiveAgent.runTextWithSteps(input);
}

/// Run a text-only agent loop using structured prompt messages and
/// return both the final result and per-step trace.
Future<AgentTextRunWithSteps> runAgentPromptTextWithSteps({
  required LanguageModel model,
  required List<ModelMessage> promptMessages,
  required Map<String, ExecutableTool> tools,
  ToolLoopConfig loopConfig = const ToolLoopConfig(),
  CancellationToken? cancelToken,
  Agent? agent,
  LanguageModelCallOptions? options,
}) {
  final initialMessages = promptMessages
      .map((prompt) => ChatMessage.fromPromptMessage(prompt))
      .toList();

  final input = AgentInput(
    model: model,
    messages: initialMessages,
    promptMessages: promptMessages,
    tools: tools,
    loopConfig: loopConfig,
    cancelToken: cancelToken,
    callOptions: options,
  );

  final effectiveAgent = agent ?? const ToolLoopAgent();
  return effectiveAgent.runTextWithSteps(input);
}

/// Run an agent loop that produces a structured object result.
Future<GenerateObjectResult<T>> runAgentObject<T>({
  required LanguageModel model,
  required List<ChatMessage> messages,
  required Map<String, ExecutableTool> tools,
  required OutputSpec<T> output,
  ToolLoopConfig loopConfig = const ToolLoopConfig(),
  CancellationToken? cancelToken,
  Agent? agent,
  LanguageModelCallOptions? options,
}) async {
  final input = AgentInput(
    model: model,
    messages: messages,
    tools: tools,
    loopConfig: loopConfig,
    cancelToken: cancelToken,
    callOptions: options,
  );

  final effectiveAgent = agent ?? const ToolLoopAgent();
  return effectiveAgent.runObject<T>(
    input: input,
    output: output,
  );
}

/// Run an agent loop using structured prompt messages that produces a
/// structured object result.
Future<GenerateObjectResult<T>> runAgentPromptObject<T>({
  required LanguageModel model,
  required List<ModelMessage> promptMessages,
  required Map<String, ExecutableTool> tools,
  required OutputSpec<T> output,
  ToolLoopConfig loopConfig = const ToolLoopConfig(),
  CancellationToken? cancelToken,
  Agent? agent,
  LanguageModelCallOptions? options,
}) async {
  final initialMessages = promptMessages
      .map((prompt) => ChatMessage.fromPromptMessage(prompt))
      .toList();

  final input = AgentInput(
    model: model,
    messages: initialMessages,
    promptMessages: promptMessages,
    tools: tools,
    loopConfig: loopConfig,
    cancelToken: cancelToken,
    callOptions: options,
  );

  final effectiveAgent = agent ?? const ToolLoopAgent();
  return effectiveAgent.runObject<T>(
    input: input,
    output: output,
  );
}

/// Run an agent loop that produces a structured object result and step trace.
Future<AgentObjectRunWithSteps<T>> runAgentObjectWithSteps<T>({
  required LanguageModel model,
  required List<ChatMessage> messages,
  required Map<String, ExecutableTool> tools,
  required OutputSpec<T> output,
  ToolLoopConfig loopConfig = const ToolLoopConfig(),
  CancellationToken? cancelToken,
  Agent? agent,
  LanguageModelCallOptions? options,
}) {
  final input = AgentInput(
    model: model,
    messages: messages,
    tools: tools,
    loopConfig: loopConfig,
    cancelToken: cancelToken,
    callOptions: options,
  );

  final effectiveAgent = agent ?? const ToolLoopAgent();
  return effectiveAgent.runObjectWithSteps<T>(
    input: input,
    output: output,
  );
}

/// Run an agent loop using structured prompt messages that produces a
/// structured object result and step trace.
Future<AgentObjectRunWithSteps<T>> runAgentPromptObjectWithSteps<T>({
  required LanguageModel model,
  required List<ModelMessage> promptMessages,
  required Map<String, ExecutableTool> tools,
  required OutputSpec<T> output,
  ToolLoopConfig loopConfig = const ToolLoopConfig(),
  CancellationToken? cancelToken,
  Agent? agent,
  LanguageModelCallOptions? options,
}) {
  final initialMessages = promptMessages
      .map((prompt) => ChatMessage.fromPromptMessage(prompt))
      .toList();

  final input = AgentInput(
    model: model,
    messages: initialMessages,
    promptMessages: promptMessages,
    tools: tools,
    loopConfig: loopConfig,
    cancelToken: cancelToken,
    callOptions: options,
  );

  final effectiveAgent = agent ?? const ToolLoopAgent();
  return effectiveAgent.runObjectWithSteps<T>(
    input: input,
    output: output,
  );
}

/// Stream a structured object response using the given [model] and
/// [output] specification.
///
/// This function:
/// - Configures structured outputs via [OutputSpec.format].
/// - Streams raw [ChatStreamEvent]s using [LLMBuilder.streamText].
/// - Accumulates [TextDeltaEvent] content into a JSON string.
/// - Parses the JSON into a [GenerateObjectResult] when the stream ends.
StreamObjectResult<T> streamObject<T>({
  required String model,
  required OutputSpec<T> output,
  String? apiKey,
  String? baseUrl,
  String? prompt,
  List<ChatMessage>? messages,
  ModelMessage? structuredPrompt,
  List<ModelMessage>? promptMessages,
  CancellationToken? cancelToken,
  LanguageModelCallOptions? options,
}) {
  var builder = LLMBuilder().use(model).jsonSchema(output.format);

  if (apiKey != null) {
    builder = builder.apiKey(apiKey);
  }
  if (baseUrl != null) {
    builder = builder.baseUrl(baseUrl);
  }

  builder = _applyCallOptions(builder, options);

  final controller = StreamController<ChatStreamEvent>();
  final completer = Completer<GenerateObjectResult<T>>();
  final buffer = StringBuffer();
  ChatResponse? finalResponse;

  () async {
    try {
      await for (final event in builder.streamText(
        prompt: prompt,
        messages: messages,
        structuredPrompt: structuredPrompt,
        promptMessages: promptMessages,
        cancelToken: cancelToken,
      )) {
        if (event is TextDeltaEvent) {
          buffer.write(event.delta);
        } else if (event is CompletionEvent) {
          finalResponse = event.response;
        }
        controller.add(event);
      }

      var rawText = buffer.toString();
      if (rawText.trim().isEmpty && finalResponse?.text != null) {
        rawText = finalResponse!.text!;
      }

      if (rawText.trim().isEmpty) {
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

      final response = finalResponse ?? _SimpleChatResponse(rawText);

      final textResult = GenerateTextResult(
        rawResponse: response,
        text: rawText,
        thinking: response.thinking,
        toolCalls: response.toolCalls,
        usage: response.usage,
        warnings: response.warnings,
        metadata: response.callMetadata,
      );

      final object = output.fromJson(json);

      if (!completer.isCompleted) {
        completer.complete(
          GenerateObjectResult<T>(
            object: object,
            textResult: textResult,
          ),
        );
      }
    } catch (e, st) {
      if (!completer.isCompleted) {
        completer.completeError(e, st);
      }
      controller.addError(e, st);
    } finally {
      await controller.close();
    }
  }();

  return StreamObjectResult<T>(
    events: controller.stream,
    asObject: completer.future,
  );
}

/// Apply per-call language model options to an [LLMBuilder].
LLMBuilder _applyCallOptions(
  LLMBuilder builder,
  LanguageModelCallOptions? options,
) {
  if (options == null) return builder;

  if (options.maxTokens != null) {
    builder = builder.maxTokens(options.maxTokens!);
  }
  if (options.temperature != null) {
    builder = builder.temperature(options.temperature!);
  }
  if (options.topP != null) {
    builder = builder.topP(options.topP!);
  }
  if (options.topK != null) {
    builder = builder.topK(options.topK!);
  }
  if (options.stopSequences != null) {
    builder = builder.stopSequences(options.stopSequences!);
  }
  if (options.tools != null) {
    builder = builder.tools(options.tools!);
  }
  if (options.toolChoice != null) {
    builder = builder.toolChoice(options.toolChoice!);
  }
  if (options.user != null) {
    builder = builder.user(options.user!);
  }
  if (options.serviceTier != null) {
    builder = builder.serviceTier(options.serviceTier!);
  }

  return builder;
}

/// Simple [ChatResponse] implementation used when no provider-specific
/// response is available (e.g. in streaming structured output helpers).
class _SimpleChatResponse implements ChatResponse {
  final String _text;

  _SimpleChatResponse(this._text);

  @override
  String? get text => _text;

  @override
  List<ToolCall>? get toolCalls => const [];

  @override
  String? get thinking => null;

  @override
  UsageInfo? get usage => null;

  @override
  List<CallWarning> get warnings => const [];

  @override
  Map<String, dynamic>? get metadata => null;

  @override
  CallMetadata? get callMetadata => null;
}
