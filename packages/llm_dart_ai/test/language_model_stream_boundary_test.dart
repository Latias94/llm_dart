import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('language model stream boundary', () {
    test('streamText rejects runtime-only events from provider streams',
        () async {
      final stream = streamText(
        model: _StreamModel([
          const StepStartEvent(stepId: 'step-1'),
        ]),
        messages: [
          UserModelMessage.text('Hello'),
        ],
      );

      await expectLater(stream, emitsError(isA<StateError>()));
    });

    test('streamTextRun rejects runtime-only events from provider streams',
        () async {
      final result = streamTextRun(
        model: _StreamModel([
          const StepStartEvent(stepId: 'step-1'),
        ]),
        messages: [
          UserModelMessage.text('Hello'),
        ],
      );

      await Future.wait([
        expectLater(result.eventStream, emitsError(isA<StateError>())),
        expectLater(result.result, throwsA(isA<StateError>())),
      ]);
    });
  });
}

final class _StreamModel implements LanguageModel {
  final List<TextStreamEvent> events;

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
  Stream<TextStreamEvent> doStream(GenerateTextRequest request) {
    return Stream<TextStreamEvent>.fromIterable(events);
  }
}
