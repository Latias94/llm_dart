import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('ChatUiStreamAccumulator', () {
    test('merges message lifecycle chunks around shared stream events', () {
      final accumulator = ChatUiStreamAccumulator(messageId: 'local-msg');

      var message = accumulator.apply(
        ChatUiMessageStartChunk(
          messageId: 'remote-msg',
          metadata: const {
            'serverOwned': true,
          },
        ),
      );

      expect(message.id, 'remote-msg');
      expect(message.metadata['serverOwned'], isTrue);

      accumulator.apply(
        const ChatUiEventChunk(
          StepStartEvent(stepId: 'step-1'),
        ),
      );
      accumulator.apply(
        const ChatUiEventChunk(
          TextStartEvent(id: 'text-1'),
        ),
      );
      accumulator.apply(
        const ChatUiEventChunk(
          TextDeltaEvent(
            id: 'text-1',
            delta: 'Hello',
          ),
        ),
      );
      accumulator.apply(
        const ChatUiEventChunk(
          TextEndEvent(id: 'text-1'),
        ),
      );
      accumulator.apply(
        const ChatUiDataPartChunk(
          DataUiPart<Object?>(
            id: 'status',
            key: 'stream',
            data: 'streaming',
          ),
        ),
      );
      accumulator.apply(
        const ChatUiEventChunk(
          FinishEvent(
            finishReason: FinishReason.stop,
            rawFinishReason: 'stop',
          ),
        ),
      );

      message = accumulator.apply(
        ChatUiMessageFinishChunk(
          metadata: const {
            'persisted': true,
          },
        ),
      );

      expect(message.id, 'remote-msg');
      expect(message.metadata['serverOwned'], isTrue);
      expect(message.metadata['persisted'], isTrue);
      expect(message.metadata[ChatUiMetadataKeys.finishReason], FinishReason.stop);

      final textPart = message.parts.whereType<TextUiPart>().single;
      expect(textPart.text, 'Hello');
      expect(textPart.isStreaming, isFalse);

      final stepBoundary = message.parts.whereType<StepBoundaryUiPart>().single;
      expect(stepBoundary.stepId, 'step-1');

      final dataPart = message.parts.whereType<DataUiPart<Object?>>().single;
      expect(dataPart.id, 'status');
      expect(dataPart.key, 'stream');
      expect(dataPart.data, 'streaming');
    });

    test('can project a chunk stream into evolving UI messages', () async {
      final chunks = Stream<ChatUiStreamChunk>.fromIterable([
        ChatUiMessageMetadataChunk(
          metadata: const {
            'phase': 'start',
          },
        ),
        const ChatUiEventChunk(
          TextStartEvent(id: 'text-1'),
        ),
        const ChatUiEventChunk(
          TextDeltaEvent(
            id: 'text-1',
            delta: 'Hi',
          ),
        ),
        const ChatUiEventChunk(
          TextEndEvent(id: 'text-1'),
        ),
        const ChatUiEventChunk(
          FinishEvent(
            finishReason: FinishReason.stop,
          ),
        ),
      ]);

      final messages = await projectChatUiStreamChunkStream(
        chunks,
        messageId: 'assistant-1',
      ).toList();

      expect(messages, hasLength(5));
      expect(messages.last.id, 'assistant-1');
      expect(messages.last.metadata['phase'], 'start');
      expect(
        messages.last.metadata[ChatUiMetadataKeys.finishReason],
        FinishReason.stop,
      );
      expect(messages.last.parts.whereType<TextUiPart>().single.text, 'Hi');
    });
  });
}
