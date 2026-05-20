import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'anthropic_stream_codec.dart';

Stream<LanguageModelStreamEvent> decodeAnthropicLanguageModelStreamEvents({
  required Stream<List<int>> stream,
  required bool includeRawChunks,
  AnthropicStreamCodec streamCodec = const AnthropicStreamCodec(),
  SseJsonChunkParser streamChunkParser = const SseJsonChunkParser(),
}) async* {
  final state = AnthropicMessagesStreamState();
  await for (final chunk in streamChunkParser.parse(
    stream,
    sourceName: 'Anthropic messages stream',
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
}
