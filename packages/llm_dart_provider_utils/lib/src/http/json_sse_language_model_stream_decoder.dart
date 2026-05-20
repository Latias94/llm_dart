import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

typedef JsonSseLanguageModelStreamChunkDecoder<State>
    = Iterable<LanguageModelStreamEvent> Function(
  Map<String, Object?> chunk,
  State state,
);

typedef JsonSseLanguageModelStreamFinishDecoder<State>
    = Iterable<LanguageModelStreamEvent> Function(
  State state,
);

Stream<LanguageModelStreamEvent> decodeJsonSseLanguageModelStream<State>({
  required Stream<List<int>> stream,
  required State state,
  required JsonSseLanguageModelStreamChunkDecoder<State> decodeChunk,
  JsonSseLanguageModelStreamFinishDecoder<State>? finish,
  bool includeRawChunks = false,
  SseJsonChunkParser streamChunkParser = const SseJsonChunkParser(),
  String sourceName = 'SSE stream chunk',
  bool Function(SseFrame frame)? shouldSkipFrame,
}) async* {
  await for (final chunk in streamChunkParser.parse(
    stream,
    sourceName: sourceName,
    shouldSkipFrame: shouldSkipFrame,
  )) {
    if (includeRawChunks) {
      yield RawChunkEvent(chunk);
    }

    for (final event in decodeChunk(chunk, state)) {
      yield event;
    }
  }

  final finishDecoder = finish;
  if (finishDecoder == null) {
    return;
  }

  for (final event in finishDecoder(state)) {
    yield event;
  }
}
