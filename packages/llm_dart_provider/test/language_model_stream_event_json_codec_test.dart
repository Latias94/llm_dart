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

    test('round-trips unified response metadata fields', () {
      const codec = LanguageModelStreamEventJsonCodec();
      final timestamp = DateTime.utc(2026, 5, 18, 1, 10);

      final encoded = codec.encodeEvent(
        ResponseMetadataEvent(
          responseMetadata: ModelResponseMetadata(
            id: 'resp_1',
            timestamp: timestamp,
            modelId: 'gpt-test',
            headers: const {
              'x-request-id': 'req_1',
            },
          ),
        ),
      );

      expect(encoded['responseId'], 'resp_1');
      expect(encoded['timestamp'], timestamp.toIso8601String());
      expect(encoded['modelId'], 'gpt-test');
      expect(encoded['headers'], {'x-request-id': 'req_1'});

      final decoded = codec.decodeEvent(encoded) as ResponseMetadataEvent;

      expect(decoded.responseMetadata!.id, 'resp_1');
      expect(decoded.responseMetadata!.timestamp, timestamp);
      expect(decoded.responseMetadata!.modelId, 'gpt-test');
      expect(decoded.responseMetadata!.headers['x-request-id'], 'req_1');
      expect(decoded.responseId, 'resp_1');
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
