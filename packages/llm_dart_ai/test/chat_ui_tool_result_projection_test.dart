import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('ChatUiToolResultProjection', () {
    test('applies approval requests to existing tool parts', () {
      final accumulator = ChatUiAccumulator(messageId: 'assistant-1')
        ..apply(
          const ToolCallEvent(
            toolCall: ToolCallContent(
              toolCallId: 'tool-1',
              toolName: 'browser',
              input: {'url': 'https://example.com'},
            ),
          ),
        )
        ..apply(
          ToolApprovalRequestEvent(
            approvalId: 'approval-1',
            toolCallId: 'tool-1',
            providerMetadata: ProviderMetadata.forNamespace(
              'test',
              {'approval': true},
            ),
          ),
        );

      final tool = accumulator.message.parts.single as ToolUiPart;
      expect(tool.state, ToolUiPartState.approvalRequested);
      expect(tool.input, {'url': 'https://example.com'});
      expect(tool.approval?.approvalId, 'approval-1');
      expect(tool.callProviderMetadata?.namespace('test'), {
        'approval': true,
      });
    });

    test('applies error results and preserves error text', () {
      final accumulator = ChatUiAccumulator(messageId: 'assistant-1')
        ..apply(
          const ToolInputStartEvent(
            toolCallId: 'tool-1',
            toolName: 'weather',
          ),
        )
        ..apply(
          ToolResultEvent(
            toolResult: ToolResultContent(
              toolCallId: 'tool-1',
              toolName: 'weather',
              output: {'message': 'failed'},
              isError: true,
              isDynamic: true,
            ),
            providerMetadata: ProviderMetadata.forNamespace(
              'test',
              {'result': 'error'},
            ),
          ),
        );

      final tool = accumulator.message.parts.single as ToolUiPart;
      expect(tool.state, ToolUiPartState.outputError);
      expect(tool.output, {'message': 'failed'});
      expect(tool.toolOutput, isA<ErrorJsonToolOutput>());
      expect(tool.errorText, '{"message":"failed"}');
      expect(tool.isDynamic, isTrue);
      expect(tool.resultProviderMetadata?.namespace('test'), {
        'result': 'error',
      });
    });

    test('applies denied outputs with result provider metadata', () {
      final accumulator = ChatUiAccumulator(messageId: 'assistant-1')
        ..apply(
          const ToolCallEvent(
            toolCall: ToolCallContent(
              toolCallId: 'tool-1',
              toolName: 'browser',
            ),
          ),
        )
        ..apply(
          ToolOutputDeniedEvent(
            toolCallId: 'tool-1',
            reason: 'Not trusted',
            providerMetadata: ProviderMetadata.forNamespace(
              'test',
              {'denied': true},
            ),
          ),
        );

      final tool = accumulator.message.parts.single as ToolUiPart;
      expect(tool.state, ToolUiPartState.outputDenied);
      expect(tool.output, 'Not trusted');
      expect(tool.toolOutput, isA<ExecutionDeniedToolOutput>());
      expect(
        (tool.toolOutput as ExecutionDeniedToolOutput).reason,
        'Not trusted',
      );
      expect(tool.resultProviderMetadata?.namespace('test'), {'denied': true});
    });
  });
}
