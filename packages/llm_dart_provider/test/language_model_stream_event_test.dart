import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider/src/stream/text_stream_event.dart'
    as provider_legacy;
import 'package:test/test.dart';

void main() {
  group('LanguageModelStreamEvent', () {
    test('accepts provider model-call events', () {
      final events = <LanguageModelStreamEvent>[
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
      ];

      for (final event in events) {
        expect(isLanguageModelStreamEvent(event), isTrue);
        expect(
          () => validateLanguageModelStreamEvent(event),
          returnsNormally,
        );
      }
    });

    test('rejects runtime-only events', () {
      final events = <LanguageModelStreamEvent>[
        const provider_legacy.StepStartEvent(stepId: 'step-1'),
        const provider_legacy.StepFinishEvent(stepId: 'step-1'),
        const provider_legacy.ToolOutputDeniedEvent(toolCallId: 'tool-1'),
        const provider_legacy.AbortEvent(reason: 'cancelled'),
      ];

      for (final event in events) {
        expect(isLanguageModelStreamEvent(event), isFalse);
        expect(
          () => validateLanguageModelStreamEvent(event),
          throwsA(isA<StateError>()),
        );
      }
    });

    test('validates event streams', () async {
      final stream = validateLanguageModelStreamEvents(
        Stream<LanguageModelStreamEvent>.fromIterable([
          StartEvent(),
          const TextDeltaEvent(id: 'text-1', delta: 'Hello'),
          const FinishEvent(finishReason: FinishReason.stop),
        ]),
      );

      await expectLater(
        stream,
        emitsInOrder([
          isA<StartEvent>(),
          isA<TextDeltaEvent>(),
          isA<FinishEvent>(),
          emitsDone,
        ]),
      );
    });
  });
}
