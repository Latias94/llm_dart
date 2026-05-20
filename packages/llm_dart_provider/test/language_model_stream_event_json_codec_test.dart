import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('LanguageModelStreamEventJsonCodec', () {
    test('round-trips provider tool stream events', () {
      const codec = LanguageModelStreamEventJsonCodec();

      final encoded = codec.encodeEvents([
        StartEvent(
          warnings: const [
            ModelWarning(
              type: ModelWarningType.unsupported,
              message: 'temperature is ignored',
              feature: 'temperature',
            ),
          ],
        ),
        ResponseMetadataEvent(
          responseMetadata: ModelResponseMetadata(
            id: 'resp_1',
            timestamp: DateTime.utc(2026, 5, 20, 1, 30),
            modelId: 'gpt-test',
          ),
          providerMetadata: ProviderMetadata.forNamespace('openai', {
            'itemId': 'msg_1',
          }),
        ),
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
        const FinishEvent(
          finishReason: FinishReason.toolCalls,
          usage: UsageStats(
            inputTokens: 3,
            outputTokens: 5,
            totalTokens: 8,
          ),
        ),
      ]);

      final decoded = codec.decodeEvents(encoded);

      expect(decoded, hasLength(9));
      expect(decoded[0], isA<StartEvent>());
      expect(decoded[1], isA<ResponseMetadataEvent>());
      expect(decoded[2], isA<ToolInputStartEvent>());
      expect(decoded[3], isA<ToolInputDeltaEvent>());
      expect(decoded[4], isA<ToolInputEndEvent>());
      expect(decoded[5], isA<ToolCallEvent>());
      expect(decoded[6], isA<ToolApprovalRequestEvent>());
      expect(decoded[7], isA<ToolResultEvent>());
      expect(decoded[8], isA<FinishEvent>());
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
