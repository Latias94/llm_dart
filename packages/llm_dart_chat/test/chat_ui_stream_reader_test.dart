import 'package:llm_dart_chat/llm_dart_chat.dart';
import 'package:llm_dart_core/ui.dart';
import 'package:test/test.dart';

void main() {
  group('readChatUiStream', () {
    test('projects message snapshots and exposes the final message', () async {
      final result = readChatUiStream(
        messageId: 'assistant-seed',
        chunks: Stream<ChatUiStreamChunk>.fromIterable([
          ChatUiMessageStartChunk(
            messageId: 'assistant-1',
            metadata: {
              'phase': 'start',
            },
          ),
          const ChatUiEventChunk(
            TextStartEvent(id: 'text-1'),
          ),
          const ChatUiEventChunk(
            TextDeltaEvent(
              id: 'text-1',
              delta: 'Hello',
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
          ChatUiMessageFinishChunk(
            metadata: {
              'phase': 'finish',
            },
          ),
        ]),
      );

      final snapshots = await result.toList();
      final finalMessage = await result.result;

      expect(snapshots, hasLength(6));
      expect(snapshots.last.id, 'assistant-1');
      expect(
        (snapshots.last.parts.single as TextUiPart).text,
        'Hello',
      );
      expect(finalMessage.id, 'assistant-1');
      expect((finalMessage.parts.single as TextUiPart).text, 'Hello');
      expect(finalMessage.metadata['phase'], 'finish');
      expect(
        finalMessage.metadata[ChatUiMetadataKeys.finishReason],
        FinishReason.stop,
      );
      expect(await result.finishReason, FinishReason.stop);
      expect(await result.isAborted, isFalse);
    });

    test('emits step-finish snapshots separately from the main message stream',
        () async {
      final result = readChatUiStream(
        messageId: 'assistant-1',
        chunks: Stream<ChatUiStreamChunk>.fromIterable([
          const ChatUiEventChunk(
            StepStartEvent(stepId: 'step-1'),
          ),
          const ChatUiEventChunk(
            TextStartEvent(id: 'text-1'),
          ),
          const ChatUiEventChunk(
            TextDeltaEvent(
              id: 'text-1',
              delta: 'First step',
            ),
          ),
          const ChatUiEventChunk(
            TextEndEvent(id: 'text-1'),
          ),
          const ChatUiEventChunk(
            StepFinishEvent(stepId: 'step-1'),
          ),
          const ChatUiEventChunk(
            FinishEvent(
              finishReason: FinishReason.stop,
            ),
          ),
        ]),
      );

      final stepSnapshots = await result.stepFinishStream.toList();
      final finalMessage = await result.result;

      expect(stepSnapshots, hasLength(1));
      expect(stepSnapshots.single.parts.whereType<StepBoundaryUiPart>(),
          hasLength(1));
      expect(
        stepSnapshots.single.parts.whereType<TextUiPart>().single.text,
        'First step',
      );
      expect(
          finalMessage.parts.whereType<TextUiPart>().single.text, 'First step');
    });

    test('emits step observations for both start and finish boundaries',
        () async {
      final result = readChatUiStream(
        messageId: 'assistant-1',
        chunks: Stream<ChatUiStreamChunk>.fromIterable([
          const ChatUiEventChunk(
            StepStartEvent(stepId: 'step-1'),
          ),
          const ChatUiEventChunk(
            TextStartEvent(id: 'text-1'),
          ),
          const ChatUiEventChunk(
            TextDeltaEvent(
              id: 'text-1',
              delta: 'First step',
            ),
          ),
          const ChatUiEventChunk(
            TextEndEvent(id: 'text-1'),
          ),
          const ChatUiEventChunk(
            StepFinishEvent(stepId: 'step-1'),
          ),
          const ChatUiEventChunk(
            FinishEvent(
              finishReason: FinishReason.stop,
            ),
          ),
        ]),
      );

      final stepEvents = await result.stepEvents.toList();
      final finalMessage = await result.result;

      expect(stepEvents, hasLength(2));
      expect(stepEvents[0].phase, ChatUiStepObservationPhase.start);
      expect(stepEvents[0].stepId, 'step-1');
      expect(
        stepEvents[0]
            .message
            .parts
            .whereType<StepBoundaryUiPart>()
            .single
            .stepId,
        'step-1',
      );

      expect(stepEvents[1].phase, ChatUiStepObservationPhase.finish);
      expect(stepEvents[1].stepId, 'step-1');
      expect(
        stepEvents[1].message.parts.whereType<TextUiPart>().single.text,
        'First step',
      );
      expect(
        finalMessage.parts.whereType<TextUiPart>().single.text,
        'First step',
      );
    });

    test('emits transient data parts without mutating persistent message state',
        () async {
      final result = readChatUiStream(
        messageId: 'assistant-1',
        chunks: Stream<ChatUiStreamChunk>.fromIterable([
          const ChatUiTransientDataPartChunk(
            DataUiPart<String>(
              id: 'status-1',
              key: 'status',
              data: 'loading',
            ),
          ),
          const ChatUiEventChunk(
            TextStartEvent(id: 'text-1'),
          ),
          const ChatUiEventChunk(
            TextDeltaEvent(
              id: 'text-1',
              delta: 'Done',
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
        ]),
      );

      final transientParts = await result.transientDataParts.toList();
      final snapshots = await result.toList();
      final finalMessage = await result.result;

      expect(transientParts, hasLength(1));
      expect(transientParts.single.key, 'status');
      expect(transientParts.single.data, 'loading');

      expect(snapshots, hasLength(4));
      expect(finalMessage.parts.whereType<DataUiPart<Object?>>(), isEmpty);
      expect(finalMessage.parts.whereType<TextUiPart>().single.text, 'Done');
    });
  });
}
