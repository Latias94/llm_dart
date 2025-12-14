// High-level text, embedding, image, and structured output helpers.
// This module is prompt-first and operates on ModelMessage conversations.

library;

import 'dart:async';

import 'package:llm_dart_ai/llm_dart_ai.dart' show StreamObjectResult;
import 'package:llm_dart_core/llm_dart_core.dart';
export 'package:llm_dart_ai/llm_dart_ai.dart'
    show
        generateTextWithModel,
        generateTextPromptWithModel,
        streamTextWithModel,
        streamTextPromptWithModel,
        streamTextPartsWithModel,
        streamTextPartsPromptWithModel,
        generateObjectWithModel,
        embedWithModel,
        rerankWithModel,
        generateImageWithModel,
        StreamObjectResult,
        streamObjectWithModel;

import 'builder/llm_builder.dart';
import 'src/builtin_providers.dart' show registerBuiltinProviders;

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
///
/// For new code, prefer one of the following:
/// - [promptMessages] with [ModelMessage], or
/// - [generateTextPrompt] / [generateTextPromptWithModel].
///
/// This helper is prompt-first and does not support the removed
/// `ChatMessage` legacy model.
Future<GenerateTextResult> generateText({
  required String model,
  String? apiKey,
  String? baseUrl,
  String? prompt,
  ModelMessage? structuredPrompt,
  List<ModelMessage>? promptMessages,
  CancellationToken? cancelToken,
  LanguageModelCallOptions? options,
  void Function(GenerateTextResult result)? onFinish,
  void Function(List<CallWarning> warnings)? onWarnings,
}) async {
  registerBuiltinProviders();
  var builder = LLMBuilder().use(model);

  if (apiKey != null) {
    builder = builder.apiKey(apiKey);
  }
  if (baseUrl != null) {
    builder = builder.baseUrl(baseUrl);
  }

  builder = _applyCallOptions(builder, options);

  final result = await builder.generateText(
    prompt: prompt,
    structuredPrompt: structuredPrompt,
    promptMessages: promptMessages,
    cancelToken: cancelToken,
    options: options,
  );

  if (onFinish != null) {
    onFinish(result);
  }
  if (onWarnings != null && result.warnings.isNotEmpty) {
    onWarnings(result.warnings);
  }

  return result;
}

/// Prompt-first generateText helper using [ModelMessage] conversations.
///
/// This variant mirrors [generateText] but accepts the conversation as
/// a list of structured [ModelMessage]s.
///
/// It is the preferred entry point for new code.
Future<GenerateTextResult> generateTextPrompt({
  required String model,
  required List<ModelMessage> messages,
  String? apiKey,
  String? baseUrl,
  CancellationToken? cancelToken,
  LanguageModelCallOptions? options,
  void Function(GenerateTextResult result)? onFinish,
  void Function(List<CallWarning> warnings)? onWarnings,
}) {
  return generateText(
    model: model,
    apiKey: apiKey,
    baseUrl: baseUrl,
    promptMessages: messages,
    cancelToken: cancelToken,
    options: options,
    onFinish: onFinish,
    onWarnings: onWarnings,
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
  ModelMessage? structuredPrompt,
  List<ModelMessage>? promptMessages,
  CancellationToken? cancelToken,
  LanguageModelCallOptions? options,
  void Function(GenerateTextResult result)? onFinish,
  void Function(List<CallWarning> warnings)? onWarnings,
}) async* {
  registerBuiltinProviders();
  var builder = LLMBuilder().use(model);

  if (apiKey != null) {
    builder = builder.apiKey(apiKey);
  }
  if (baseUrl != null) {
    builder = builder.baseUrl(baseUrl);
  }

  builder = _applyCallOptions(builder, options);

  final source = builder.streamText(
    prompt: prompt,
    structuredPrompt: structuredPrompt,
    promptMessages: promptMessages,
    cancelToken: cancelToken,
    options: options,
  );

  await for (final event in source) {
    if (event is CompletionEvent && (onFinish != null || onWarnings != null)) {
      final response = event.response;
      final result = GenerateTextResult(
        rawResponse: response,
        text: response.text,
        thinking: response.thinking,
        toolCalls: response.toolCalls,
        usage: response.usage,
        warnings: response.warnings,
        metadata: response.callMetadata,
      );

      if (onFinish != null) {
        onFinish(result);
      }
      if (onWarnings != null && result.warnings.isNotEmpty) {
        onWarnings(result.warnings);
      }
    }

    yield event;
  }
}

/// Prompt-first streamText helper using [ModelMessage] conversations.
///
/// This mirrors [streamText] but accepts a list of [ModelMessage]s and
/// is the recommended API for new integrations.
Stream<ChatStreamEvent> streamTextPrompt({
  required String model,
  required List<ModelMessage> messages,
  String? apiKey,
  String? baseUrl,
  CancellationToken? cancelToken,
  LanguageModelCallOptions? options,
  void Function(GenerateTextResult result)? onFinish,
  void Function(List<CallWarning> warnings)? onWarnings,
}) {
  return streamText(
    model: model,
    apiKey: apiKey,
    baseUrl: baseUrl,
    promptMessages: messages,
    cancelToken: cancelToken,
    options: options,
    onFinish: onFinish,
    onWarnings: onWarnings,
  );
}

/// Prompt-first helper that returns provider-agnostic stream parts.
///
/// This mirrors [streamTextParts] but accepts a list of [ModelMessage]s
/// and is the recommended streaming API for new integrations.
Stream<StreamTextPart> streamTextPartsPrompt({
  required String model,
  required List<ModelMessage> messages,
  String? apiKey,
  String? baseUrl,
  CancellationToken? cancelToken,
  LanguageModelCallOptions? options,
}) {
  return streamTextParts(
    model: model,
    apiKey: apiKey,
    baseUrl: baseUrl,
    promptMessages: messages,
    cancelToken: cancelToken,
    options: options,
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
  ModelMessage? structuredPrompt,
  List<ModelMessage>? promptMessages,
  CancellationToken? cancelToken,
  LanguageModelCallOptions? options,
}) async* {
  registerBuiltinProviders();
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
    structuredPrompt: structuredPrompt,
    promptMessages: promptMessages,
    cancelToken: cancelToken,
    options: options,
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
  ModelMessage? structuredPrompt,
  List<ModelMessage>? promptMessages,
  CancellationToken? cancelToken,
  LanguageModelCallOptions? options,
}) async {
  registerBuiltinProviders();
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
    structuredPrompt: structuredPrompt,
    promptMessages: promptMessages,
    cancelToken: cancelToken,
    options: options,
  );

  final rawText = textResult.text;
  if (rawText == null || rawText.trim().isEmpty) {
    throw const ResponseFormatError(
      'Structured output is empty or missing JSON content',
      '',
    );
  }

  final json = parseStructuredObjectJson(rawText, output.format);
  final object = output.fromJson(json);

  return GenerateObjectResult<T>(
    object: object,
    textResult: textResult,
  );
}

/// High-level embedding helper (Vercel AI SDK-style).
///
/// This helper builds an [EmbeddingCapability] for the given `model`
/// identifier (`"provider:model"`) and calls `embed(input)` on it.
///
/// Example:
/// ```dart
/// final vectors = await embed(
///   model: 'openai:text-embedding-3-small',
///   input: ['hello', 'world'],
///   apiKey: openaiKey,
/// );
/// ```
Future<List<List<double>>> embed({
  required String model,
  required List<String> input,
  String? apiKey,
  String? baseUrl,
  CancellationToken? cancelToken,
}) async {
  registerBuiltinProviders();
  var builder = LLMBuilder().use(model);

  if (apiKey != null) {
    builder = builder.apiKey(apiKey);
  }
  if (baseUrl != null) {
    builder = builder.baseUrl(baseUrl);
  }

  final embeddingProvider = await builder.buildEmbedding();
  return embeddingProvider.embed(input, cancelToken: cancelToken);
}

/// High-level rerank helper (AI SDK-style, embedding-based).
///
/// This helper uses an embedding model (`"provider:model"`) to compute
/// cosine similarity between a [query] and the given [documents], and
/// returns a [RerankResult] with ranked documents.
///
/// It is implemented purely in terms of the generic [embed] helper, so
/// it works with any provider that supports [EmbeddingCapability]
/// (OpenAI, Google, xAI, Ollama, etc.).
///
/// Example:
/// ```dart
/// final result = await rerank(
///   model: 'openai:text-embedding-3-small',
///   query: 'rust http client',
///   documents: [
///     'How to write a HTTP client in Rust',
///     'Cooking pasta like a pro',
///   ],
/// );
///
/// for (final item in result.ranking) {
///   print('${item.score}: ${item.document.text}');
/// }
/// ```
Future<RerankResult> rerank({
  required String model,
  required String query,
  required List<String> documents,
  String? apiKey,
  String? baseUrl,
  int? topN,
  CancellationToken? cancelToken,
}) async {
  if (documents.isEmpty) {
    return RerankResult(query: query, ranking: const []);
  }

  registerBuiltinProviders();
  final builder = LLMBuilder().use(model);

  if (apiKey != null) {
    builder.apiKey(apiKey);
  }
  if (baseUrl != null) {
    builder.baseUrl(baseUrl);
  }

  final reranker = await builder.buildReranker();

  final docs = <RerankDocument>[
    for (var i = 0; i < documents.length; i++)
      RerankDocument(
        id: i.toString(),
        text: documents[i],
      ),
  ];

  return reranker.rerank(
    query: query,
    documents: docs,
    topN: topN,
    cancelToken: cancelToken,
  );
}

/// High-level image generation helper (Vercel AI SDK-style).
///
/// This helper builds an [ImageGenerationCapability] for the given
/// `model` identifier (`"provider:model"`) and issues a single
/// [ImageGenerationRequest]. The returned [ImageGenerationResponse]
/// contains URLs or binary data for the generated images.
Future<ImageGenerationResponse> generateImage({
  required String model,
  required String prompt,
  String? apiKey,
  String? baseUrl,
  String? negativePrompt,
  String? size,
  int? count,
  int? seed,
  int? steps,
  double? guidanceScale,
  bool? enhancePrompt,
  String? style,
  String? quality,
  String? responseFormat,
  String? user,
}) async {
  registerBuiltinProviders();
  var builder = LLMBuilder().use(model);

  if (apiKey != null) {
    builder = builder.apiKey(apiKey);
  }
  if (baseUrl != null) {
    builder = builder.baseUrl(baseUrl);
  }

  final imageProvider = await builder.buildImageGeneration();

  final request = ImageGenerationRequest(
    prompt: prompt,
    // Leave request.model null so providers use the configured model from
    // LLMConfig; callers control the model via the `model` identifier.
    model: null,
    negativePrompt: negativePrompt,
    size: size,
    count: count,
    seed: seed,
    steps: steps,
    guidanceScale: guidanceScale,
    enhancePrompt: enhancePrompt,
    style: style,
    quality: quality,
    responseFormat: responseFormat,
    user: user,
  );

  return imageProvider.generateImages(request);
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
  ModelMessage? structuredPrompt,
  List<ModelMessage>? promptMessages,
  CancellationToken? cancelToken,
  LanguageModelCallOptions? options,
}) {
  registerBuiltinProviders();
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
      final source = builder.streamText(
        prompt: prompt,
        structuredPrompt: structuredPrompt,
        promptMessages: promptMessages,
        cancelToken: cancelToken,
        options: options,
      );

      await for (final event in source) {
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

      final json = parseStructuredObjectJson(rawText, output.format);

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
  if (options.reasoningEffort != null) {
    builder = builder.reasoningEffort(options.reasoningEffort);
  }
  if (options.jsonSchema != null) {
    builder = builder.jsonSchema(options.jsonSchema!);
  }
  if (options.headers != null && options.headers!.isNotEmpty) {
    final existing = builder.currentConfig.getExtension<Map<String, String>>(
          LLMConfigKeys.customHeaders,
        ) ??
        const {};
    builder = builder.extension(
      LLMConfigKeys.customHeaders,
      {...existing, ...options.headers!},
    );
  }
  if (options.metadata != null && options.metadata!.isNotEmpty) {
    final existing = builder.currentConfig.getExtension<Map<String, dynamic>>(
          LLMConfigKeys.metadata,
        ) ??
        const {};
    builder = builder.extension(
      LLMConfigKeys.metadata,
      {...existing, ...options.metadata!},
    );
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
