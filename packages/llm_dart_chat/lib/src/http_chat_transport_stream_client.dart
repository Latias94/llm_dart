import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'http_chat_transport_chunk_json_codec.dart';
import 'http_chat_transport_resume_state.dart';
import 'http_chat_transport_stream_projection.dart';

typedef HttpChatTransportResumeStateClearer = void Function();

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
    try {
      final response = await transport.sendStream(
        TransportRequest(
          uri: endpoint,
          method: TransportMethod.post,
          headers: {
            ...headers,
          },
          body: payload,
          timeout: requestTimeout,
          maxRetries: maxRetries,
          cancellation: cancellation,
          responseType: TransportResponseType.plainText,
        ),
      );

      if (response.statusCode >= 400) {
        clearResumeState();
        yield ChatUiEventChunk(
          ErrorEvent(
            ModelError(
              kind: ModelErrorKind.transport,
              message: 'HTTP chat transport request failed.',
              code: 'http-transport-status',
              statusCode: response.statusCode,
              isRetryable: response.statusCode >= 500 ||
                  response.statusCode == 408 ||
                  response.statusCode == 409 ||
                  response.statusCode == 429,
            ),
          ),
        );
        return;
      }

      final parser = SseJsonChunkParser(sseDecoder: sseDecoder);
      await for (final envelope in parser.parse(response.stream)) {
        final chunk = chunkCodec.decodeChunk(envelope);
        final projected = projectHttpChatTransportChunk(
          chunk: chunk,
          state: state,
          clearResumeState: clearResumeState,
        );

        switch (projected) {
          case HttpChatTransportEmitChunk(
              :final chunks,
              :final terminateStream,
            ):
            yield* Stream<ChatUiStreamChunk>.fromIterable(chunks);
            if (terminateStream) {
              return;
            }
          case HttpChatTransportNoopChunk():
            break;
        }
      }
    } catch (error) {
      if (!state.canReconnect) {
        clearResumeState();
      }
      yield ChatUiEventChunk(
        ErrorEvent(transportErrorToModelError(error)),
      );
    }
  }
}
