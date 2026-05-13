// ignore_for_file: implementation_imports

import 'package:llm_dart_ai/internal.dart';
import 'package:llm_dart_ai/llm_dart_ai.dart' as ai;
import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;
import 'package:llm_dart_provider/src/stream/text_stream_event.dart'
    as provider_legacy;
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

    test('rejects runtime-only events from provider streams', () async {
      final events = adaptLanguageModelStreamEvents(
        Stream<provider.LanguageModelStreamEvent>.fromIterable([
          const provider_legacy.StepStartEvent(stepId: 'step-1'),
        ]),
      );

      await expectLater(events, emitsError(isA<StateError>()));
    });
  });
}
