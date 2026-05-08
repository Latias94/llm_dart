import 'package:llm_dart/models/chat_models.dart';
import 'package:llm_dart/src/compatibility/providers/openai_compatible_legacy_message_codec.dart';
import 'package:test/test.dart';

void main() {
  group('buildOpenAICompatibleLegacyMessages', () {
    test('expands tool results into role tool messages with matching ids', () {
      const toolCall = ToolCall(
        id: 'call_weather_1',
        callType: 'function',
        function: FunctionCall(
          name: 'get_weather',
          arguments: '{"city":"Hanoi"}',
        ),
      );

      final messages = buildOpenAICompatibleLegacyMessages(
        systemPrompt: 'Be concise.',
        messages: [
          ChatMessage.user('What is the weather in Hanoi?'),
          ChatMessage.toolUse(toolCalls: [toolCall]),
          ChatMessage.toolResult(
            results: [toolCall],
            content: '{"city":"Hanoi","temperatureC":31}',
          ),
        ],
      );

      expect(messages, [
        {
          'role': 'system',
          'content': 'Be concise.',
        },
        {
          'role': 'user',
          'content': 'What is the weather in Hanoi?',
        },
        {
          'role': 'assistant',
          'content': '',
          'tool_calls': [
            {
              'id': 'call_weather_1',
              'type': 'function',
              'function': {
                'name': 'get_weather',
                'arguments': '{"city":"Hanoi"}',
              },
            },
          ],
        },
        {
          'role': 'tool',
          'tool_call_id': 'call_weather_1',
          'content': '{"city":"Hanoi","temperatureC":31}',
        },
      ]);
    });

    test('expands parallel tool results into one message per result', () {
      const weatherCall = ToolCall(
        id: 'call_weather_1',
        callType: 'function',
        function: FunctionCall(
          name: 'get_weather',
          arguments: '{"city":"Hanoi"}',
        ),
      );
      const timeCall = ToolCall(
        id: 'call_time_1',
        callType: 'function',
        function: FunctionCall(
          name: 'get_time',
          arguments: '{"city":"Hanoi"}',
        ),
      );

      final messages = buildOpenAICompatibleLegacyMessages(
        messages: [
          ChatMessage.toolResult(results: [weatherCall, timeCall]),
        ],
      );

      expect(messages, [
        {
          'role': 'tool',
          'tool_call_id': 'call_weather_1',
          'content': '{"city":"Hanoi"}',
        },
        {
          'role': 'tool',
          'tool_call_id': 'call_time_1',
          'content': '{"city":"Hanoi"}',
        },
      ]);
    });

    test('can omit legacy participant names for providers that reject them',
        () {
      final messages = buildOpenAICompatibleLegacyMessages(
        includeName: false,
        messages: [
          ChatMessage.system('Be concise.', name: 'policy'),
        ],
      );

      expect(messages, [
        {
          'role': 'system',
          'content': 'Be concise.',
        },
      ]);
    });
  });
}
