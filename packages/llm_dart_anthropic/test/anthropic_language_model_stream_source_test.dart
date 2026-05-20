import 'dart:convert';

import 'package:llm_dart_anthropic/src/anthropic_language_model_stream.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('decodeAnthropicLanguageModelStreamEvents', () {
    test('labels malformed messages SSE payloads with source', () {
      expect(
        decodeAnthropicLanguageModelStreamEvents(
          stream: Stream.fromIterable([
            utf8.encode('data: <html>bad gateway</html>\n\n'),
          ]),
          includeRawChunks: false,
        ),
        emitsError(
          isA<TransportResponseFormatException>().having(
            (error) => error.message,
            'message',
            contains('Anthropic messages stream API returned HTML page'),
          ),
        ),
      );
    });
  });
}
