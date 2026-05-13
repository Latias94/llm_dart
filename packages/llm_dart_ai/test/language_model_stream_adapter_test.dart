import 'package:llm_dart_ai/internal.dart';
import 'package:llm_dart_ai/llm_dart_ai.dart' as ai;
import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;
import 'package:test/test.dart';

void main() {
  group('adaptLanguageModelStreamEvents', () {
    test('forwards provider model-call events as runtime text events',
        () async {
      final events = adaptLanguageModelStreamEvents(
        Stream<provider.LanguageModelStreamEvent>.fromIterable([
          provider.StartEvent(),
          const provider.TextDeltaEvent(id: 'text-1', delta: 'Hello'),
          const provider.FinishEvent(finishReason: ai.FinishReason.stop),
        ]),
      );

      await expectLater(
        events,
        emitsInOrder([
          isA<ai.StartEvent>(),
          isA<ai.TextDeltaEvent>(),
          isA<ai.FinishEvent>(),
          emitsDone,
        ]),
      );
    });

    test('rejects runtime-only AI events when converting back to provider', () {
      expect(
        () => textStreamEventToProvider(
          const ai.StepStartEvent(stepId: 'step-1'),
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        () => textStreamEventToProvider(
          const ai.RunStartEvent(runId: 'run-1'),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
