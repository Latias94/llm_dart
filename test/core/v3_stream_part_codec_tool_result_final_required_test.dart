import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('v3 stream part codec: tool-result final required', () {
    test('preliminary-only tool-result throws', () {
      expect(
        () => decodeV3StreamParts([
          {
            'type': 'tool-call',
            'toolCallId': 'id-0',
            'toolName': 'tool',
            'input': '{}',
          },
          {
            'type': 'tool-result',
            'toolCallId': 'id-0',
            'toolName': 'tool',
            'preliminary': true,
            'result': {'preview': 1},
          },
        ]),
        throwsA(isA<InvalidStreamPartError>()),
      );
    });

    test('final tool-result satisfies requirement', () {
      final parts = decodeV3StreamParts([
        {
          'type': 'tool-call',
          'toolCallId': 'id-0',
          'toolName': 'tool',
          'input': '{}',
        },
        {
          'type': 'tool-result',
          'toolCallId': 'id-0',
          'toolName': 'tool',
          'preliminary': true,
          'result': {'preview': 1},
        },
        {
          'type': 'tool-result',
          'toolCallId': 'id-0',
          'toolName': 'tool',
          'result': {'ok': true},
        },
      ]);

      expect(parts.whereType<LLMProviderToolResultPart>(), hasLength(2));
    });
  });
}
