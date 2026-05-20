import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'google_stream_codec.dart';

Stream<LanguageModelStreamEvent> decodeGoogleLanguageModelStreamEvents({
  required Stream<List<int>> stream,
  required bool includeRawChunks,
  GoogleGenerateContentStreamCodec streamCodec =
      const GoogleGenerateContentStreamCodec(),
  SseJsonChunkParser streamChunkParser = const SseJsonChunkParser(),
}) async* {
  final state = GoogleGenerateContentStreamState();
  await for (final chunk in streamChunkParser.parse(
    stream,
    sourceName: 'Google GenerateContent stream',
  )) {
    if (includeRawChunks) {
      yield RawChunkEvent(chunk);
    }
    for (final event in streamCodec.decodeChunk(
      chunk,
      state,
    )) {
      yield event;
    }
  }

  for (final event in streamCodec.finish(state)) {
    yield event;
  }
}
