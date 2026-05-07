import 'package:llm_dart/providers/google/chat.dart';
import 'package:test/test.dart';

void main() {
  group('GoogleChatResponse', () {
    test('projects text, thinking, tool calls, and usage from one payload', () {
      final response = GoogleChatResponse({
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': 'Let me think first.',
                  'thought': true,
                },
                {
                  'text': 'Here is the answer.',
                },
                {
                  'functionCall': {
                    'name': 'lookup_weather',
                    'args': {'city': 'Shanghai'},
                  },
                },
                {
                  'functionCall': {
                    'args': {'ignored': true},
                  },
                },
              ],
            },
          },
        ],
        'usageMetadata': {
          'promptTokenCount': 3,
          'candidatesTokenCount': 7,
          'totalTokenCount': 10,
          'thoughtsTokenCount': 2,
        },
      });

      expect(response.thinking, 'Let me think first.');
      expect(response.text, 'Here is the answer.');
      expect(response.toolCalls, hasLength(1));
      expect(response.toolCalls!.single.id, 'call_lookup_weather');
      expect(response.toolCalls!.single.function.name, 'lookup_weather');
      expect(
          response.toolCalls!.single.function.arguments, '{"city":"Shanghai"}');
      expect(response.usage?.promptTokens, 3);
      expect(response.usage?.completionTokens, 7);
      expect(response.usage?.totalTokens, 10);
      expect(response.usage?.reasoningTokens, 2);
      expect(
        response.toString(),
        'Thinking: Let me think first.\n{"id":"call_lookup_weather","type":"function","function":{"name":"lookup_weather","arguments":"{\\"city\\":\\"Shanghai\\"}"}}\nHere is the answer.',
      );
    });

    test('returns null for empty or malformed payloads', () {
      expect(GoogleChatResponse({}).text, isNull);
      expect(
        GoogleChatResponse({
          'candidates': [],
        }).thinking,
        isNull,
      );
      expect(
        GoogleChatResponse({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': null},
                  {'thought': true},
                  {'functionCall': 'broken'},
                ],
              },
            },
          ],
          'usageMetadata': 'broken',
        }).toolCalls,
        isNull,
      );
      expect(
        GoogleChatResponse({
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': 'kept',
                    'thought': false,
                  },
                ],
              },
            },
          ],
          'usageMetadata': {
            'promptTokenCount': '12',
            'candidatesTokenCount': 8.0,
            'totalTokenCount': '20',
            'thoughtsTokenCount': 4,
          },
        }).usage,
        isNotNull,
      );
    });
  });
}
