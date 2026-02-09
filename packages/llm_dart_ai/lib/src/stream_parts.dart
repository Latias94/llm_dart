import 'package:llm_dart_core/llm_dart_core.dart';

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
  yield const LLMStreamStartPart();
  yield* _streamChatPartsInternal(
    model: model,
    system: system,
    prompt: prompt,
    messages: messages,
    promptIr: promptIr,
    tools: tools,
    cancelToken: cancelToken,
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
        yield* (partsCapable as ChatStreamPartsCapability).chatStreamParts(
          messages,
          tools: tools,
          cancelToken: cancelToken,
        );
        return;
      }

      yield* _streamChatPartsFromEvents(
        model.chatStream(
          messages,
          tools: tools,
          cancelToken: cancelToken,
        ),
      );

    case StandardizedPromptIr(:final prompt):
      if (model is PromptChatStreamPartsCapability) {
        yield* (model as PromptChatStreamPartsCapability).chatPromptStreamParts(
          prompt,
          tools: tools,
          cancelToken: cancelToken,
        );
        return;
      }

      if (model is PromptChatCapability) {
        yield* _streamChatPartsFromEvents(
          (model as PromptChatCapability).chatPromptStream(
            prompt,
            tools: tools,
            cancelToken: cancelToken,
          ),
        );
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

Stream<LLMStreamPart> _streamChatPartsFromEvents(
  Stream<ChatStreamEvent> events,
) async* {
  var inText = false;
  var inThinking = false;

  final fullText = StringBuffer();
  final fullThinking = StringBuffer();
  final currentText = StringBuffer();
  final currentThinking = StringBuffer();

  String? currentTextBlockId;
  String? currentThinkingBlockId;
  var blockCounter = 0;

  final startedToolCalls = <String>{};
  final endedToolCalls = <String>{};

  await for (final event in events) {
    switch (event) {
      case TextDeltaEvent(:final delta):
        if (inThinking) {
          inThinking = false;
          yield LLMReasoningEndPart(
            currentThinking.toString(),
            blockId: currentThinkingBlockId,
          );
          currentThinking.clear();
          currentThinkingBlockId = null;
        }
        if (!inText) {
          inText = true;
          currentTextBlockId ??= '${blockCounter++}';
          yield LLMTextStartPart(blockId: currentTextBlockId);
          currentText.clear();
        }
        fullText.write(delta);
        currentText.write(delta);
        yield LLMTextDeltaPart(delta, blockId: currentTextBlockId);

      case ThinkingDeltaEvent(:final delta):
        if (inText) {
          inText = false;
          yield LLMTextEndPart(
            currentText.toString(),
            blockId: currentTextBlockId,
          );
          currentText.clear();
          currentTextBlockId = null;
        }
        if (!inThinking) {
          inThinking = true;
          currentThinkingBlockId ??= '${blockCounter++}';
          yield LLMReasoningStartPart(blockId: currentThinkingBlockId);
          currentThinking.clear();
        }
        fullThinking.write(delta);
        currentThinking.write(delta);
        yield LLMReasoningDeltaPart(delta, blockId: currentThinkingBlockId);

      case ToolCallDeltaEvent(:final toolCall):
        if (!startedToolCalls.contains(toolCall.id)) {
          startedToolCalls.add(toolCall.id);
          yield LLMToolCallStartPart(toolCall);
        } else {
          yield LLMToolCallDeltaPart(toolCall);
        }

      case CompletionEvent(:final response):
        if (inText) {
          yield LLMTextEndPart(
            currentText.toString(),
            blockId: currentTextBlockId,
          );
          inText = false;
          currentText.clear();
          currentTextBlockId = null;
        }
        if (inThinking) {
          yield LLMReasoningEndPart(
            currentThinking.toString(),
            blockId: currentThinkingBlockId,
          );
          inThinking = false;
          currentThinking.clear();
          currentThinkingBlockId = null;
        }
        for (final toolCallId in startedToolCalls) {
          if (endedToolCalls.add(toolCallId)) {
            yield LLMToolCallEndPart(toolCallId);
          }
        }

        final providerMetadata = response.providerMetadata;
        if (providerMetadata != null && providerMetadata.isNotEmpty) {
          yield LLMProviderMetadataPart(providerMetadata);
        }

        yield LLMFinishPart(response);

      case ErrorEvent(:final error):
        yield LLMErrorPart(error);
    }
  }
}
