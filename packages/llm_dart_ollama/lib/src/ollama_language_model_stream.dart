import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'ollama_chat_response_codec.dart';
import 'ollama_chat_stream_codec.dart';

OllamaChatStreamCodec buildOllamaChatStreamCodec({
  required OllamaChatResponseCodec responseCodec,
}) {
  return OllamaChatStreamCodec(responseCodec: responseCodec);
}

Stream<LanguageModelStreamEvent> decodeOllamaChatStreamResponse({
  required Stream<List<int>> stream,
  required OllamaChatStreamCodec streamCodec,
  required bool includeRawChunks,
}) {
  return streamCodec.decodeByteStream(
    stream,
    includeRawChunks: includeRawChunks,
  );
}
