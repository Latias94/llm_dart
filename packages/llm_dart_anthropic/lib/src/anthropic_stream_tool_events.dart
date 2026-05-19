import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_stream_tool_models.dart';

ToolCallContent anthropicProjectedToolCallContent(
  AnthropicProjectedToolCall call,
) {
  return ToolCallContent(
    toolCallId: call.toolCallId,
    toolName: call.toolName,
    input: call.input,
    providerExecuted: call.providerExecuted,
    isDynamic: call.isDynamic,
    title: call.title,
  );
}

Iterable<LanguageModelStreamEvent> emitAnthropicFinishedToolInputEvents(
  AnthropicFinishedToolInputProjection projection,
) sync* {
  final error = projection.errorEvent;
  if (error != null) {
    yield error;
    return;
  }

  final call = projection.toolCall;
  if (call == null) {
    return;
  }

  yield ToolInputEndEvent(
    toolCallId: call.toolCallId,
    providerMetadata: call.providerMetadata,
  );
  yield ToolCallEvent(
    toolCall: anthropicProjectedToolCallContent(call),
    providerMetadata: call.providerMetadata,
  );
}

Iterable<LanguageModelStreamEvent> emitAnthropicToolInputStartEvents(
  AnthropicProjectedToolCall call,
) sync* {
  yield ToolInputStartEvent(
    toolCallId: call.toolCallId,
    toolName: call.toolName,
    providerExecuted: call.providerExecuted,
    isDynamic: call.isDynamic,
    title: call.title,
    providerMetadata: call.providerMetadata,
  );

  if (call.encodedInput.isNotEmpty) {
    yield ToolInputDeltaEvent(
      toolCallId: call.toolCallId,
      delta: call.encodedInput,
      providerMetadata: call.providerMetadata,
    );
  }
}

Iterable<LanguageModelStreamEvent> emitAnthropicProjectedToolCallEvents(
  AnthropicProjectedToolCall call,
) sync* {
  yield* emitAnthropicToolInputStartEvents(call);
  yield ToolInputEndEvent(
    toolCallId: call.toolCallId,
    providerMetadata: call.providerMetadata,
  );
  yield ToolCallEvent(
    toolCall: anthropicProjectedToolCallContent(call),
    providerMetadata: call.providerMetadata,
  );
}

extension AnthropicFinishedToolInputProjectionEvents
    on AnthropicFinishedToolInputProjection {
  Iterable<LanguageModelStreamEvent> emitEvents() {
    return emitAnthropicFinishedToolInputEvents(this);
  }
}
