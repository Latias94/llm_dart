import 'dart:convert';

import 'package:llm_dart_google/src/google_language_model_stream.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('decodeGoogleLanguageModelStreamEvents', () {
    test('labels malformed GenerateContent SSE payloads with source', () {
      expect(
        decodeGoogleLanguageModelStreamEvents(
          stream: Stream.fromIterable([
            utf8.encode('data: ["not","object"]\n\n'),
          ]),
          includeRawChunks: false,
        ),
        emitsError(
          isA<TransportResponseFormatException>().having(
            (error) => error.message,
            'message',
            contains(
              'Google GenerateContent stream API returned JSON that is not an object',
            ),
          ),
        ),
      );
    });
  });
}
