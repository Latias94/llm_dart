import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'ollama_api.dart';
import 'ollama_chat_response_codec.dart';
import 'ollama_tool_codec.dart';

const _ollamaTextPartId = 'ollama-text';
const _ollamaReasoningPartId = 'ollama-reasoning';

final class OllamaChatStreamCodec {
  final OllamaChatResponseCodec responseCodec;
  final OllamaToolCodec toolCodec;

  const OllamaChatStreamCodec({
    required this.responseCodec,
    this.toolCodec = const OllamaToolCodec(),
  });

  Stream<LanguageModelStreamEvent> decodeByteStream(
    Stream<List<int>> stream, {
    required bool includeRawChunks,
  }) async* {
    final utf8Decoder = Utf8StreamDecoder();
    final state = OllamaChatStreamState();
    await for (final chunk in stream) {
      final decoded = utf8Decoder.decode(chunk);
      if (decoded.isEmpty) continue;
      for (final event in decodeText(
        decoded,
        state,
        includeRawChunks: includeRawChunks,
      )) {
        yield event;
      }
    }

    final remaining = utf8Decoder.flush();
    if (remaining.isNotEmpty) {
      for (final event in decodeText(
        '$remaining\n',
        state,
        includeRawChunks: includeRawChunks,
      )) {
        yield event;
      }
    }

    for (final event in flushPendingLine(
      state,
      includeRawChunks: includeRawChunks,
    )) {
      yield event;
    }
  }

  Iterable<LanguageModelStreamEvent> decodeText(
    String chunk,
    OllamaChatStreamState state, {
    required bool includeRawChunks,
  }) sync* {
    state.buffer.write(chunk);
    final buffered = state.buffer.toString();
    final lines = buffered.split('\n');
    state.buffer
      ..clear()
      ..write(lines.removeLast());

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final json = decodeOllamaJsonObject(
        trimmed,
        responseName: 'stream chunk',
      );
      if (includeRawChunks) {
        yield RawChunkEvent(json);
      }
      yield* decodeJsonChunk(json, state);
    }
  }

  Iterable<LanguageModelStreamEvent> flushPendingLine(
    OllamaChatStreamState state, {
    required bool includeRawChunks,
  }) sync* {
    final pendingLine = state.buffer.toString().trim();
    if (pendingLine.isEmpty) {
      return;
    }

    state.buffer.clear();
    final json = decodeOllamaJsonObject(
      pendingLine,
      responseName: 'stream chunk',
    );
    if (includeRawChunks) {
      yield RawChunkEvent(json);
    }
    yield* decodeJsonChunk(json, state);
  }

  Iterable<LanguageModelStreamEvent> decodeJsonChunk(
    Map<String, Object?> json,
    OllamaChatStreamState state,
  ) sync* {
    if (!state.metadataEmitted) {
      state.metadataEmitted = true;
      yield ResponseMetadataEvent(
        modelId: responseCodec.asString(json['model']) ?? responseCodec.modelId,
        timestamp: responseCodec.parseTimestamp(json['created_at']),
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
  final StringBuffer buffer = StringBuffer();
  final Set<String> emittedToolCallIds = <String>{};
  bool metadataEmitted = false;
  bool textStarted = false;
  bool textEnded = false;
  bool reasoningStarted = false;
  bool reasoningEnded = false;
}
