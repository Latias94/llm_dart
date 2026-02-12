import 'package:llm_dart_provider_utils/utils/response_metadata_sanitizer.dart';
import 'package:test/test.dart';

void main() {
  group('sanitizeResponseHeadersForMetadata', () {
    test('lowercases keys', () {
      final out = sanitizeResponseHeadersForMetadata(
        const {'X-Test': '1'},
      );
      expect(out, containsPair('x-test', '1'));
      expect(out.containsKey('X-Test'), isFalse);
    });

    test('redacts sensitive keys', () {
      final out = sanitizeResponseHeadersForMetadata(
        const {
          'Authorization': 'Bearer secret',
          'Set-Cookie': 'a=b',
          'X-Api-Key': 'k',
          'X-Goog-Api-Key': 'k2',
        },
      );
      expect(out['authorization'], equals('[REDACTED]'));
      expect(out['set-cookie'], equals('[REDACTED]'));
      expect(out['x-api-key'], equals('[REDACTED]'));
      expect(out['x-goog-api-key'], equals('[REDACTED]'));
    });

    test('truncates long values', () {
      final out = sanitizeResponseHeadersForMetadata(
        {'x-long': 'a' * 1000},
        maxValueLength: 10,
      );
      expect(out['x-long'], equals('a' * 10));
    });
  });
}
