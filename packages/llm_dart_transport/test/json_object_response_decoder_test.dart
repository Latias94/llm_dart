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

    test('parses JSON strings into maps', () {
      final result = JsonObjectResponseDecoder.decode(
        '{"message":"hello"}',
        sourceName: 'Test',
      );

      expect(result, {'message': 'hello'});
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
