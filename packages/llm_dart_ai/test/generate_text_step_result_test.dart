import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('GenerateTextStepResult', () {
    test('projects common step data from the wrapped request and result', () {
      final request = GenerateTextRequest(
        prompt: [
          UserPromptMessage.text('What happened?'),
        ],
      );

      final source = SourceReference(
        kind: SourceReferenceKind.url,
        sourceId: 'src-1',
        uri: Uri.parse('https://example.com/news'),
        title: 'Example News',
      );
      final file = GeneratedFile(
        mediaType: 'application/pdf',
        filename: 'report.pdf',
        uri: Uri.parse('https://example.com/report.pdf'),
      );
      final responseTimestamp = DateTime.utc(2026, 3, 30, 12, 0, 0);

      final result = GenerateTextResult(
        content: [
          const TextContentPart('Hello'),
          const ReasoningContentPart('Think first.'),
          ToolCallContentPart(
            const ToolCallContent(
              toolCallId: 'tool-1',
              toolName: 'weather',
              input: {
                'location': 'Tokyo',
              },
            ),
          ),
          ToolApprovalRequestContentPart(
            const ToolApprovalRequestContent(
              approvalId: 'approval-1',
              toolCallId: 'tool-1',
            ),
          ),
          ToolResultContentPart(
            ToolResultContent(
              toolCallId: 'tool-1',
              toolName: 'weather',
              output: {
                'temperature': 24,
              },
            ),
          ),
          SourceContentPart(source),
          FileContentPart(file),
        ],
        finishReason: FinishReason.stop,
        rawFinishReason: 'stop',
        responseId: 'resp-1',
        responseTimestamp: responseTimestamp,
        responseModelId: 'gpt-test',
        usage: const UsageStats(
          inputTokens: 10,
          outputTokens: 20,
          totalTokens: 30,
        ),
        providerMetadata: const ProviderMetadata({
          'openai': {
            'serviceTier': 'default',
          },
        }),
        warnings: const [
          ModelWarning(
            type: ModelWarningType.unsupported,
            message:
                'The provider ignored one optional setting during the request.',
          ),
        ],
      );

      final step = GenerateTextStepResult(
        stepNumber: 0,
        providerId: 'openai',
        modelId: 'gpt-test',
        request: request,
        result: result,
      );

      expect(step.stepNumber, 0);
      expect(step.providerId, 'openai');
      expect(step.modelId, 'gpt-test');
      expect(step.request, same(request));
      expect(step.result, same(result));

      expect(step.content, same(result.content));
      expect(step.text, 'Hello');
      expect(step.reasoningText, 'Think first.');
      expect(step.sources, [source]);
      expect(step.files, [file]);
      expect(step.toolCalls, hasLength(1));
      expect(step.toolCalls.single.toolName, 'weather');
      expect(step.toolResults, hasLength(1));
      expect(step.toolResults.single.output, {
        'temperature': 24,
      });
      expect(step.toolApprovalRequests, hasLength(1));
      expect(step.toolApprovalRequests.single.approvalId, 'approval-1');
      expect(step.finishReason, FinishReason.stop);
      expect(step.rawFinishReason, 'stop');
      expect(step.responseId, 'resp-1');
      expect(step.responseTimestamp, responseTimestamp);
      expect(step.responseModelId, 'gpt-test');
      expect(step.usage?.totalTokens, 30);
      expect(
        step.providerMetadata?['openai'],
        containsPair('serviceTier', 'default'),
      );
      expect(step.warnings, hasLength(1));
      expect(step.warnings.single.message, contains('ignored'));
    });
  });
}
