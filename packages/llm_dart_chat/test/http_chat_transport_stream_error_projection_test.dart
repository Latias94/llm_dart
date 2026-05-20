import 'package:llm_dart_chat/src/http_chat_transport_request_payload.dart';
import 'package:llm_dart_chat/src/http_chat_transport_resume_state.dart';
import 'package:llm_dart_chat/src/http_chat_transport_stream_error_projection.dart';
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('HttpChatTransportStreamErrorProjection', () {
    test('projects status failures with retryability', () {
      final retryable = projectHttpChatTransportStatusError(503);
      final nonRetryable = projectHttpChatTransportStatusError(400);

      final retryableError = (retryable.event as ErrorEvent).error;
      expect(retryableError.code, 'http-transport-status');
      expect(retryableError.statusCode, 503);
      expect(retryableError.isRetryable, isTrue);

      final nonRetryableError = (nonRetryable.event as ErrorEvent).error;
      expect(nonRetryableError.statusCode, 400);
      expect(nonRetryableError.isRetryable, isFalse);
    });

    test('keeps reconnectable stream errors without clearing resume state', () {
      final state = _resumeState()..resumeToken = 'resume-1';
      var cleared = false;

      final chunk = projectHttpChatTransportCaughtError(
        error: StateError('socket closed'),
        state: state,
        clearResumeState: () => cleared = true,
      );

      final error = (chunk.event as ErrorEvent).error;
      expect(error.kind, ModelErrorKind.transport);
      expect(error.originalType, 'StateError');
      expect(cleared, isFalse);
    });

    test('clears non-reconnectable stream errors', () {
      final state = _resumeState();
      var cleared = false;

      projectHttpChatTransportCaughtError(
        error: FormatException('bad stream'),
        state: state,
        clearResumeState: () => cleared = true,
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
