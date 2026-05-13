// ignore_for_file: implementation_imports

import 'package:llm_dart_ai/llm_dart_ai.dart' as ai;
import 'package:llm_dart_provider/src/serialization/text_stream_event_json_codec.dart'
    as provider_codec;
import 'package:llm_dart_provider/src/stream/text_stream_event.dart'
    as provider_stream;
import 'package:test/test.dart';

void main() {
  group('TextStreamEventJsonCodec', () {
    test('is owned by the AI runtime entrypoint', () {
      const codec = ai.TextStreamEventJsonCodec();

      expect(codec, isA<ai.TextStreamEventJsonCodec>());
      expect(codec, isNot(isA<provider_codec.TextStreamEventJsonCodec>()));
    });

    test('owns event implementations separately from provider events', () {
      final event = ai.StartEvent();

      expect(event, isA<ai.TextStreamEvent>());
      expect(event, isNot(isA<provider_stream.TextStreamEvent>()));
      expect(event, isNot(isA<provider_stream.StartEvent>()));
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
