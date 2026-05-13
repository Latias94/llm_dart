import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('generate text stop conditions', () {
    test('isStepCount matches the completed step count exactly', () async {
      final condition = isStepCount(2);

      expect(
        await condition(
          GenerateTextStopConditionContext(
            steps: [
              _step(0),
              _step(1),
            ],
          ),
        ),
        isTrue,
      );
      expect(
        await condition(
          GenerateTextStopConditionContext(
            steps: [
              _step(0),
            ],
          ),
        ),
        isFalse,
      );
      expect(
        await condition(
          GenerateTextStopConditionContext(
            steps: [
              _step(0),
              _step(1),
              _step(2),
            ],
          ),
        ),
        isFalse,
      );
    });

    test('isLoopFinished never stops by itself', () async {
      final condition = isLoopFinished();

      expect(
        await condition(GenerateTextStopConditionContext(steps: const [])),
        isFalse,
      );
      expect(
        await condition(
          GenerateTextStopConditionContext(
            steps: [
              _step(0),
            ],
          ),
        ),
        isFalse,
      );
    });

    test('hasToolCall only checks the latest completed step', () async {
      final condition = hasToolCall('finalAnswer');

      expect(
        await condition(
          GenerateTextStopConditionContext(
            steps: [
              _step(
                0,
                toolCallName: 'finalAnswer',
              ),
              _step(1),
            ],
          ),
        ),
        isFalse,
      );
      expect(
        await condition(
          GenerateTextStopConditionContext(
            steps: [
              _step(0),
              _step(
                1,
                toolCallName: 'finalAnswer',
              ),
            ],
          ),
        ),
        isTrue,
      );
    });

    test('hasToolCall accepts additional tool names', () async {
      final condition = hasToolCall('search', ['finalAnswer']);

      expect(
        await condition(
          GenerateTextStopConditionContext(
            steps: [
              _step(
                0,
                toolCallName: 'finalAnswer',
              ),
            ],
          ),
        ),
        isTrue,
      );
    });

    test('isStopConditionMet returns true when any condition matches',
        () async {
      expect(
        await isStopConditionMet(
          stopConditions: [
            (_) => false,
            (context) async => context.steps.length == 1,
          ],
          steps: [
            _step(0),
          ],
        ),
        isTrue,
      );
      expect(
        await isStopConditionMet(
          stopConditions: [
            (_) => false,
            (_) async => false,
          ],
          steps: [
            _step(0),
          ],
        ),
        isFalse,
      );
    });
  });
}

GenerateTextStepResult _step(
  int stepNumber, {
  String? toolCallName,
}) {
  return GenerateTextStepResult(
    stepNumber: stepNumber,
    providerId: 'test',
    modelId: 'test-model',
    request: GenerateTextRequest(prompt: const []),
    result: GenerateTextResult(
      content: [
        if (toolCallName != null)
          ToolCallContentPart(
            ToolCallContent(
              toolCallId: 'tool-$stepNumber',
              toolName: toolCallName,
            ),
          )
        else
          const TextContentPart('done'),
      ],
      finishReason:
          toolCallName == null ? FinishReason.stop : FinishReason.toolCalls,
    ),
  );
}
