import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'http_chat_transport_chunk_json_codec.dart';
import 'http_chat_transport_stream_execution.dart';
import 'http_chat_transport_stream_request.dart';
import 'http_chat_transport_resume_state.dart';
import 'http_chat_transport_stream_session.dart';

final class HttpChatTransportStreamClient {
  final TransportClient transport;
  final SseDecoder sseDecoder;
  final HttpChatTransportChunkJsonCodec chunkCodec;

  const HttpChatTransportStreamClient({
    required this.transport,
    required this.sseDecoder,
    required this.chunkCodec,
  });

  Stream<ChatUiStreamChunk> sendPayload({
    required HttpChatTransportResumeState state,
    required Uri endpoint,
    required Map<String, String> headers,
    required Duration? requestTimeout,
    required int? maxRetries,
    required ProviderCancellation? cancellation,
    required Map<String, Object?> payload,
    required HttpChatTransportResumeStateClearer clearResumeState,
  }) async* {
    final session = HttpChatTransportStreamSession(
      state: state,
      clearResumeState: clearResumeState,
    );
    yield* session.consume(
      executeHttpChatTransportStream(
        transport: transport,
        request: buildHttpChatTransportStreamRequest(
          endpoint: endpoint,
          headers: headers,
          requestTimeout: requestTimeout,
          maxRetries: maxRetries,
          cancellation: cancellation,
          payload: payload,
        ),
        sseDecoder: sseDecoder,
        chunkCodec: chunkCodec,
      ),
    );
  }
}
