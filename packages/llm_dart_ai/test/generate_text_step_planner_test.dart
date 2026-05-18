import 'package:llm_dart_ai/src/model/generate_text_step_planner.dart';
import 'package:llm_dart_ai/src/model/generate_text_step_result.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('GenerateTextStepPlanner', () {
    test('plans provider request and step-start event from completed steps',
        () {
      final model = _PlannerLanguageModel();
      final tool = FunctionToolDefinition(
        name: 'weather',
        inputSchema: ToolJsonSchema.object(),
      );
      final planner = GenerateTextStepPlanner(
        runnerName: 'TestRunner',
        model: model,
        tools: [
          tool,
        ],
        toolChoice: const RequiredToolChoice(),
        options: const GenerateTextOptions(
          temperature: 0.2,
        ),
        callOptions: const CallOptions(
          timeout: Duration(seconds: 30),
        ),
        maxSteps: 3,
      );
      final previousStep = _step(0);

      final plan = planner.planNextStep(
        promptHistory: [
          UserPromptMessage.text('next'),
        ],
        previousSteps: [
          previousStep,
        ],
      );

      expect(plan.stepNumber, 1);
      expect(plan.request.prompt.single, isA<UserPromptMessage>());
      expect(plan.request.tools.single, same(tool));
      expect(plan.request.toolChoice, isA<RequiredToolChoice>());
      expect(plan.request.options.temperature, 0.2);
      expect(plan.request.callOptions.timeout, const Duration(seconds: 30));
      expect(plan.startEvent.stepNumber, 1);
      expect(plan.startEvent.providerId, 'test-provider');
      expect(plan.startEvent.modelId, 'test-model');
      expect(plan.startEvent.request, same(plan.request));
      expect(plan.startEvent.previousSteps.single, same(previousStep));
      expect(
        () => plan.startEvent.previousSteps.add(previousStep),
        throwsUnsupportedError,
      );
      expect(planner.declaredToolNames, {'weather'});
    });

    test('throws when the next step would exceed maxSteps', () {
      final planner = GenerateTextStepPlanner(
        runnerName: 'TestRunner',
        model: _PlannerLanguageModel(),
        maxSteps: 1,
      );

      expect(
        () => planner.planNextStep(
          promptHistory: [
            UserPromptMessage.text('next'),
          ],
          previousSteps: [
            _step(0),
          ],
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('TestRunner exceeded maxSteps (1).'),
          ),
        ),
      );
    });
  });
}

GenerateTextStepResult _step(int stepNumber) {
  return GenerateTextStepResult(
    stepNumber: stepNumber,
    providerId: 'test-provider',
    modelId: 'test-model',
    request: GenerateTextRequest(
      prompt: [
        UserPromptMessage.text('previous'),
      ],
    ),
    result: GenerateTextResult(
      content: const [
        TextContentPart('done'),
      ],
      finishReason: FinishReason.stop,
    ),
  );
}

final class _PlannerLanguageModel implements LanguageModel {
  @override
  String get modelId => 'test-model';

  @override
  String get providerId => 'test-provider';

  @override
  Future<GenerateTextResult> doGenerate(GenerateTextRequest request) {
    throw UnimplementedError();
  }

  @override
  Stream<LanguageModelStreamEvent> doStream(GenerateTextRequest request) {
    throw UnimplementedError();
  }
}
