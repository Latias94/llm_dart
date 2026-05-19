import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_chat/llm_dart_chat.dart';
import 'package:llm_dart_chat/src/default_chat_session_transcript.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultChatSessionTranscript', () {
    test('appends user input to prompt history and UI messages', () {
      final transcript = DefaultChatSessionTranscript(const []);

      final append = transcript.appendUserInput(
        ChatInput.text('Hello'),
        messageId: 'msg-1',
      );

      expect(transcript.prompt, hasLength(1));
      expect(transcript.prompt.single, isA<UserPromptMessage>());
      expect(append.uiMessage.id, 'msg-1');
      expect(append.uiMessage.role, ChatUiRole.user);
      expect(
        append.uiMessage.parts.whereType<TextUiPart>().single.text,
        'Hello',
      );
    });

    test('replays assistant prompts from a start part index', () {
      final transcript = DefaultChatSessionTranscript([
        UserPromptMessage.text('Use the tool'),
      ]);
      final assistantMessage = ChatUiMessage(
        id: 'msg-2',
        role: ChatUiRole.assistant,
        parts: const [
          ToolUiPart(
            toolCallId: 'tool-1',
            toolName: 'weather',
            state: ToolUiPartState.outputAvailable,
            input: {
              'city': 'London',
            },
            providerExecuted: true,
          ),
          TextUiPart(text: 'Sunny.'),
        ],
      );

      transcript.appendAssistantPromptIfPresent(
        assistantMessage,
        startPartIndex: 1,
      );

      expect(transcript.prompt, hasLength(2));
      final replayedAssistant =
          transcript.prompt.last as AssistantPromptMessage;
      expect(replayedAssistant.parts, hasLength(1));
      expect(
        (replayedAssistant.parts.single as TextPromptPart).text,
        'Sunny.',
      );
    });

    test('records tool output and approval responses in replay order', () {
      final transcript = DefaultChatSessionTranscript([
        UserPromptMessage.text('Run browser'),
      ]);

      transcript.appendToolOutput(
        const ToolOutputUpdate(
          toolCallId: 'tool-1',
          toolName: 'weather',
          output: {
            'forecast': 'sunny',
          },
        ),
      );
      transcript.appendToolApprovalResponse(
        response: const ToolApprovalResponse(
          approvalId: 'approval-1',
          approved: false,
          reason: 'Not trusted',
        ),
        pendingTool: const ToolUiPart(
          toolCallId: 'tool-2',
          toolName: 'browser',
          state: ToolUiPartState.approvalRequested,
          approval: ToolApprovalUiState(approvalId: 'approval-1'),
        ),
      );

      expect(transcript.prompt, hasLength(3));
      final outputMessage = transcript.prompt[1] as ToolPromptMessage;
      final outputPart = outputMessage.parts.single as ToolResultPromptPart;
      expect(outputMessage.toolName, 'weather');
      expect(outputPart.toolCallId, 'tool-1');
      expect((outputPart.output as Map<String, Object?>)['forecast'], 'sunny');

      final approvalMessage = transcript.prompt[2] as ToolPromptMessage;
      final approvalPart =
          approvalMessage.parts.single as ToolApprovalResponsePromptPart;
      expect(approvalMessage.toolName, 'browser');
      expect(approvalPart.toolCallId, 'tool-2');
      expect(approvalPart.approved, isFalse);
      expect(approvalPart.reason, 'Not trusted');
    });

    test('upserts and replaces only the latest assistant message', () {
      final transcript = DefaultChatSessionTranscript(const []);
      final userMessage = ChatUiMessage(
        id: 'msg-1',
        role: ChatUiRole.user,
        parts: const [
          TextUiPart(text: 'Hi'),
        ],
      );
      final firstAssistant = ChatUiMessage(
        id: 'msg-2',
        role: ChatUiRole.assistant,
        parts: const [
          TextUiPart(text: 'Draft'),
        ],
      );
      final finalAssistant = ChatUiMessage(
        id: 'msg-2',
        role: ChatUiRole.assistant,
        parts: const [
          TextUiPart(text: 'Final'),
        ],
      );

      final appended = transcript.upsertAssistantMessage(
        [userMessage],
        firstAssistant,
      );
      final replaced = transcript.replaceLatestAssistantMessage(
        appended,
        finalAssistant,
      );

      expect(appended, hasLength(2));
      expect(replaced, hasLength(2));
      expect(
        replaced.last.parts.whereType<TextUiPart>().single.text,
        'Final',
      );
    });
  });
}
