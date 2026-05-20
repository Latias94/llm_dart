import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_chat/src/chat_prompt_tool_part_projection.dart';
import 'package:test/test.dart';

void main() {
  group('ChatPromptToolPartProjector', () {
    test('merges tool call and approval request into one tool UI part', () {
      final parts = <ChatUiPart>[];
      final projector = ChatPromptToolPartProjector(
        parts: parts,
        fallbackToolName: 'fallback',
      );

      projector.applyToolCall(
        const ToolCallPromptPart(
          toolCallId: 'tool-1',
          toolName: 'weather',
          input: {
            'city': 'London',
          },
          providerExecuted: true,
          isDynamic: true,
          title: 'Weather lookup',
          providerOptions: ProviderReplayPromptPartOptions(
            ProviderMetadata({
              'test': {
                'call': true,
              },
            }),
          ),
        ),
      );
      projector.applyApprovalRequest(
        const ToolApprovalRequestPromptPart(
          approvalId: 'approval-1',
          toolCallId: 'tool-1',
          providerOptions: ProviderReplayPromptPartOptions(
            ProviderMetadata({
              'test': {
                'approval': true,
              },
            }),
          ),
        ),
      );

      final toolPart = parts.whereType<ToolUiPart>().single;
      expect(toolPart.toolName, 'weather');
      expect(toolPart.state, ToolUiPartState.approvalRequested);
      expect((toolPart.input as Map<String, Object?>)['city'], 'London');
      expect(toolPart.providerExecuted, isTrue);
      expect(toolPart.isDynamic, isTrue);
      expect(toolPart.title, 'Weather lookup');
      expect(toolPart.approval?.approvalId, 'approval-1');
      expect(toolPart.callProviderMetadata!.namespace('test'), {
        'call': true,
        'approval': true,
      });
    });

    test('merges tool result metadata without dropping call metadata', () {
      final parts = <ChatUiPart>[];
      final projector = ChatPromptToolPartProjector(
        parts: parts,
        fallbackToolName: 'fallback',
      );

      projector.applyToolCall(
        const ToolCallPromptPart(
          toolCallId: 'tool-1',
          toolName: 'weather',
          input: {
            'city': 'London',
          },
          providerOptions: ProviderReplayPromptPartOptions(
            ProviderMetadata({
              'test': {
                'call': true,
              },
            }),
          ),
        ),
      );
      projector.applyToolResult(
        ToolResultPromptPart(
          toolCallId: 'tool-1',
          toolName: 'weather',
          output: {
            'forecast': 'sunny',
          },
          providerOptions: const ProviderReplayPromptPartOptions(
            ProviderMetadata({
              'test': {
                'result': true,
              },
            }),
          ),
        ),
      );

      final toolPart = parts.whereType<ToolUiPart>().single;
      expect(toolPart.state, ToolUiPartState.outputAvailable);
      expect((toolPart.input as Map<String, Object?>)['city'], 'London');
      expect((toolPart.output as Map<String, Object?>)['forecast'], 'sunny');
      expect(toolPart.callProviderMetadata!.namespace('test'), {
        'call': true,
      });
      expect(toolPart.resultProviderMetadata!.namespace('test'), {
        'result': true,
      });
    });

    test('projects denied approval response as denied tool output', () {
      final parts = <ChatUiPart>[];
      final projector = ChatPromptToolPartProjector(
        parts: parts,
        fallbackToolName: 'browser',
      );

      projector.applyApprovalResponse(
        const ToolApprovalResponsePromptPart(
          approvalId: 'approval-1',
          toolCallId: 'tool-1',
          approved: false,
          reason: 'no',
        ),
      );

      final toolPart = parts.whereType<ToolUiPart>().single;
      expect(toolPart.toolName, 'browser');
      expect(toolPart.state, ToolUiPartState.outputDenied);
      expect(toolPart.approval?.approved, isFalse);
      expect(toolPart.approval?.reason, 'no');
      expect(toolPart.toolOutput, isA<ExecutionDeniedToolOutput>());
      expect(
        (toolPart.toolOutput as ExecutionDeniedToolOutput).reason,
        'no',
      );
    });
  });
}
