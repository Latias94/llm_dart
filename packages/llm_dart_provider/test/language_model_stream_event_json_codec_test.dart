import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('LanguageModelStreamEventJsonCodec', () {
    test('round-trips provider tool stream events', () {
      const codec = LanguageModelStreamEventJsonCodec();

      final encoded = codec.encodeEvents([
        const ToolInputStartEvent(
          toolCallId: 'tool-1',
          toolName: 'weather',
          providerExecuted: true,
          isDynamic: true,
          title: 'Weather',
        ),
        const ToolInputDeltaEvent(
          toolCallId: 'tool-1',
          delta: '{"city":"Tokyo"}',
        ),
        const ToolInputEndEvent(toolCallId: 'tool-1'),
        const ToolCallEvent(
          toolCall: ToolCallContent(
            toolCallId: 'tool-1',
            toolName: 'weather',
            input: {
              'city': 'Tokyo',
            },
          ),
        ),
        const ToolApprovalRequestEvent(
          approvalId: 'approval-1',
          toolCallId: 'tool-1',
        ),
        ToolResultEvent(
          toolResult: ToolResultContent(
            toolCallId: 'tool-1',
            toolName: 'weather',
            output: 'sunny',
          ),
        ),
      ]);

      final decoded = codec.decodeEvents(encoded);

      expect(decoded, hasLength(6));
      expect(decoded[0], isA<ToolInputStartEvent>());
      expect(decoded[1], isA<ToolInputDeltaEvent>());
      expect(decoded[2], isA<ToolInputEndEvent>());
      expect(decoded[3], isA<ToolCallEvent>());
      expect(decoded[4], isA<ToolApprovalRequestEvent>());
      expect(decoded[5], isA<ToolResultEvent>());
    });

    test('rejects runtime-only tool output denial events', () {
      const codec = LanguageModelStreamEventJsonCodec();

      expect(
        () => codec.decodeEvent(
          {
            'type': 'tool-output-denied',
            'toolCallId': 'tool-1',
          },
        ),
        throwsStateError,
      );
    });
  });
}
