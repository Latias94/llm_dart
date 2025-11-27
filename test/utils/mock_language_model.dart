import 'dart:async';
import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

/// Mock implementation of [LanguageModel] for unit tests.
///
/// This model is designed to test high-level helpers without hitting
/// real providers. It records the last messages and options that were
/// passed to it and delegates result generation to injectable handlers.
class MockLanguageModel implements LanguageModel {
  @override
  final String providerId;

  @override
  final String modelId;

  @override
  final LLMConfig config;

  /// Last raw ChatMessage list passed into any method.
  List<ChatMessage>? lastMessages;

  /// Last prompt-first ModelMessage list derived from [lastMessages].
  List<ModelMessage>? lastPromptMessages;

  /// Last per-call options passed into any `*WithOptions` method.
  LanguageModelCallOptions? lastOptions;

  /// Optional handler used by [generateTextWithOptions].
  ///
  /// The handler receives the resolved prompt-first messages and
  /// the call options and is expected to return a [GenerateTextResult].
  final Future<GenerateTextResult> Function(
    List<ModelMessage> messages,
    LanguageModelCallOptions? options,
  )? doGenerate;

  /// Optional handler used by [streamTextWithOptions].
  ///
  /// The handler receives the resolved prompt-first messages and
  /// the call options and is expected to return a stream of
  /// [ChatStreamEvent] values.
  final Stream<ChatStreamEvent> Function(
    List<ModelMessage> messages,
    LanguageModelCallOptions? options,
  )? doStream;

  MockLanguageModel({
    this.providerId = 'mock',
    this.modelId = 'mock-model',
    LLMConfig? config,
    this.doGenerate,
    this.doStream,
  }) : config = config ?? LLMConfig(baseUrl: '', model: 'mock-model');

  List<ModelMessage> _toPromptMessages(List<ChatMessage> messages) {
    return messages
        .map((message) => message.toPromptMessage())
        .toList(growable: false);
  }

  void _record(List<ChatMessage> messages, LanguageModelCallOptions? options) {
    lastMessages = messages;
    lastPromptMessages = _toPromptMessages(messages);
    lastOptions = options;
  }

  @override
  Future<GenerateTextResult> generateText(
    List<ChatMessage> messages, {
    CancellationToken? cancelToken,
  }) {
    return generateTextWithOptions(
      messages,
      options: null,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<ChatStreamEvent> streamText(
    List<ChatMessage> messages, {
    CancellationToken? cancelToken,
  }) {
    return streamTextWithOptions(
      messages,
      options: null,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<StreamTextPart> streamTextParts(
    List<ChatMessage> messages, {
    CancellationToken? cancelToken,
  }) {
    return adaptStreamText(
      streamText(messages, cancelToken: cancelToken),
    );
  }

  @override
  Future<GenerateObjectResult<T>> generateObject<T>(
    OutputSpec<T> output,
    List<ChatMessage> messages, {
    CancellationToken? cancelToken,
  }) {
    return generateObjectWithOptions<T>(
      output,
      messages,
      options: null,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<GenerateTextResult> generateTextWithOptions(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    _record(messages, options);

    if (doGenerate != null) {
      return doGenerate!(
        lastPromptMessages ?? const <ModelMessage>[],
        options,
      );
    }

    final response = _SimpleTestChatResponse(text: 'ok');

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
  Stream<ChatStreamEvent> streamTextWithOptions(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    _record(messages, options);

    if (doStream != null) {
      return doStream!(
        lastPromptMessages ?? const <ModelMessage>[],
        options,
      );
    }

    return Stream<ChatStreamEvent>.fromIterable(<ChatStreamEvent>[
      const TextDeltaEvent('chunk'),
      CompletionEvent(_SimpleTestChatResponse(text: 'ok')),
    ]);
  }

  @override
  Stream<StreamTextPart> streamTextPartsWithOptions(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return adaptStreamText(
      streamTextWithOptions(
        messages,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  @override
  Future<GenerateObjectResult<T>> generateObjectWithOptions<T>(
    OutputSpec<T> output,
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    final textResult = await generateTextWithOptions(
      messages,
      options: options,
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

/// Minimal [ChatResponse] implementation used by [MockLanguageModel].
class _SimpleTestChatResponse implements ChatResponse {
  @override
  final String? text;

  const _SimpleTestChatResponse({this.text});

  @override
  List<ToolCall>? get toolCalls => const [];

  @override
  UsageInfo? get usage => const UsageInfo(
        promptTokens: 1,
        completionTokens: 1,
        totalTokens: 2,
      );

  @override
  String? get thinking => null;

  @override
  List<CallWarning> get warnings => const [];

  @override
  Map<String, dynamic>? get metadata => null;

  @override
  CallMetadata? get callMetadata => null;
}
