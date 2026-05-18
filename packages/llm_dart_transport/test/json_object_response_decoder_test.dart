import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('JsonObjectResponseDecoder', () {
    test('returns maps unchanged', () {
      final result = JsonObjectResponseDecoder.decode(
        const {'ok': true},
        sourceName: 'Test',
      );

      expect(result, {'ok': true});
    });

    test('copies generic maps into string-keyed JSON objects', () {
      final result = JsonObjectResponseDecoder.decode(
        {'ok': true, 'count': 1},
        sourceName: 'Test',
      );

      expect(result, isA<Map<String, Object?>>());
      expect(result, {'ok': true, 'count': 1});
    });

    test('parses JSON strings into maps', () {
      final result = JsonObjectResponseDecoder.decode(
        '{"message":"hello"}',
        sourceName: 'Test',
      );

      expect(result, {'message': 'hello'});
    });

    test('throws response-format error for JSON arrays', () {
      expect(
        () => JsonObjectResponseDecoder.decode(
          '["not","object"]',
          sourceName: 'Test',
        ),
        throwsA(
          isA<TransportResponseFormatException>().having(
            (error) => error.message,
            'message',
            contains('JSON that is not an object'),
          ),
        ),
      );
    });

    test('throws response-format error for non-string map keys', () {
      expect(
        () => JsonObjectResponseDecoder.decode(
          {1: 'bad'},
          sourceName: 'Test',
        ),
        throwsA(
          isA<TransportResponseFormatException>().having(
            (error) => error.message,
            'message',
            contains('non-string key'),
          ),
        ),
      );
    });

    test('throws transport response-format error for HTML bodies', () {
      expect(
        () => JsonObjectResponseDecoder.decode(
          '<html>forbidden</html>',
          sourceName: 'Test',
        ),
        throwsA(
          isA<TransportResponseFormatException>()
              .having(
                (error) => error.message,
                'message',
                contains('HTML page instead of JSON response'),
              )
              .having(
                (error) => error.responseBody,
                'responseBody',
                '<html>forbidden</html>',
              ),
        ),
      );
    });
  });
}
