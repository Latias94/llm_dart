import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('prepareHeaders', () {
    test('adds default headers when missing', () {
      final out = prepareHeaders(
        const {'x-test': '1'},
        const {'content-type': 'text/plain'},
      );

      expect(out['x-test'], equals('1'));
      expect(out['content-type'], equals('text/plain'));
    });

    test('does not override existing headers (case-insensitive)', () {
      final out = prepareHeaders(
        const {'Content-Type': 'application/json'},
        const {'content-type': 'text/plain'},
      );

      expect(out['Content-Type'], equals('application/json'));
      expect(out.containsKey('content-type'), isFalse);
    });
  });
}

