import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;
import 'package:test/test.dart';

void main() {
  group('language model stream boundary', () {
    test('streamText maps provider model-call events to runtime events',
        () async {
      final stream = streamText(
        model: _StreamModel([
          provider.StartEvent(),
          const provider.TextStartEvent(id: 'text-1'),
          const provider.TextDeltaEvent(id: 'text-1', delta: 'Hello'),
          const provider.TextEndEvent(id: 'text-1'),
          const provider.FinishEvent(
            finishReason: provider.FinishReason.stop,
          ),
        ]),
        messages: [
          UserModelMessage.text('Hello'),
        ],
      );

      await expectLater(
        stream,
        emitsInOrder([
          isA<StepStartEvent>(),
          isA<StartEvent>(),
          isA<TextStartEvent>(),
          isA<TextDeltaEvent>(),
          isA<TextEndEvent>(),
          isA<FinishEvent>(),
          isA<StepFinishEvent>(),
          emitsDone,
        ]),
      );
    });

    test('streamTextRun maps provider model-call events and final result',
        () async {
      final result = streamTextRun(
        model: _StreamModel([
          provider.StartEvent(),
          const provider.TextStartEvent(id: 'text-1'),
          const provider.TextDeltaEvent(id: 'text-1', delta: 'Hello'),
          const provider.TextEndEvent(id: 'text-1'),
          const provider.FinishEvent(
            finishReason: provider.FinishReason.stop,
          ),
        ]),
        messages: [
          UserModelMessage.text('Hello'),
        ],
      );

      await expectLater(
        result.eventStream,
        emitsInOrder([
          isA<StepStartEvent>(),
          isA<StartEvent>(),
          isA<TextStartEvent>(),
          isA<TextDeltaEvent>(),
          isA<TextEndEvent>(),
          isA<FinishEvent>(),
          isA<StepFinishEvent>(),
          emitsDone,
        ]),
      );
      expect((await result.result).text, 'Hello');
    });
  });
}

final class _StreamModel implements LanguageModel {
  final List<provider.LanguageModelStreamEvent> events;

  const _StreamModel(this.events);

  @override
  String get providerId => 'test';

  @override
  String get modelId => 'test-model';

  @override
  Future<GenerateTextResult> doGenerate(GenerateTextRequest request) async {
    return GenerateTextResult(
      content: const [],
      finishReason: FinishReason.stop,
    );
  }

  @override
  Stream<provider.LanguageModelStreamEvent> doStream(
    GenerateTextRequest request,
  ) {
    return Stream<provider.LanguageModelStreamEvent>.fromIterable(events);
  }
}
