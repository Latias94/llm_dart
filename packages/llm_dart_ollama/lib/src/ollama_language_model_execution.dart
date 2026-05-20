import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'ollama_chat_request_codec.dart';
import 'ollama_chat_stream_codec.dart';
import 'ollama_language_model_stream.dart';

Stream<LanguageModelStreamEvent> sendOllamaChatStreamCall({
  required TransportClient transport,
  required TransportRequest request,
  required OllamaPreparedChatRequest preparedRequest,
  required OllamaChatStreamCodec streamCodec,
  required bool includeRawChunks,
}) async* {
  yield* startOllamaChatStream(preparedRequest: preparedRequest);

  try {
    final response = await transport.sendStream(request);

    yield* decodeOllamaChatStreamResponse(
      stream: response.stream,
      streamCodec: streamCodec,
      includeRawChunks: includeRawChunks,
    );
  } catch (error) {
    yield ollamaChatStreamErrorEvent(error);
  }
}
