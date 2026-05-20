import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'ollama_chat_response_codec.dart';
import 'ollama_tool_codec.dart';

const _ollamaTextPartId = 'ollama-text';
const _ollamaReasoningPartId = 'ollama-reasoning';

final class OllamaChatStreamCodec {
  final OllamaChatResponseCodec responseCodec;
  final OllamaToolCodec toolCodec;
  final NdjsonJsonChunkParser streamChunkParser;

  const OllamaChatStreamCodec({
    required this.responseCodec,
    this.toolCodec = const OllamaToolCodec(),
    this.streamChunkParser = const NdjsonJsonChunkParser(),
  });

  Stream<LanguageModelStreamEvent> decodeByteStream(
    Stream<List<int>> stream, {
    required bool includeRawChunks,
  }) async* {
    final state = OllamaChatStreamState();
    await for (final json in streamChunkParser.parse(
      stream,
      sourceName: 'Ollama stream chunk',
    )) {
      for (final event in decodeJsonChunk(
        json,
        state,
        includeRawChunks: includeRawChunks,
      )) {
        yield event;
      }
    }
  }

  Iterable<LanguageModelStreamEvent> decodeJsonChunk(
    Map<String, Object?> json,
    OllamaChatStreamState state, {
    required bool includeRawChunks,
  }) sync* {
    if (includeRawChunks) {
      yield RawChunkEvent(json);
    }

    if (!state.metadataEmitted) {
      state.metadataEmitted = true;
      yield ResponseMetadataEvent(
        responseMetadata: ModelResponseMetadata(
          timestamp: responseCodec.parseTimestamp(json['created_at']),
          modelId:
              responseCodec.asString(json['model']) ?? responseCodec.modelId,
        ),
        providerMetadata: responseCodec.decodeProviderMetadata(json),
      );
    }

    final message = responseCodec.asObject(json['message']);
    final thinking = responseCodec.asString(message?['thinking']);
    if (thinking != null && thinking.isNotEmpty) {
      if (!state.reasoningStarted) {
        state.reasoningStarted = true;
        yield const ReasoningStartEvent(id: _ollamaReasoningPartId);
      }
      yield ReasoningDeltaEvent(id: _ollamaReasoningPartId, delta: thinking);
    }

    final text = responseCodec.asString(message?['content']);
    if (text != null && text.isNotEmpty) {
      if (!state.textStarted) {
        state.textStarted = true;
        yield const TextStartEvent(id: _ollamaTextPartId);
      }
      yield TextDeltaEvent(id: _ollamaTextPartId, delta: text);
    }

    final toolCalls = toolCodec.decodeToolCalls(message);
    for (final toolCall in toolCalls) {
      if (!state.emittedToolCallIds.add(toolCall.toolCallId)) continue;
      yield ToolCallEvent(toolCall: toolCall);
    }

    if (json['done'] != true) return;

    if (state.reasoningStarted && !state.reasoningEnded) {
      state.reasoningEnded = true;
      yield const ReasoningEndEvent(id: _ollamaReasoningPartId);
    }

    if (state.textStarted && !state.textEnded) {
      state.textEnded = true;
      yield const TextEndEvent(id: _ollamaTextPartId);
    }

    yield FinishEvent(
      finishReason: responseCodec.decodeFinishReason(
        json,
        hasToolCalls: state.emittedToolCallIds.isNotEmpty,
      ),
      rawFinishReason: responseCodec.asString(json['done_reason']),
      usage: responseCodec.decodeUsage(json),
      providerMetadata: responseCodec.decodeProviderMetadata(json),
    );
  }
}

final class OllamaChatStreamState {
  final Set<String> emittedToolCallIds = <String>{};
  bool metadataEmitted = false;
  bool textStarted = false;
  bool textEnded = false;
  bool reasoningStarted = false;
  bool reasoningEnded = false;
}
