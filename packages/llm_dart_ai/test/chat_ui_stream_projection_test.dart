import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('projectTextStreamEventStream', () {
    test(
        'emits message metadata, leading data parts, stream events, and final metadata',
        () async {
      final chunks = await projectTextStreamEventStream(
        Stream.fromIterable([
          StartEvent(),
          const TextStartEvent(id: 'text-1'),
          const TextDeltaEvent(id: 'text-1', delta: 'Hello'),
          const FinishEvent(finishReason: FinishReason.stop),
        ]),
        messageMetadata: const {
          'traceId': 'req-1',
        },
        leadingDataParts: const [
          DataUiPart<Object?>(
            id: 'progress',
            key: 'status',
            data: {
              'value': 0.5,
            },
          ),
        ],
        finalMessageMetadata: const {
          'persisted': true,
        },
      ).toList();

      expect(chunks, hasLength(7));

      final start = chunks[0] as ChatUiMessageStartChunk;
      expect(start.messageId, isNull);
      expect(start.metadata, {
        'traceId': 'req-1',
      });

      final leadingDataPart = chunks[1] as ChatUiDataPartChunk<Object?>;
      expect(leadingDataPart.part.id, 'progress');
      expect(leadingDataPart.part.key, 'status');
      expect(
        (leadingDataPart.part.data as Map<String, Object?>)['value'],
        0.5,
      );

      expect((chunks[2] as ChatUiEventChunk).event, isA<StartEvent>());
      expect((chunks[3] as ChatUiEventChunk).event, isA<TextStartEvent>());
      expect(
        (chunks[4] as ChatUiEventChunk).event,
        isA<TextDeltaEvent>().having((event) => event.delta, 'delta', 'Hello'),
      );
      expect((chunks[5] as ChatUiEventChunk).event, isA<FinishEvent>());

      final finish = chunks[6] as ChatUiMessageFinishChunk;
      expect(finish.metadata, {
        'persisted': true,
      });
    });
  });
}
