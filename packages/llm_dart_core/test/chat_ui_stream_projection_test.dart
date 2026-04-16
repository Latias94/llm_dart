import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('projectTextStreamEventStream', () {
    test('wraps shared events with shared UI message lifecycle chunks',
        () async {
      final chunks = await projectTextStreamEventStream(
        Stream<TextStreamEvent>.fromIterable([
          const TextStartEvent(id: 'text-1'),
          const TextDeltaEvent(
            id: 'text-1',
            delta: 'Hello',
          ),
          const TextEndEvent(id: 'text-1'),
          const FinishEvent(
            finishReason: FinishReason.stop,
          ),
        ]),
        messageId: 'assistant-1',
        messageMetadata: const {
          'serverOwned': true,
        },
        leadingDataParts: const [
          DataUiPart<Object?>(
            id: 'status',
            key: 'stream',
            data: {
              'phase': 'running',
            },
          ),
        ],
        finalMessageMetadata: const {
          'persisted': true,
        },
      ).toList();

      final start = chunks[0] as ChatUiMessageStartChunk;
      expect(start.messageId, 'assistant-1');
      expect(start.metadata['serverOwned'], isTrue);

      final dataPartChunk = chunks[1] as ChatUiDataPartChunk<Object?>;
      expect(dataPartChunk.part.id, 'status');
      expect(dataPartChunk.part.key, 'stream');
      expect(
        (dataPartChunk.part.data as Map<String, Object?>)['phase'],
        'running',
      );

      expect((chunks[2] as ChatUiEventChunk).event, isA<TextStartEvent>());
      expect(
        ((chunks[3] as ChatUiEventChunk).event as TextDeltaEvent).delta,
        'Hello',
      );
      expect((chunks[4] as ChatUiEventChunk).event, isA<TextEndEvent>());
      expect((chunks[5] as ChatUiEventChunk).event, isA<FinishEvent>());

      final finish = chunks[6] as ChatUiMessageFinishChunk;
      expect(finish.metadata['persisted'], isTrue);
    });

    test('omits message lifecycle chunks when no metadata patch is provided',
        () async {
      final chunks = await projectTextStreamEventStream(
        Stream<TextStreamEvent>.fromIterable([
          const TextStartEvent(id: 'text-1'),
          const FinishEvent(
            finishReason: FinishReason.stop,
          ),
        ]),
      ).toList();

      expect(chunks, hasLength(2));
      expect((chunks[0] as ChatUiEventChunk).event, isA<TextStartEvent>());
      expect((chunks[1] as ChatUiEventChunk).event, isA<FinishEvent>());
    });
  });
}
