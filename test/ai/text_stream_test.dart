import 'dart:convert';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('text stream (ai-sdk style)', () {
    test('textStreamHeadersV1 sets content-type to text/plain; charset=utf-8',
        () {
      expect(
        textStreamHeadersV1,
        containsPair('content-type', 'text/plain; charset=utf-8'),
      );
    });

    test('utf8BytesFromTextStream encodes chunks without concatenation',
        () async {
      final bytes = await utf8BytesFromTextStream(
        Stream<String>.fromIterable(const ['a', '中', '\n']),
      ).toList();

      expect(bytes.length, equals(3));
      expect(utf8.decode(bytes[0]), equals('a'));
      expect(utf8.decode(bytes[1]), equals('中'));
      expect(utf8.decode(bytes[2]), equals('\n'));
    });
  });
}
