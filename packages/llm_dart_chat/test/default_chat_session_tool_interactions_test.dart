import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_chat/llm_dart_chat.dart';
import 'package:llm_dart_chat/src/default_chat_session_tool_interactions.dart';
import 'package:llm_dart_chat/src/default_chat_session_transcript.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultChatSessionToolInteractions', () {
    test('applies tool output and requests a provider continuation', () {
      final transcript = DefaultChatSessionTranscript([
        UserPromptMessage.text('Weather?'),
      ]);
      final interactions = DefaultChatSessionToolInteractions(transcript);

      final result = interactions.applyToolOutput(
        messages: [_assistantWithPendingTool()],
        update: const ToolOutputUpdate(
          toolCallId: 'tool-1',
          toolName: 'weather',
          output: {
            'forecast': 'sunny',
          },
        ),
      );

      expect(result.status, ChatStatus.submitting);
      expect(result.continuation?.trigger, ChatTransportTrigger.toolOutput);
      expect(result.shouldScheduleAutomaticToolExecution, isFalse);

      final toolPart =
          result.assistantMessage.parts.whereType<ToolUiPart>().single;
      expect(toolPart.state, ToolUiPartState.outputAvailable);
      expect((toolPart.output as Map<String, Object?>)['forecast'], 'sunny');

      expect(transcript.prompt, hasLength(2));
      final toolMessage = transcript.prompt.last as ToolPromptMessage;
      final toolResult = toolMessage.parts.single as ToolResultPromptPart;
      expect(toolResult.toolCallId, 'tool-1');
      expect((toolResult.output as Map<String, Object?>)['forecast'], 'sunny');
    });

    test('keeps waiting when more client tool output is required', () {
      final transcript = DefaultChatSessionTranscript([
        UserPromptMessage.text('Use tools'),
      ]);
      final interactions = DefaultChatSessionToolInteractions(transcript);

      final result = interactions.applyToolOutput(
        messages: [
          ChatUiMessage(
            id: 'assistant-1',
            role: ChatUiRole.assistant,
            parts: const [
              ToolUiPart(
                toolCallId: 'tool-1',
                toolName: 'weather',
                state: ToolUiPartState.inputAvailable,
              ),
              ToolUiPart(
                toolCallId: 'tool-2',
                toolName: 'calendar',
                state: ToolUiPartState.inputAvailable,
              ),
            ],
          ),
        ],
        update: const ToolOutputUpdate(
          toolCallId: 'tool-1',
          toolName: 'weather',
          output: 'sunny',
        ),
      );

      expect(result.status, ChatStatus.awaitingTool);
      expect(result.continuation, isNull);
      expect(result.shouldScheduleAutomaticToolExecution, isTrue);
    });

    test('records denied approval without provider continuation', () {
      final transcript = DefaultChatSessionTranscript([
        UserPromptMessage.text('Browse'),
      ]);
      final interactions = DefaultChatSessionToolInteractions(transcript);

      final result = interactions.applyToolApproval(
        messages: [
          ChatUiMessage(
            id: 'assistant-1',
            role: ChatUiRole.assistant,
            parts: const [
              ToolUiPart(
                toolCallId: 'tool-1',
                toolName: 'browser',
                state: ToolUiPartState.approvalRequested,
                approval: ToolApprovalUiState(approvalId: 'approval-1'),
              ),
            ],
          ),
        ],
        response: const ToolApprovalResponse(
          approvalId: 'approval-1',
          approved: false,
          reason: 'no',
        ),
      );

      expect(result.status, ChatStatus.ready);
      expect(result.continuation, isNull);
      expect(result.shouldScheduleAutomaticToolExecution, isTrue);

      final toolPart =
          result.assistantMessage.parts.whereType<ToolUiPart>().single;
      expect(toolPart.state, ToolUiPartState.outputDenied);
      expect(toolPart.toolOutput, isA<ExecutionDeniedToolOutput>());

      final approvalMessage = transcript.prompt.last as ToolPromptMessage;
      final approvalPart =
          approvalMessage.parts.single as ToolApprovalResponsePromptPart;
      expect(approvalPart.approved, isFalse);
      expect(approvalPart.reason, 'no');
    });

    test('continues provider turn after provider-executed tool approval', () {
      final transcript = DefaultChatSessionTranscript([
        UserPromptMessage.text('Browse'),
      ]);
      final interactions = DefaultChatSessionToolInteractions(transcript);

      final result = interactions.applyToolApproval(
        messages: [
          ChatUiMessage(
            id: 'assistant-1',
            role: ChatUiRole.assistant,
            parts: const [
              ToolUiPart(
                toolCallId: 'tool-1',
                toolName: 'browser',
                state: ToolUiPartState.approvalRequested,
                providerExecuted: true,
                approval: ToolApprovalUiState(approvalId: 'approval-1'),
              ),
            ],
          ),
        ],
        response: const ToolApprovalResponse(
          approvalId: 'approval-1',
          approved: true,
        ),
      );

      expect(result.status, ChatStatus.submitting);
      expect(result.continuation?.trigger, ChatTransportTrigger.toolApproval);
      expect(result.shouldScheduleAutomaticToolExecution, isFalse);
    });
  });
}

ChatUiMessage _assistantWithPendingTool() {
  return ChatUiMessage(
    id: 'assistant-1',
    role: ChatUiRole.assistant,
    parts: const [
      ToolUiPart(
        toolCallId: 'tool-1',
        toolName: 'weather',
        state: ToolUiPartState.inputAvailable,
        input: {
          'city': 'London',
        },
      ),
    ],
  );
}
