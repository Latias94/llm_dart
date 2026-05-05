import 'package:llm_dart_ai/internal.dart';
import 'package:test/test.dart';

void main() {
  group('parsePartialJson', () {
    test('returns undefined-input for null input', () {
      final result = parsePartialJson(null);

      expect(result.value, isNull);
      expect(result.state, PartialJsonParseState.undefinedInput);
    });

    test('parses valid JSON directly', () {
      final result = parsePartialJson('{"key":"value"}');

      expect(result.value, {'key': 'value'});
      expect(result.state, PartialJsonParseState.successfulParse);
    });

    test('repairs truncated JSON objects', () {
      final result = parsePartialJson('{"key":"value"');

      expect(result.value, {'key': 'value'});
      expect(result.state, PartialJsonParseState.repairedParse);
    });

    test('returns failed-parse for irreparable text', () {
      final result = parsePartialJson('not json at all');

      expect(result.value, isNull);
      expect(result.state, PartialJsonParseState.failedParse);
    });
  });
}
