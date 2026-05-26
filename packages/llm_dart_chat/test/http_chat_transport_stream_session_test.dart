import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_chat/src/http_chat_transport_chunk.dart';
import 'package:llm_dart_chat/src/http_chat_transport_request_payload.dart';
import 'package:llm_dart_chat/src/http_chat_transport_resume_state.dart';
import 'package:llm_dart_chat/src/http_chat_transport_stream_execution.dart';
import 'package:llm_dart_chat/src/http_chat_transport_stream_session.dart';
import 'package:test/test.dart';

void main() {
  group('HttpChatTransportStreamSession', () {
    test('status failures clear state and terminate consumption', () async {
      final state = _resumeState();
      var cleared = false;

      final chunks = await HttpChatTransportStreamSession(
        state: state,
        clearResumeState: () => cleared = true,
      )
          .consume(
            Stream.fromIterable([
              const HttpChatTransportStreamStatusFailure(503),
              const HttpChatTransportStreamReceivedChunk(
                HttpChatTransportEventChunk(
                  TextDeltaEvent(id: 'text-1', delta: 'ignored'),
                ),
              ),
            ]),
          )
          .toList();

      expect(chunks, hasLength(1));
      final event = (chunks.single as ChatUiEventChunk).event;
      final error = (event as ErrorEvent).error;
      expect(error.statusCode, 503);
      expect(error.isRetryable, isTrue);
      expect(state.replayChunks, isEmpty);
      expect(cleared, isTrue);
    });

    test('checkpointed stream errors keep reconnectable state', () async {
      final state = _resumeState();
      var cleared = false;

      final chunks = await HttpChatTransportStreamSession(
        state: state,
        clearResumeState: () => cleared = true,
      ).consume(Stream<HttpChatTransportStreamFrame>.multi((controller) {
        controller.add(
          const HttpChatTransportStreamReceivedChunk(
            HttpChatTransportCheckpointChunk(resumeToken: 'resume-1'),
          ),
        );
        controller.addError(StateError('socket closed'));
        controller.close();
      })).toList();

      expect(chunks, hasLength(1));
      final error =
          ((chunks.single as ChatUiEventChunk).event as ErrorEvent).error;
      expect(error.kind, ModelErrorKind.transport);
      expect(state.resumeToken, 'resume-1');
      expect(state.canReconnect, isTrue);
      expect(cleared, isFalse);
    });

    test('abort chunks clear state and terminate consumption', () async {
      final state = _resumeState()..resumeToken = 'resume-1';
      var cleared = false;

      final chunks = await HttpChatTransportStreamSession(
        state: state,
        clearResumeState: () => cleared = true,
      )
          .consume(
            Stream.fromIterable([
              const HttpChatTransportStreamReceivedChunk(
                HttpChatTransportAbortChunk(reason: 'cancelled'),
              ),
              const HttpChatTransportStreamReceivedChunk(
                HttpChatTransportEventChunk(
                  TextDeltaEvent(id: 'text-1', delta: 'ignored'),
                ),
              ),
            ]),
          )
          .toList();

      expect(chunks, hasLength(2));
      expect(
        (chunks.first as ChatUiEventChunk).event,
        isA<AbortEvent>()
            .having((event) => event.reason, 'reason', 'cancelled'),
      );
      expect(
        (chunks.last as ChatUiEventChunk).event,
        isA<FinishEvent>().having(
          (event) => event.finishReason,
          'finishReason',
          FinishReason.aborted,
        ),
      );
      expect(cleared, isTrue);
    });
  });
}

HttpChatTransportResumeState _resumeState() {
  return HttpChatTransportResumeState(
    callOptionsPayload: HttpChatTransportCallOptionsPayload(),
    requestTimeout: null,
    maxRetries: null,
    cancellation: null,
  );
}
