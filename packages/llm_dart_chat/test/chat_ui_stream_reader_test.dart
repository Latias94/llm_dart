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

    test('validates merged message metadata patches before projection',
        () async {
      final metadataContexts = <ChatUiMessageMetadataValidationContext>[];

      final result = readChatUiStream(
        messageId: 'assistant-seed',
        messageMetadataValidator: (context) {
          metadataContexts.add(context);

          if (context.nextMetadata['phase'] is! String) {
            throw FormatException('phase must stay a string');
          }
        },
        chunks: Stream<ChatUiStreamChunk>.fromIterable([
          ChatUiMessageStartChunk(
            messageId: 'assistant-1',
            metadata: const {
              'phase': 'start',
            },
          ),
          const ChatUiEventChunk(
            FinishEvent(
              finishReason: FinishReason.stop,
            ),
          ),
          ChatUiMessageFinishChunk(
            metadata: const {
              'phase': 'finish',
            },
          ),
        ]),
      );

      final snapshots = await result.toList();
      final finalMessage = await result.result;

      expect(metadataContexts, hasLength(2));
      expect(metadataContexts[0].phase,
          ChatUiMessageMetadataValidationPhase.start);
      expect(metadataContexts[0].messageId, 'assistant-1');
      expect(metadataContexts[0].currentMetadata, isEmpty);
      expect(metadataContexts[0].nextMetadata['phase'], 'start');

      expect(
        metadataContexts[1].phase,
        ChatUiMessageMetadataValidationPhase.finish,
      );
      expect(
        metadataContexts[1].currentMetadata[ChatUiMetadataKeys.finishReason],
        FinishReason.stop,
      );
      expect(metadataContexts[1].patch['phase'], 'finish');
      expect(metadataContexts[1].nextMetadata['phase'], 'finish');

      expect(snapshots.last.metadata['phase'], 'finish');
      expect(
        finalMessage.metadata[ChatUiMetadataKeys.finishReason],
        FinishReason.stop,
      );
    });

    test('fails when message metadata validation rejects a patch', () async {
      final reader = ChatUiStreamReader(
        messageId: 'assistant-1',
        messageMetadataValidator: (context) {
          final phase = context.nextMetadata['phase'];
          if (phase is! String) {
            throw FormatException('phase must be a string');
          }
        },
      );

      await reader.consume(
        Stream<ChatUiStreamChunk>.fromIterable([
          ChatUiMessageMetadataChunk(
            metadata: const {
              'phase': 1,
            },
          ),
        ]),
      );

      await expectLater(
        reader.readResult.result,
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'phase must be a string',
          ),
        ),
      );
    });

    test('validates persistent and transient data parts separately', () async {
      final dataContexts = <ChatUiDataPartValidationContext>[];

      final result = readChatUiStream(
        messageId: 'assistant-1',
        dataPartValidator: dataContexts.add,
        chunks: Stream<ChatUiStreamChunk>.fromIterable([
          const ChatUiTransientDataPartChunk(
            DataUiPart<String>(
              id: 'status-1',
              key: 'status',
              data: 'loading',
            ),
          ),
          const ChatUiDataPartChunk(
            DataUiPart<Object?>(
              id: 'progress',
              key: 'status',
              data: {
                'value': 1.0,
              },
            ),
          ),
          const ChatUiEventChunk(
            FinishEvent(
              finishReason: FinishReason.stop,
            ),
          ),
        ]),
      );

      final snapshots = await result.toList();
      final finalMessage = await result.result;

      expect(dataContexts, hasLength(2));
      expect(dataContexts[0].isTransient, isTrue);
      expect(dataContexts[0].part.id, 'status-1');
      expect(dataContexts[0].message.parts, isEmpty);

      expect(dataContexts[1].isTransient, isFalse);
      expect(dataContexts[1].part.id, 'progress');

      expect(
          snapshots.last.parts.whereType<DataUiPart<Object?>>(), hasLength(1));
      expect(finalMessage.parts.whereType<DataUiPart<Object?>>().single.id,
          'progress');
    });

    test('fails when data validation rejects a transient part', () async {
      final reader = ChatUiStreamReader(
        messageId: 'assistant-1',
        dataPartValidator: (context) {
          if (context.isTransient) {
            throw FormatException('transient data is disabled');
          }
        },
      );

      await reader.consume(
        Stream<ChatUiStreamChunk>.fromIterable([
          const ChatUiTransientDataPartChunk(
            DataUiPart<String>(
              id: 'status-1',
              key: 'status',
              data: 'loading',
            ),
          ),
        ]),
      );

      await expectLater(
        reader.readResult.result,
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'transient data is disabled',
          ),
        ),
      );
    });
  });
}
