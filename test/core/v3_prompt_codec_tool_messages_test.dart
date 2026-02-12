import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('v3 prompt codec: tool messages', () {
    test('encodes ToolResultPart as role=tool message', () {
      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: ChatRole.user,
            parts: [
              ToolResultPart(
                ToolCall(
                  id: 'call_1',
                  callType: 'function',
                  function: const FunctionCall(
                    name: 'tool',
                    arguments: '{"type":"text","value":"ok"}',
                  ),
                ),
              ),
            ],
          ),
        ],
      );

      final encoded = encodeV3Prompt(prompt);
      expect(encoded, hasLength(1));
      expect(encoded.single['role'], 'tool');
      expect((encoded.single['content'] as List).single, {
        'type': 'tool-result',
        'toolCallId': 'call_1',
        'toolName': 'tool',
        'output': {'type': 'text', 'value': 'ok'},
      });
    });

    test('decodes role=tool tool-result into ToolResultPart', () {
      final prompt = decodeV3Prompt([
        {
          'role': 'tool',
          'content': [
            {
              'type': 'tool-result',
              'toolCallId': 'call_1',
              'toolName': 'tool',
              'output': {'type': 'text', 'value': 'ok'},
            }
          ],
        }
      ]);

      expect(prompt.messages, hasLength(1));
      expect(prompt.messages.single.role, ChatRole.user);
      expect(prompt.messages.single.parts.single, isA<ToolResultPart>());
    });

    test('invalid tool-result output throws', () {
      expect(
        () => decodeV3Prompt([
          {
            'role': 'tool',
            'content': [
              {
                'type': 'tool-result',
                'toolCallId': 'call_1',
                'toolName': 'tool',
                'output': {'type': 'text'},
              }
            ],
          }
        ]),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
