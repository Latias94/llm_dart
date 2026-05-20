import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'http_chat_transport_chunk_json_codec.dart';
import 'http_chat_transport_resume_state.dart';
import 'http_chat_transport_stream_error_projection.dart';
import 'http_chat_transport_stream_execution.dart';
import 'http_chat_transport_stream_projection.dart';
import 'http_chat_transport_stream_request.dart';

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
      await for (final frame in executeHttpChatTransportStream(
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
      )) {
        final projected = _projectFrame(
          frame: frame,
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
      yield projectHttpChatTransportCaughtError(
        error: error,
        state: state,
        clearResumeState: clearResumeState,
      );
    }
  }

  HttpChatTransportProjectedChunk _projectFrame({
    required HttpChatTransportStreamFrame frame,
    required HttpChatTransportResumeState state,
    required HttpChatTransportResumeStateClearer clearResumeState,
  }) {
    return switch (frame) {
      HttpChatTransportStreamStatusFailure(:final statusCode) => () {
          clearResumeState();
          return HttpChatTransportEmitChunk(
            projectHttpChatTransportStatusError(statusCode),
            terminateStream: true,
          );
        }(),
      HttpChatTransportStreamReceivedChunk(:final chunk) =>
        projectHttpChatTransportChunk(
          chunk: chunk,
          state: state,
          clearResumeState: clearResumeState,
        ),
    };
  }
}
