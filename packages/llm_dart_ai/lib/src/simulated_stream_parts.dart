import 'package:llm_dart_core/llm_dart_core.dart';

import 'metadata_fallbacks.dart';

Stream<LLMStreamPart> simulatedStreamPartsFromChatResponse(
  ChatResponse response, {
  required DateTime startedAtUtc,
  String? defaultModelId,
}) async* {
  yield const LLMStreamStartPart();

  if (response is ChatResponseWithRequestMetadata) {
    final request = response.requestMetadata;
    if (request != null) {
      yield request;
    }
  }

  final responseMetadata = responseMetadataWithDefaults(
    response is ChatResponseWithResponseMetadata
        ? response.responseMetadata
        : null,
    startedAtUtc,
    defaultModelId: defaultModelId,
  );
  yield responseMetadata;

  final thinking = response.thinking?.trim();
  if (thinking != null && thinking.isNotEmpty) {
    const blockId = '0';
    yield const LLMReasoningStartPart(blockId: blockId);
    yield LLMReasoningDeltaPart(thinking, blockId: blockId);
    yield LLMReasoningEndPart(thinking, blockId: blockId);
  }

  final text = response.text?.trim();
  if (text != null && text.isNotEmpty) {
    const blockId = '1';
    yield const LLMTextStartPart(blockId: blockId);
    yield LLMTextDeltaPart(text, blockId: blockId);
    yield LLMTextEndPart(text, blockId: blockId);
  }

  final toolCalls = response.toolCalls ?? const <ToolCall>[];
  for (final toolCall in toolCalls) {
    yield LLMToolInputStartPart(
      id: toolCall.id,
      toolName: toolCall.function.name,
    );
    final args = toolCall.function.arguments;
    if (args.isNotEmpty) {
      yield LLMToolInputDeltaPart(id: toolCall.id, delta: args);
    }
    yield LLMToolInputEndPart(id: toolCall.id);
  }

  yield LLMFinishPart(
    response,
    usage: response.usage,
    finishReason:
        response is ChatResponseWithFinishReason ? response.finishReason : null,
  );
}
