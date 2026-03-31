import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('TransportRetryPolicy', () {
    test('uses retry-after header when available', () {
      const policy = TransportRetryPolicy(
        maxAttempts: 2,
        baseDelay: Duration(milliseconds: 50),
      );
      final context = TransportRetryContext(
        request: TransportRequest(
          uri: Uri.parse('https://example.com/chat'),
          method: TransportMethod.post,
        ),
        attempt: 1,
        isStreaming: false,
        error: TransportHttpException(
          'busy',
          statusCode: 429,
          headers: const {
            'retry-after': '3',
          },
        ),
      );

      expect(policy.shouldRetry(context), isTrue);
      expect(policy.delayFor(context), const Duration(seconds: 3));
    });

    test('falls back to exponential backoff when retry-after is absent', () {
      const policy = TransportRetryPolicy(
        maxAttempts: 3,
        baseDelay: Duration(milliseconds: 100),
        backoffMultiplier: 2,
      );
      final context = TransportRetryContext(
        request: TransportRequest(
          uri: Uri.parse('https://example.com/chat'),
          method: TransportMethod.post,
        ),
        attempt: 2,
        isStreaming: false,
        error: const TransportTimeoutException('timeout'),
      );

      expect(policy.delayFor(context), const Duration(milliseconds: 200));
    });
  });
}
