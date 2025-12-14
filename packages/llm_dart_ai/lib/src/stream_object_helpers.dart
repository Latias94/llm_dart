// Streaming structured output helpers that operate on LanguageModel instances.

library;

import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

/// Streaming structured object helper.
///
/// This mirrors the bundle-level `streamObject(...)` helper but operates on a
/// pre-configured [LanguageModel] instance.
///
/// Assumption: the given [model] is already configured to emit JSON that
/// matches [output.format] (for example via provider-specific model settings).
class StreamObjectResult<T> {
  /// Stream of chat events (thinking, text deltas, tool calls, completion).
  final Stream<ChatStreamEvent> events;

  /// Future that resolves to the structured object result once the stream
  /// completes and JSON parsing succeeds.
  final Future<GenerateObjectResult<T>> asObject;

  const StreamObjectResult({
    required this.events,
    required this.asObject,
  });
}

/// Stream a structured object using an existing [LanguageModel].
StreamObjectResult<T> streamObjectWithModel<T>({
  required LanguageModel model,
  required OutputSpec<T> output,
  String? prompt,
  ModelMessage? structuredPrompt,
  List<ModelMessage>? promptMessages,
  CancellationToken? cancelToken,
  LanguageModelCallOptions? options,
}) {
  final resolvedMessages = resolvePromptMessagesForTextGeneration(
    prompt: prompt,
    structuredPrompt: structuredPrompt,
    promptMessages: promptMessages,
  );

  final controller = StreamController<ChatStreamEvent>();
  final completer = Completer<GenerateObjectResult<T>>();
  final buffer = StringBuffer();
  ChatResponse? finalResponse;

  () async {
    try {
      final source = model.streamTextWithOptions(
        resolvedMessages,
        options: options,
        cancelToken: cancelToken,
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

/// Simple [ChatResponse] implementation used when no provider-specific
/// response is available (e.g. when providers don't emit CompletionEvent).
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
