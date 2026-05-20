import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_chat/src/chat_assistant_prompt_replay_projection.dart';
import 'package:test/test.dart';

void main() {
  group('assistantPromptMessagesFromChatUiMessage', () {
    test('parses custom tool replay payloads and uses them for dedupe', () {
      final payload = <Object?, Object?>{
        'replayRole': 'tool',
        'toolCallId': 'tool-1',
        'toolName': 'weather',
      };

      expect(toolReplayPayloadRole(payload), 'tool');
      expect(toolReplayPayloadToolCallId(payload), 'tool-1');
      expect(toolReplayPayloadToolName(payload), 'weather');
      expect(
        replayedToolResultIdsFromChatUiParts([
          CustomUiPart(kind: 'openai-response-item', data: payload),
        ]),
        {'tool-1'},
      );
      expect(toolReplayPayloadMap({1: 'bad'}), isNull);
    });

    test('splits provider-executed tool calls and results for prompt replay',
        () {
      final prompt = assistantPromptMessagesFromChatUiMessage(
        ChatUiMessage(
          id: 'assistant-1',
          role: ChatUiRole.assistant,
          parts: [
            const TextUiPart(text: 'Checking.'),
            ToolUiPart(
              toolCallId: 'tool-1',
              toolName: 'weather',
              state: ToolUiPartState.outputAvailable,
              input: const {'city': 'Paris'},
              output: const {'forecast': 'sunny'},
              providerExecuted: true,
              callProviderMetadata: ProviderMetadata.forNamespace(
                'test',
                {'call': true},
              ),
              resultProviderMetadata: ProviderMetadata.forNamespace(
                'test',
                {'result': true},
              ),
            ),
            const TextUiPart(text: 'Done.'),
          ],
        ),
      );

      expect(prompt, hasLength(3));

      final firstAssistant = prompt[0] as AssistantPromptMessage;
      expect(firstAssistant.parts, hasLength(2));
      expect((firstAssistant.parts[0] as TextPromptPart).text, 'Checking.');
      final toolCall = firstAssistant.parts[1] as ToolCallPromptPart;
      expect(toolCall.toolCallId, 'tool-1');
      expect(toolCall.providerExecuted, isTrue);
      expect(
        (toolCall.providerOptions as ProviderReplayPromptPartOptions)
            .metadata
            .namespace('test'),
        {
          'call': true,
        },
      );

      final toolMessage = prompt[1] as ToolPromptMessage;
      final toolResult = toolMessage.parts.single as ToolResultPromptPart;
      expect(toolResult.output, {'forecast': 'sunny'});
      expect(
        (toolResult.providerOptions as ProviderReplayPromptPartOptions)
            .metadata
            .namespace('test'),
        {
          'result': true,
        },
      );

      final finalAssistant = prompt[2] as AssistantPromptMessage;
      expect((finalAssistant.parts.single as TextPromptPart).text, 'Done.');
    });

    test('does not duplicate explicit custom tool replay payloads', () {
      final prompt = assistantPromptMessagesFromChatUiMessage(
        ChatUiMessage(
          id: 'assistant-1',
          role: ChatUiRole.assistant,
          parts: [
            ToolUiPart(
              toolCallId: 'tool-1',
              toolName: 'weather',
              state: ToolUiPartState.outputAvailable,
              input: const {'city': 'Paris'},
              output: const {'forecast': 'sunny'},
              providerExecuted: true,
            ),
            const CustomUiPart(
              kind: 'openai-response-item',
              data: {
                'replayRole': 'tool',
                'toolCallId': 'tool-1',
                'toolName': 'weather',
              },
            ),
          ],
        ),
      );

      expect(prompt, hasLength(2));
      expect(prompt.whereType<ToolPromptMessage>(), hasLength(1));
      final toolMessage = prompt.whereType<ToolPromptMessage>().single;
      expect(toolMessage.parts.single, isA<CustomPromptPart>());
    });
  });
}
