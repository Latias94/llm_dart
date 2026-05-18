import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_ai/src/model/generate_text_loop_continuation.dart';
import 'package:test/test.dart';

void main() {
  group('GenerateTextLoopContinuation', () {
    test('stops without replaying the step when a stop condition matches',
        () async {
      final initialPrompt = [
        UserPromptMessage.text('weather'),
      ];
      final step = _toolStep();

      final continuation = await resolveGenerateTextLoopContinuation(
        promptHistory: initialPrompt,
        step: step,
        completedSteps: [
          step,
        ],
        stopConditions: [
          (_) => true,
        ],
        runnerName: 'TestRunner',
      );

      expect(continuation.shouldContinue, isFalse);
      expect(continuation.promptHistory, initialPrompt);
      expect(
        () => continuation.promptHistory.add(UserPromptMessage.text('again')),
        throwsUnsupportedError,
      );
    });

    test('continues with replayed assistant and tool messages otherwise',
        () async {
      final initialPrompt = [
        UserPromptMessage.text('weather'),
      ];
      final step = _toolStep();

      final continuation = await resolveGenerateTextLoopContinuation(
        promptHistory: initialPrompt,
        step: step,
        completedSteps: [
          step,
        ],
        stopConditions: [
          (_) => false,
        ],
        runnerName: 'TestRunner',
      );

      expect(continuation.shouldContinue, isTrue);
      expect(continuation.promptHistory, hasLength(3));
      expect(continuation.promptHistory[0], same(initialPrompt.single));
      expect(continuation.promptHistory[1], isA<AssistantPromptMessage>());
      expect(continuation.promptHistory[2], isA<ToolPromptMessage>());

      final assistantMessage =
          continuation.promptHistory[1] as AssistantPromptMessage;
      expect(assistantMessage.parts.single, isA<ToolCallPromptPart>());

      final toolMessage = continuation.promptHistory[2] as ToolPromptMessage;
      expect(toolMessage.toolName, 'weather');
      expect(toolMessage.parts.single, isA<ToolResultPromptPart>());
    });
  });
}

GenerateTextStepResult _toolStep() {
  return GenerateTextStepResult(
    stepNumber: 0,
    providerId: 'test-provider',
    modelId: 'test-model',
    request: GenerateTextRequest(
      prompt: [
        UserPromptMessage.text('weather'),
      ],
    ),
    result: GenerateTextResult(
      content: [
        const ToolCallContentPart(
          ToolCallContent(
            toolCallId: 'tool-1',
            toolName: 'weather',
          ),
        ),
        ToolResultContentPart(
          ToolResultContent(
            toolCallId: 'tool-1',
            toolName: 'weather',
            output: {
              'forecast': 'sunny',
            },
          ),
        ),
      ],
      finishReason: FinishReason.toolCalls,
    ),
  );
}
