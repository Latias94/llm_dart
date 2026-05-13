import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('LanguageModelStreamEventJsonCodec', () {
    test('round-trips provider language model stream events', () {
      const codec = LanguageModelStreamEventJsonCodec();

      final encoded = codec.encodeEvents([
        StartEvent(),
        const ResponseMetadataEvent(responseId: 'response-1'),
        const TextStartEvent(id: 'text-1'),
        const TextDeltaEvent(id: 'text-1', delta: 'Hello'),
        const TextEndEvent(id: 'text-1'),
        const ToolApprovalRequestEvent(
          approvalId: 'approval-1',
          toolCallId: 'tool-1',
        ),
        const FinishEvent(finishReason: FinishReason.stop),
      ]);

      expect(encoded['kind'], LanguageModelStreamEventJsonCodec.envelopeKind);

      final decoded = codec.decodeEvents(encoded);
      expect(decoded, hasLength(7));
      expect(decoded[1], isA<ResponseMetadataEvent>());
      expect(decoded[3], isA<TextDeltaEvent>());
      expect(decoded.last, isA<FinishEvent>());
    });

    test('rejects runtime-only events during decoding', () {
      const codec = LanguageModelStreamEventJsonCodec();

      expect(
        () => codec.decodeEvent({
          'type': 'tool-output-denied',
          'toolCallId': 'tool-1',
        }),
        throwsA(isA<StateError>()),
      );
      expect(
        () => codec.decodeEvents({
          'schemaVersion': llmDartJsonSchemaVersion,
          'kind': LanguageModelStreamEventJsonCodec.envelopeKind,
          'data': {
            'events': [
              {'type': 'start', 'warnings': []},
              {'type': 'step-start', 'stepId': 'step-1'},
            ],
          },
        }),
        throwsA(isA<StateError>()),
      );
    });
  });
}
