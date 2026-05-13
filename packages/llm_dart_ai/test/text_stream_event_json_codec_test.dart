import 'package:llm_dart_ai/llm_dart_ai.dart' as ai;
import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;
import 'package:test/test.dart';

void main() {
  group('TextStreamEventJsonCodec', () {
    test('is owned by the AI runtime entrypoint', () {
      const codec = ai.TextStreamEventJsonCodec();

      expect(codec, isA<ai.TextStreamEventJsonCodec>());
      expect(codec, isNot(isA<provider.TextStreamEventJsonCodec>()));
    });

    test('keeps the existing full-stream wire shape', () {
      const codec = ai.TextStreamEventJsonCodec();

      final encoded = codec.encodeEvents([
        const ai.StepStartEvent(stepId: 'step-1'),
        const ai.TextDeltaEvent(id: 'text-1', delta: 'Hello'),
        const ai.ToolOutputDeniedEvent(toolCallId: 'tool-1'),
        const ai.AbortEvent(reason: 'cancelled'),
      ]);

      expect(encoded['kind'], ai.TextStreamEventJsonCodec.envelopeKind);

      final decoded = codec.decodeEvents(encoded);
      expect(decoded[0], isA<ai.StepStartEvent>());
      expect(decoded[1], isA<ai.TextDeltaEvent>());
      expect(decoded[2], isA<ai.ToolOutputDeniedEvent>());
      expect(decoded[3], isA<ai.AbortEvent>());
    });
  });
}
