import 'package:test/test.dart';

import 'package:llm_dart_provider_utils/utils/jsonl_chunk_parser.dart';

void main() {
  group('JsonlChunkParser', () {
    test('buffers incomplete JSON lines across chunks', () {
      final parser = JsonlChunkParser();

      expect(parser.parseObjects('{"a":1'), isEmpty);
      expect(parser.parseObjects('}\n'), hasLength(1));
      expect(parser.parseObjects(''), isEmpty);
    });

    test('parses multiple objects and ignores malformed lines', () {
      final parser = JsonlChunkParser();
      final objects = parser.parseObjects(
        '{"a":1}\n'
        'not json\n'
        '{"b":2}\n',
      );

      expect(objects, hasLength(2));
      expect(objects[0]['a'], equals(1));
      expect(objects[1]['b'], equals(2));
    });
  });
}
