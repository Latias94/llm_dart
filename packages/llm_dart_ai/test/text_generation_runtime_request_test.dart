import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_ai/src/model/text_generation_runtime_request.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;
import 'package:test/test.dart';

void main() {
  group('TextGenerationRuntimeRequest', () {
    test('normalizes user messages and freezes runner collections', () {
      final tools = [
        FunctionToolDefinition(
          name: 'weather',
          inputSchema: ToolJsonSchema.object(),
        ),
      ];
      final stopConditions = [
        isStepCount(2),
      ];

      final runtime = TextGenerationRuntimeRequest(
        model: _NoopLanguageModel(),
        messages: [
          UserModelMessage.text('Hello from messages'),
        ],
        tools: tools,
        stopWhen: stopConditions,
      );

      tools.add(
        FunctionToolDefinition(
          name: 'later',
          inputSchema: ToolJsonSchema.object(),
        ),
      );
      stopConditions.add(isLoopFinished());

      expect(runtime.tools.map((tool) => tool.name), ['weather']);
      expect(runtime.stopWhen, hasLength(1));

      final message = runtime.prompt.single as UserPromptMessage;
      final text = message.parts.single as TextPromptPart;
      expect(text.text, 'Hello from messages');

      final promptHistory = runtime.createPromptHistory();
      promptHistory.clear();
      expect(runtime.prompt, hasLength(1));
    });

    test('builds shared step planner and continuation resolver', () {
      final runtime = TextGenerationRuntimeRequest(
        model: _NoopLanguageModel(),
        prompt: [
          UserPromptMessage.text('Hello'),
        ],
        tools: [
          FunctionToolDefinition(
            name: 'weather',
            inputSchema: ToolJsonSchema.object(),
          ),
        ],
      );

      final context = runtime.createStepContext(
        runnerName: 'RuntimeRequestTest',
      );
      final plan = context.planner.planNextStep(
        promptHistory: runtime.createPromptHistory(),
        previousSteps: const [],
      );

      expect(plan.request.tools.single.name, 'weather');
      expect(context.continuationResolver.declaredToolNames, {'weather'});
    });

    test('derives structured-output options without reparsing prompt input',
        () {
      final runtime = TextGenerationRuntimeRequest(
        model: _NoopLanguageModel(),
        messages: [
          UserModelMessage.text('Return JSON'),
        ],
      );
      final responseFormat = JsonResponseFormat(
        schema: JsonSchema.object(),
      );

      final copied = runtime.withOptions(
        GenerateTextOptions(
          responseFormat: responseFormat,
        ),
      );

      expect(copied.prompt, runtime.prompt);
      expect(copied.options.responseFormat, same(responseFormat));
    });
  });
}

final class _NoopLanguageModel implements LanguageModel {
  @override
  String get modelId => 'noop-model';

  @override
  String get providerId => 'test';

  @override
  Future<GenerateTextResult> doGenerate(GenerateTextRequest request) {
    throw UnimplementedError();
  }

  @override
  Stream<provider.LanguageModelStreamEvent> doStream(
    GenerateTextRequest request,
  ) async* {
    throw UnimplementedError();
  }
}
