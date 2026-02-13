import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('ui message chunk builders', () {
    test('uiChunkStart includes optional fields', () {
      expect(
        uiChunkStart(),
        equals(const {'type': 'start'}),
      );

      expect(
        uiChunkStart(messageId: 'm1', messageMetadata: const {'x': 1}),
        equals(const {
          'type': 'start',
          'messageId': 'm1',
          'messageMetadata': {'x': 1},
        }),
      );
    });

    test('uiChunkFinish includes optional fields', () {
      expect(
        uiChunkFinish(),
        equals(const {'type': 'finish'}),
      );

      expect(
        uiChunkFinish(finishReason: 'stop', messageMetadata: const {'y': 2}),
        equals(const {
          'type': 'finish',
          'finishReason': 'stop',
          'messageMetadata': {'y': 2},
        }),
      );
    });

    test('uiChunkData produces data-* type', () {
      expect(
        uiChunkData('foo', const {'a': 1}),
        equals(const {'type': 'data-foo', 'data': {'a': 1}}),
      );

      expect(
        uiChunkData('bar', 123, id: 'id1', transient: true),
        equals(const {
          'type': 'data-bar',
          'id': 'id1',
          'data': 123,
          'transient': true,
        }),
      );
    });
  });
}

