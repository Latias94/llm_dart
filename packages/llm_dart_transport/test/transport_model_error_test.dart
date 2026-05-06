import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('transportErrorToModelError', () {
    test('maps HTTP transport exceptions into structured transport errors', () {
      final error = transportErrorToModelError(
        TransportHttpException(
          'Bad gateway',
          statusCode: 502,
          headers: {
            'retry-after': '1',
          },
          responseBody: {
            'message': 'upstream failed',
          },
          uri: Uri(
            scheme: 'https',
            host: 'example.com',
            path: '/chat',
          ),
        ),
      );

      expect(error.kind, ModelErrorKind.transport);
      expect(error.code, 'transport-http');
      expect(error.statusCode, 502);
      expect(error.isRetryable, isTrue);
      expect(
        error.details,
        {
          'uri': 'https://example.com/chat',
          'headers': {
            'retry-after': '1',
          },
          'responseBody': {
            'message': 'upstream failed',
          },
        },
      );
    });
  });
}
