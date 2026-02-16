import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('v3 stream part codec: tool-call/tool-result strictness', () {
    test('duplicate tool-call is allowed (fixture parity)', () {
      final parts = decodeV3StreamParts([
        {
          'type': 'tool-call',
          'toolCallId': 'id-0',
          'toolName': 'tool',
          'input': '{}',
        },
        {
          'type': 'tool-call',
          'toolCallId': 'id-0',
          'toolName': 'tool',
          'input': '{}',
        },
      ]);

      expect(parts.whereType<LLMProviderToolCallPart>(), hasLength(2));
    });

    test('tool-result toolName mismatch throws', () {
      expect(
        () => decodeV3StreamParts([
          {
            'type': 'tool-call',
            'toolCallId': 'id-0',
            'toolName': 'toolA',
            'input': '{}',
          },
          {
            'type': 'tool-result',
            'toolCallId': 'id-0',
            'toolName': 'toolB',
            'result': {'ok': true},
          },
        ]),
        throwsA(isA<InvalidStreamPartError>()),
      );
    });

    test('duplicate final tool-result throws', () {
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
            'result': {'ok': true},
          },
          {
            'type': 'tool-result',
            'toolCallId': 'id-0',
            'toolName': 'tool',
            'result': {'ok': true},
          },
        ]),
        throwsA(isA<InvalidStreamPartError>()),
      );
    });

    test('preliminary tool-result may repeat before final', () {
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
          'result': {'n': 1},
        },
        {
          'type': 'tool-result',
          'toolCallId': 'id-0',
          'toolName': 'tool',
          'preliminary': true,
          'result': {'n': 2},
        },
        {
          'type': 'tool-result',
          'toolCallId': 'id-0',
          'toolName': 'tool',
          'result': {'ok': true},
        },
      ]);

      expect(parts.whereType<LLMProviderToolResultPart>(), hasLength(3));
    });

    test('tool-result after final throws (even if preliminary)', () {
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
            'result': {'ok': true},
          },
          {
            'type': 'tool-result',
            'toolCallId': 'id-0',
            'toolName': 'tool',
            'preliminary': true,
            'result': {'n': 1},
          },
        ]),
        throwsA(isA<InvalidStreamPartError>()),
      );
    });

    test('tool-approval-request requires a known toolCallId', () {
      expect(
        () => decodeV3StreamParts([
          {
            'type': 'tool-approval-request',
            'approvalId': 'appr-1',
            'toolCallId': 'id-0',
          },
        ]),
        throwsA(isA<InvalidStreamPartError>()),
      );
    });

    test('duplicate approvalId throws', () {
      expect(
        () => decodeV3StreamParts([
          {
            'type': 'tool-call',
            'toolCallId': 'id-0',
            'toolName': 'tool',
            'input': '{}',
          },
          {
            'type': 'tool-approval-request',
            'approvalId': 'appr-1',
            'toolCallId': 'id-0',
          },
          {
            'type': 'tool-approval-request',
            'approvalId': 'appr-1',
            'toolCallId': 'id-0',
          },
        ]),
        throwsA(isA<InvalidStreamPartError>()),
      );
    });
  });
}
