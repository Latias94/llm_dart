import 'package:llm_dart_ai/llm_dart_ai.dart' as ai;
import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;
import 'package:test/test.dart';

void main() {
  group('TextStreamEventJsonCodec', () {
    test('is owned by the AI runtime entrypoint', () {
      const codec = ai.TextStreamEventJsonCodec();

      expect(codec, isA<ai.TextStreamEventJsonCodec>());
    });

    test('owns event implementations separately from provider events', () {
      final event = ai.StartEvent();

      expect(event, isA<ai.TextStreamEvent>());
      expect(event, isNot(isA<provider.LanguageModelStreamEvent>()));
      expect(event, isNot(isA<provider.StartEvent>()));
    });

    test('keeps the existing full-stream wire shape', () {
      const codec = ai.TextStreamEventJsonCodec();

      final encoded = codec.encodeEvents([
        const ai.RunStartEvent(runId: 'run-1'),
        const ai.StepStartEvent(stepId: 'step-1'),
        const ai.TextDeltaEvent(id: 'text-1', delta: 'Hello'),
        const ai.ToolOutputDeniedEvent(toolCallId: 'tool-1'),
        const ai.RunFinishEvent(
          runId: 'run-1',
          finishReason: ai.FinishReason.stop,
          usage: ai.UsageStats(
            inputTokens: 1,
            outputTokens: 2,
            totalTokens: 3,
          ),
        ),
        const ai.AbortEvent(reason: 'cancelled'),
      ]);

      expect(encoded['kind'], ai.TextStreamEventJsonCodec.envelopeKind);

      final decoded = codec.decodeEvents(encoded);
      expect(decoded[0], isA<ai.RunStartEvent>());
      expect(decoded[1], isA<ai.StepStartEvent>());
      expect(decoded[2], isA<ai.TextDeltaEvent>());
      expect(decoded[3], isA<ai.ToolOutputDeniedEvent>());
      expect(
        decoded[4],
        isA<ai.RunFinishEvent>().having(
          (event) => event.usage?.totalTokens,
          'total tokens',
          3,
        ),
      );
      expect(decoded[5], isA<ai.AbortEvent>());
    });
  });
}
