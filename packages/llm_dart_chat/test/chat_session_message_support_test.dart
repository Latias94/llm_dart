import 'package:llm_dart_chat/src/chat_session_message_support.dart';
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('chat session message support', () {
    test('preserves explicit tool output between prompt and UI messages', () {
      final toolOutput = ContentToolOutput(
        parts: const [
          TextToolOutputContentPart('forecast'),
          JsonToolOutputContentPart({
            'tempC': 21,
          }),
        ],
      );

      final uiMessage = promptMessageToChatUiMessage(
        ToolPromptMessage(
          toolName: 'weather',
          parts: [
            ToolResultPromptPart(
              toolCallId: 'tool-1',
              toolName: 'weather',
              toolOutput: toolOutput,
            ),
          ],
        ),
        id: 'message-1',
      );

      final uiToolPart = uiMessage.parts.whereType<ToolUiPart>().single;
      expect(uiToolPart.state, ToolUiPartState.outputAvailable);
      expect(uiToolPart.toolOutput, same(toolOutput));
      expect(uiToolPart.output, same(toolOutput.parts));

      final promptMessages = assistantPromptMessagesFromChatUiMessage(
        ChatUiMessage(
          id: 'assistant-1',
          role: ChatUiRole.assistant,
          parts: [
            ToolUiPart(
              toolCallId: 'tool-1',
              toolName: 'weather',
              state: ToolUiPartState.outputAvailable,
              input: const {
                'city': 'Shanghai',
              },
              providerExecuted: true,
              toolOutput: toolOutput,
            ),
          ],
        ),
      );

      expect(promptMessages, hasLength(2));
      final resultMessage = promptMessages[1] as ToolPromptMessage;
      final resultPart = resultMessage.parts.single as ToolResultPromptPart;
      expect(resultPart.toolOutput, same(toolOutput));
    });

    test('maps denied approval responses to denied tool output', () {
      final uiMessage = promptMessageToChatUiMessage(
        ToolPromptMessage(
          toolName: 'browser',
          parts: const [
            ToolApprovalResponsePromptPart(
              approvalId: 'approval-1',
              toolCallId: 'tool-1',
              approved: false,
              reason: 'User denied browser access.',
            ),
          ],
        ),
        id: 'message-1',
      );

      final toolPart = uiMessage.parts.whereType<ToolUiPart>().single;
      expect(toolPart.state, ToolUiPartState.outputDenied);
      expect(toolPart.toolOutput, isA<ExecutionDeniedToolOutput>());
      expect(
        (toolPart.toolOutput as ExecutionDeniedToolOutput).reason,
        'User denied browser access.',
      );
    });
  });
}
