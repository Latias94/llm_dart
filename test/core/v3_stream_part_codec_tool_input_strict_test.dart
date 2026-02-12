import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('v3 stream part codec: tool-input strictness', () {
    test('tool-input-delta without start throws', () {
      expect(
        () => decodeV3StreamParts([
          {
            'type': 'tool-input-delta',
            'id': 'id-0',
            'delta': '{"a":1',
          }
        ]),
        throwsA(isA<FormatException>()),
      );
    });

    test('tool-input-end without start throws', () {
      expect(
        () => decodeV3StreamParts([
          {
            'type': 'tool-input-end',
            'id': 'id-0',
          }
        ]),
        throwsA(isA<FormatException>()),
      );
    });

    test('duplicate tool-input-start throws', () {
      expect(
        () => decodeV3StreamParts([
          {
            'type': 'tool-input-start',
            'id': 'id-0',
            'toolName': 'tool',
          },
          {
            'type': 'tool-input-start',
            'id': 'id-0',
            'toolName': 'tool',
          },
        ]),
        throwsA(isA<FormatException>()),
      );
    });

    test('duplicate tool-input-end throws', () {
      expect(
        () => decodeV3StreamParts([
          {
            'type': 'tool-input-start',
            'id': 'id-0',
            'toolName': 'tool',
          },
          {
            'type': 'tool-input-end',
            'id': 'id-0',
          },
          {
            'type': 'tool-input-end',
            'id': 'id-0',
          },
        ]),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
