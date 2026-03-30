import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('GenerateTextRunner', () {
    test('runs a single generation step and returns a run result', () async {
      final model = _RecordingLanguageModel(
        result: GenerateTextResult(
          content: const [
            TextContentPart('Runner output'),
          ],
          finishReason: FinishReason.stop,
          usage: const UsageStats(
            inputTokens: 5,
            outputTokens: 7,
            totalTokens: 12,
          ),
        ),
      );

      final runResult = await runTextGeneration(
        model: model,
        prompt: [
          UserPromptMessage.text('Hello'),
        ],
        tools: [
          FunctionToolDefinition(
            name: 'weather',
            inputSchema: ToolJsonSchema.object(),
          ),
        ],
        toolChoice: const RequiredToolChoice(),
        options: const GenerateTextOptions(
          temperature: 0.2,
        ),
        callOptions: const CallOptions(
          timeout: Duration(seconds: 30),
        ),
      );

      expect(model.lastRequest, isNotNull);
      expect(model.lastRequest!.prompt, hasLength(1));
      expect(model.lastRequest!.tools.single.name, 'weather');
      expect(model.lastRequest!.toolChoice, isA<RequiredToolChoice>());
      expect(model.lastRequest!.options.temperature, 0.2);
      expect(
          model.lastRequest!.callOptions.timeout, const Duration(seconds: 30));

      expect(runResult.steps, hasLength(1));
      expect(runResult.text, 'Runner output');
      expect(runResult.totalUsage?.totalTokens, 12);
    });

    test('invokes lifecycle callbacks in order with shared step context',
        () async {
      final callbackOrder = <String>[];
      final model = _RecordingLanguageModel(
        result: GenerateTextResult(
          content: const [
            TextContentPart('Done'),
          ],
          finishReason: FinishReason.stop,
        ),
      );

      GenerateTextRequest? startedRequest;
      GenerateTextStepResult? finishedStep;
      GenerateTextRunResult? finishedRun;

      final runResult = await GenerateTextRunner(
        model: model,
        prompt: [
          UserPromptMessage.text('Hello'),
        ],
        onStepStart: (event) async {
          callbackOrder.add('start');
          startedRequest = event.request;
          expect(event.stepNumber, 0);
          expect(event.providerId, 'test');
          expect(event.modelId, 'test-model');
          expect(event.previousSteps, isEmpty);
        },
        onStepFinish: (step) async {
          callbackOrder.add('step-finish');
          finishedStep = step;
          expect(step.stepNumber, 0);
          expect(step.request, same(startedRequest));
          expect(step.text, 'Done');
        },
        onFinish: (run) async {
          callbackOrder.add('finish');
          finishedRun = run;
          expect(run.steps.single, same(finishedStep));
        },
      ).run();

      expect(callbackOrder, ['start', 'step-finish', 'finish']);
      expect(runResult, same(finishedRun));
      expect(runResult.lastStep, same(finishedStep));
    });
  });
}

final class _RecordingLanguageModel implements LanguageModel {
  final GenerateTextResult result;
  GenerateTextRequest? lastRequest;

  _RecordingLanguageModel({
    required this.result,
  });

  @override
  String get modelId => 'test-model';

  @override
  String get providerId => 'test';

  @override
  Future<GenerateTextResult> generate(GenerateTextRequest request) async {
    lastRequest = request;
    return result;
  }

  @override
  Stream<TextStreamEvent> stream(GenerateTextRequest request) async* {
    lastRequest = request;
    yield const FinishEvent(
      finishReason: FinishReason.stop,
    );
  }
}
