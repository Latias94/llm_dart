import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('LogSanitizer', () {
    test('redacts sensitive query parameters from endpoints', () {
      final sanitized = LogSanitizer.sanitizeEndpoint(
        'https://example.com/v1/chat?api_key=secret&token=secret&keep=value',
      );

      expect(sanitized, contains('api_key=%2A%2A%2A'));
      expect(sanitized, contains('token=%2A%2A%2A'));
      expect(sanitized, contains('keep=value'));
      expect(sanitized, isNot(contains('secret')));
    });

    test('redacts sensitive headers while preserving normal headers', () {
      final sanitized = LogSanitizer.sanitizeHeaders({
        'Authorization': 'Bearer secret',
        'X-Api-Key': 'abc',
        'X-Trace-Id': 'trace-1',
        'proxy-authorization': 'Basic secret',
      });

      expect(sanitized['Authorization'], '***');
      expect(sanitized['X-Api-Key'], '***');
      expect(sanitized['proxy-authorization'], '***');
      expect(sanitized['X-Trace-Id'], 'trace-1');
    });
  });
}
