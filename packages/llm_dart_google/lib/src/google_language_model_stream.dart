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
  yield* decodeJsonSseLanguageModelStream(
    stream: stream,
    state: GoogleGenerateContentStreamState(),
    includeRawChunks: includeRawChunks,
    sourceName: 'Google GenerateContent stream',
    streamChunkParser: streamChunkParser,
    decodeChunk: streamCodec.decodeChunk,
    finish: streamCodec.finish,
  );
}
