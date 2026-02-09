import 'package:llm_dart_core/llm_dart_core.dart';

import 'ensure_stream_start.dart';
import 'prompt_input.dart';

export 'package:llm_dart_core/core/stream_parts.dart';

/// Stream chat as provider-agnostic stream parts (Vercel-style).
///
/// This is a forward-compatible surface that adds block boundaries and allows
/// provider-native tools/metadata to be observed without forcing a "perfect"
/// abstraction.
Stream<LLMStreamPart> streamChatParts({
  required ChatCapability model,
  String? system,
  String? prompt,
  List<ChatMessage>? messages,
  Prompt? promptIr,
  List<Tool>? tools,
  CancelToken? cancelToken,
}) async* {
  yield* ensureStreamStartPart(
    _streamChatPartsInternal(
      model: model,
      system: system,
      prompt: prompt,
      messages: messages,
      promptIr: promptIr,
      tools: tools,
      cancelToken: cancelToken,
    ),
  );
}

Stream<LLMStreamPart> _streamChatPartsInternal({
  required ChatCapability model,
  String? system,
  String? prompt,
  List<ChatMessage>? messages,
  Prompt? promptIr,
  List<Tool>? tools,
  CancelToken? cancelToken,
}) async* {
  final input = standardizePromptInput(
    system: system,
    prompt: prompt,
    messages: messages,
    promptIr: promptIr,
  );

  switch (input) {
    case StandardizedChatMessages(:final messages):
      final partsCapable = model;
      if (partsCapable is ChatStreamPartsCapability) {
        await for (final part
            in (partsCapable as ChatStreamPartsCapability).chatStreamParts(
          messages,
          tools: tools,
          cancelToken: cancelToken,
        )) {
          switch (part) {
            case LLMFinishPart(
                response: final response,
                usage: final usage,
                finishReason: final finishReason,
              ):
              yield LLMFinishPart(
                response,
                usage: usage ?? response.usage,
                finishReason: finishReason ??
                    (response is ChatResponseWithFinishReason
                        ? response.finishReason
                        : null),
              );
            default:
              yield part;
          }
        }
        return;
      }

      throw UnsupportedError(
        'Model does not support parts-first streaming. Implement '
        '`ChatStreamPartsCapability.chatStreamParts()` (or use a provider that does).',
      );

    case StandardizedPromptIr(:final prompt):
      if (model is PromptChatStreamPartsCapability) {
        await for (final part
            in (model as PromptChatStreamPartsCapability).chatPromptStreamParts(
          prompt,
          tools: tools,
          cancelToken: cancelToken,
        )) {
          switch (part) {
            case LLMFinishPart(
                response: final response,
                usage: final usage,
                finishReason: final finishReason,
              ):
              yield LLMFinishPart(
                response,
                usage: usage ?? response.usage,
                finishReason: finishReason ??
                    (response is ChatResponseWithFinishReason
                        ? response.finishReason
                        : null),
              );
            default:
              yield part;
          }
        }
        return;
      }

      yield* _streamChatPartsInternal(
        model: model,
        messages: prompt.toChatMessages(),
        tools: tools,
        cancelToken: cancelToken,
      );
  }
}

/// Stream chat as provider-agnostic stream parts from a `Prompt` IR (legacy helper).
@Deprecated('Use streamChatParts(model: ..., promptIr: ...) instead.')
Stream<LLMStreamPart> streamChatPartsFromPromptIr({
  required ChatCapability model,
  required Prompt prompt,
  List<Tool>? tools,
  CancelToken? cancelToken,
}) {
  return streamChatParts(
    model: model,
    promptIr: prompt,
    tools: tools,
    cancelToken: cancelToken,
  );
}

/// Stream chat parts from a plain prompt (legacy helper).
@Deprecated(
    'Use streamChatParts(model: ..., system: ..., prompt: ...) instead.')
Stream<LLMStreamPart> streamChatPartsFromPrompt({
  required ChatCapability model,
  required String prompt,
  String? systemPrompt,
  List<Tool>? tools,
  CancelToken? cancelToken,
}) {
  return streamChatParts(
    model: model,
    system: systemPrompt,
    prompt: prompt,
    tools: tools,
    cancelToken: cancelToken,
  );
}
