import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai_compatible/responses.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI Responses finishReason', () {
    test('completed without tool calls => stop', () {
      final response = OpenAIResponsesResponse(
        {
          'id': 'resp_1',
          'model': 'gpt-5-mini',
          'status': 'completed',
          'output': [
            {
              'type': 'message',
              'content': [
                {'type': 'output_text', 'text': 'hi'}
              ],
              'status': 'completed',
            }
          ],
        },
        null,
        null,
        'openai',
      );

      final finish = response.finishReason!;
      expect(finish.unified, equals(LLMUnifiedFinishReason.stop));
      expect(finish.raw, equals('completed'));
    });

    test('completed with function calls => tool-calls', () {
      final response = OpenAIResponsesResponse(
        {
          'id': 'resp_2',
          'model': 'gpt-5-mini',
          'status': 'completed',
          'output': [
            {
              'type': 'function_call',
              'id': 'fc_1',
              'call_id': 'call_1',
              'name': 'calculator',
              'arguments': '{"a":1,"b":2,"op":"add"}',
              'status': 'completed',
            }
          ],
        },
        null,
        null,
        'openai',
      );

      final finish = response.finishReason!;
      expect(finish.unified, equals(LLMUnifiedFinishReason.toolCalls));
      expect(finish.raw, equals('tool_calls'));
    });

    test('incomplete max_output_tokens => length', () {
      final response = OpenAIResponsesResponse(
        {
          'id': 'resp_3',
          'model': 'gpt-5-mini',
          'status': 'incomplete',
          'incomplete_details': {'reason': 'max_output_tokens'},
          'output': [],
        },
        null,
        null,
        'openai',
      );

      final finish = response.finishReason!;
      expect(finish.unified, equals(LLMUnifiedFinishReason.length));
      expect(finish.raw, equals('max_output_tokens'));
    });
  });
}

