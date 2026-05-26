import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'http_chat_transport_resume_state.dart';
import 'http_chat_transport_stream_error_projection.dart';
import 'http_chat_transport_stream_execution.dart';
import 'http_chat_transport_stream_projection.dart';

/// Owns the stateful client-side stream protocol for HTTP chat transport.
///
/// The wire executor only yields frames. This session decides how those frames
/// affect replay, resume, terminal cleanup, stream termination, and recoverable
/// transport errors.
final class HttpChatTransportStreamSession {
  final HttpChatTransportResumeState state;
  final HttpChatTransportResumeStateClearer clearResumeState;

  const HttpChatTransportStreamSession({
    required this.state,
    required this.clearResumeState,
  });

  Stream<ChatUiStreamChunk> consume(
    Stream<HttpChatTransportStreamFrame> frames,
  ) async* {
    try {
      await for (final frame in frames) {
        final projected = projectFrame(frame);

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
      yield projectCaughtError(error);
    }
  }

  HttpChatTransportProjectedChunk projectFrame(
    HttpChatTransportStreamFrame frame,
  ) {
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

  ChatUiEventChunk projectCaughtError(Object error) {
    return projectHttpChatTransportCaughtError(
      error: error,
      state: state,
      clearResumeState: clearResumeState,
    );
  }
}
