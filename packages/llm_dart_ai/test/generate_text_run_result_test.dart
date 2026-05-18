import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('GenerateTextRunResult', () {
    test('requires at least one step', () {
      expect(
        () => GenerateTextRunResult(steps: const []),
        throwsArgumentError,
      );
    });

    test('projects the final step and aggregates usage across steps', () {
      final firstFile = GeneratedFile(
        mediaType: 'text/plain',
        filename: 'first.txt',
        data: const FileTextData('first'),
      );
      final firstSource = SourceReference(
        kind: SourceReferenceKind.url,
        sourceId: 'source-1',
        uri: Uri.parse('https://example.com/one'),
      );
      final firstStep = _stepResult(
        stepNumber: 0,
        text: 'First',
        usage: const UsageStats(
          inputTokens: 10,
          outputTokens: 5,
          totalTokens: 15,
          reasoningTokens: 2,
        ),
        finishReason: FinishReason.toolCalls,
        extraContent: [
          FileContentPart(firstFile),
          SourceContentPart(firstSource),
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
              output: 'sunny',
            ),
          ),
        ],
        warnings: const [
          ModelWarning(
            type: ModelWarningType.unsupported,
            message: 'first warning',
            feature: 'temperature',
          ),
        ],
      );
      final secondFile = GeneratedFile(
        mediaType: 'text/plain',
        filename: 'second.txt',
        data: const FileTextData('second'),
      );
      final secondSource = SourceReference(
        kind: SourceReferenceKind.url,
        sourceId: 'source-2',
        uri: Uri.parse('https://example.com/two'),
      );
      final secondStep = _stepResult(
        stepNumber: 1,
        text: 'Second',
        usage: const UsageStats(
          inputTokens: 3,
          outputTokens: 7,
          totalTokens: 10,
          reasoningTokens: 1,
        ),
        finishReason: FinishReason.stop,
        extraContent: [
          FileContentPart(secondFile),
          SourceContentPart(secondSource),
          const ToolCallContentPart(
            ToolCallContent(
              toolCallId: 'tool-2',
              toolName: 'dynamicWeather',
              isDynamic: true,
            ),
          ),
          ToolResultContentPart(
            ToolResultContent(
              toolCallId: 'tool-2',
              toolName: 'dynamicWeather',
              output: 'warm',
              isDynamic: true,
            ),
          ),
        ],
        warnings: const [
          ModelWarning(
            type: ModelWarningType.compatibility,
            message: 'second warning',
            feature: 'toolChoice',
          ),
        ],
      );

      final run = GenerateTextRunResult(
        steps: [
          firstStep,
          secondStep,
        ],
      );

      expect(run.lastStep, same(secondStep));
      expect(run.text, 'Second');
      expect(run.finishReason, FinishReason.stop);
      expect(run.files, [firstFile, secondFile]);
      expect(run.sources, [firstSource, secondSource]);
      expect(run.toolCalls.map((toolCall) => toolCall.toolName), [
        'weather',
        'dynamicWeather',
      ]);
      expect(run.staticToolCalls.single.toolName, 'weather');
      expect(run.dynamicToolCalls.single.toolName, 'dynamicWeather');
      expect(run.toolResults.map((toolResult) => toolResult.output), [
        'sunny',
        'warm',
      ]);
      expect(run.staticToolResults.single.toolName, 'weather');
      expect(run.dynamicToolResults.single.toolName, 'dynamicWeather');
      expect(run.warnings.map((warning) => warning.message), [
        'first warning',
        'second warning',
      ]);
      expect(
          run.totalUsage,
          const UsageStats(
            inputTokens: 13,
            outputTokens: 12,
            totalTokens: 25,
            reasoningTokens: 3,
          ));
    });
  });

  group('GenerateTextStepStartEvent', () {
    test('captures immutable previous step snapshots', () {
      final request = GenerateTextRequest(
        prompt: [
          UserPromptMessage.text('Hello'),
        ],
      );
      final previousStep = _stepResult(
        stepNumber: 0,
        text: 'First',
      );

      final event = GenerateTextStepStartEvent(
        stepNumber: 1,
        providerId: 'openai',
        modelId: 'gpt-test',
        request: request,
        previousSteps: [previousStep],
      );

      expect(event.stepNumber, 1);
      expect(event.providerId, 'openai');
      expect(event.modelId, 'gpt-test');
      expect(event.request, same(request));
      expect(event.previousSteps, [previousStep]);
      expect(
        () => event.previousSteps.add(previousStep),
        throwsUnsupportedError,
      );
    });
  });
}

GenerateTextStepResult _stepResult({
  required int stepNumber,
  required String text,
  UsageStats? usage,
  FinishReason finishReason = FinishReason.stop,
  List<ContentPart> extraContent = const [],
  List<ModelWarning> warnings = const [],
}) {
  return GenerateTextStepResult(
    stepNumber: stepNumber,
    providerId: 'openai',
    modelId: 'gpt-test',
    request: GenerateTextRequest(
      prompt: [
        UserPromptMessage.text('Prompt $stepNumber'),
      ],
    ),
    result: GenerateTextResult(
      content: [
        TextContentPart(text),
        ...extraContent,
      ],
      finishReason: finishReason,
      usage: usage,
      warnings: warnings,
    ),
  );
}
