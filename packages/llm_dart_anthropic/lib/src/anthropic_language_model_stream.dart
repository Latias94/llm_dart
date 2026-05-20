import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'anthropic_stream_codec.dart';

Stream<LanguageModelStreamEvent> decodeAnthropicLanguageModelStreamEvents({
  required Stream<List<int>> stream,
  required bool includeRawChunks,
  AnthropicStreamCodec streamCodec = const AnthropicStreamCodec(),
  SseJsonChunkParser streamChunkParser = const SseJsonChunkParser(),
}) async* {
  yield* decodeJsonSseLanguageModelStream(
    stream: stream,
    state: AnthropicMessagesStreamState(),
    includeRawChunks: includeRawChunks,
    sourceName: 'Anthropic messages stream',
    streamChunkParser: streamChunkParser,
    decodeChunk: streamCodec.decodeChunk,
  );
}
