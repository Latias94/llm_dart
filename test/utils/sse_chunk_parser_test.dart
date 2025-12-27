import 'package:test/test.dart';

import 'package:llm_dart_provider_utils/utils/sse_chunk_parser.dart';

void main() {
  group('SseChunkParser', () {
    test('parses data lines and associates last event', () {
      final parser = SseChunkParser();
      final lines = parser.parse(
        'event: message_start\n'
        'data: {"type":"message_start"}\n'
        '\n'
        'data: {"type":"message_delta"}\n',
      );

      expect(lines, hasLength(2));
      expect(lines[0].event, equals('message_start'));
      expect(lines[0].data, equals('{"type":"message_start"}'));
      expect(lines[1].event, isNull);
      expect(lines[1].data, equals('{"type":"message_delta"}'));
    });

    test('buffers incomplete lines across chunks', () {
      final parser = SseChunkParser();

      expect(parser.parse('data: {"a":'), isEmpty);

      final lines = parser.parse('1}\n');
      expect(lines, hasLength(1));
      expect(lines.single.data, equals('{"a":1}'));
    });

    test('ignores comment lines', () {
      final parser = SseChunkParser();
      final lines = parser.parse(
        ': ping\n'
        'data: ok\n',
      );
      expect(lines, hasLength(1));
      expect(lines.single.data, equals('ok'));
    });
  });
}
