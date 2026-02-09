import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIChatResponse.toolCalls extra_content', () {
    test(
        'captures google thought_signature into providerOptions (AI SDK parity)',
        () {
      final response = OpenAIChatResponse(
        {
          'choices': [
            {
              'message': {
                'role': 'assistant',
                'content': '',
                'tool_calls': [
                  {
                    'id': 'call_1',
                    'type': 'function',
                    'function': {
                      'name': 'getWeather',
                      'arguments': '{"city":"London"}',
                    },
                    'extra_content': {
                      'google': {'thought_signature': 'sigA'},
                    },
                  }
                ],
              },
              'finish_reason': 'tool_calls',
            },
          ],
        },
        providerId: 'deepseek',
      );

      final calls = response.toolCalls;
      expect(calls, isNotNull);
      expect(calls, hasLength(1));
      expect(
        calls!.single.providerOptions['deepseek']?['thoughtSignature'],
        equals('sigA'),
      );
    });
  });
}
