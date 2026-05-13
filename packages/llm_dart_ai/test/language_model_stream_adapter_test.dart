import 'package:llm_dart_ai/internal.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('adaptLanguageModelStreamEvents', () {
    test('forwards provider model-call events as runtime text events',
        () async {
      final events = adaptLanguageModelStreamEvents(
        Stream<LanguageModelStreamEvent>.fromIterable([
          StartEvent(),
          const TextDeltaEvent(id: 'text-1', delta: 'Hello'),
          const FinishEvent(finishReason: FinishReason.stop),
        ]),
      );

      await expectLater(
        events,
        emitsInOrder([
          isA<StartEvent>(),
          isA<TextDeltaEvent>(),
          isA<FinishEvent>(),
          emitsDone,
        ]),
      );
    });

    test('rejects runtime-only events from provider streams', () async {
      final events = adaptLanguageModelStreamEvents(
        Stream<LanguageModelStreamEvent>.fromIterable([
          const StepStartEvent(stepId: 'step-1'),
        ]),
      );

      await expectLater(events, emitsError(isA<StateError>()));
    });
  });
}
