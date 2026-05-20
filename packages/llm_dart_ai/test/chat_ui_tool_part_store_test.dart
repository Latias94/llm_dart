import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('ChatUiToolPartStore integration', () {
    test('hydrates seeded tool parts and updates them by tool call id', () {
      final accumulator = ChatUiAccumulator(
        messageId: 'assistant-1',
        seedMessage: ChatUiMessage(
          id: 'assistant-1',
          role: ChatUiRole.assistant,
          parts: const [
            ToolUiPart(
              toolCallId: 'call-1',
              toolName: 'weather',
              state: ToolUiPartState.inputAvailable,
              input: {'city': 'Paris'},
              title: 'Weather',
            ),
          ],
        ),
      );

      final message = accumulator.apply(
        ToolResultEvent(
          toolResult: ToolResultContent(
            toolCallId: 'call-1',
            toolName: 'weather',
            output: {'temperature': 21},
          ),
        ),
      );

      expect(message.parts, hasLength(1));
      final tool = message.parts.single as ToolUiPart;
      expect(tool.toolCallId, 'call-1');
      expect(tool.state, ToolUiPartState.outputAvailable);
      expect(tool.input, {'city': 'Paris'});
      expect(tool.output, {'temperature': 21});
      expect(tool.title, 'Weather');
    });
  });
}
