import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
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
}) {
  return sendProviderLanguageModelStreamRequest(
    transport: transport,
    request: request,
    warnings: preparedRequest.warnings,
    includeRawChunks: includeRawChunks,
    decode: ({required stream, required includeRawChunks}) {
      return decodeOllamaChatStreamResponse(
        stream: stream,
        streamCodec: streamCodec,
        includeRawChunks: includeRawChunks,
      );
    },
  );
}
