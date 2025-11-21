/// LLM Dart Library - A modular Dart library for AI provider interactions
///
/// This library provides a unified interface for interacting with different
/// AI providers, starting with OpenAI. It's designed to be modular and
/// extensible
library;

import 'dart:async';
import 'dart:convert';

// Core exports
export 'core/capability.dart';
export 'core/cancellation.dart';
export 'core/llm_error.dart';
export 'core/config.dart';
export 'core/registry.dart';
export 'core/base_http_provider.dart';
export 'core/tool_validator.dart';
export 'core/web_search.dart';

// Model exports
export 'models/chat_models.dart';
export 'models/tool_models.dart';
export 'models/audio_models.dart';
export 'models/image_models.dart';
export 'models/file_models.dart';
export 'models/moderation_models.dart';
export 'models/assistant_models.dart';

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
export 'utils/utf8_stream_decoder.dart';
export 'utils/http_config_utils.dart';
export 'utils/logging_middleware.dart';
export 'utils/default_settings_middleware.dart';

// Convenience functions for creating providers
import 'builder/llm_builder.dart';
import 'core/capability.dart';
import 'core/llm_error.dart';
import 'models/tool_models.dart';

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
  ChatPromptMessage? structuredPrompt,
  CancelToken? cancelToken,
}) {
  var builder = LLMBuilder().use(model);

  if (apiKey != null) {
    builder = builder.apiKey(apiKey);
  }
  if (baseUrl != null) {
    builder = builder.baseUrl(baseUrl);
  }

  return builder.generateText(
    prompt: prompt,
    messages: messages,
    structuredPrompt: structuredPrompt,
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
  ChatPromptMessage? structuredPrompt,
  CancelToken? cancelToken,
}) async* {
  var builder = LLMBuilder().use(model);

  if (apiKey != null) {
    builder = builder.apiKey(apiKey);
  }
  if (baseUrl != null) {
    builder = builder.baseUrl(baseUrl);
  }

  yield* builder.streamText(
    prompt: prompt,
    messages: messages,
    structuredPrompt: structuredPrompt,
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
  ChatPromptMessage? structuredPrompt,
  CancelToken? cancelToken,
}) async {
  var builder = LLMBuilder().use(model).jsonSchema(output.format);

  if (apiKey != null) {
    builder = builder.apiKey(apiKey);
  }
  if (baseUrl != null) {
    builder = builder.baseUrl(baseUrl);
  }

  final textResult = await builder.generateText(
    prompt: prompt,
    messages: messages,
    structuredPrompt: structuredPrompt,
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
  ChatPromptMessage? structuredPrompt,
  CancelToken? cancelToken,
}) {
  var builder = LLMBuilder().use(model).jsonSchema(output.format);

  if (apiKey != null) {
    builder = builder.apiKey(apiKey);
  }
  if (baseUrl != null) {
    builder = builder.baseUrl(baseUrl);
  }

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
