import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI Responses lifecycle models', () {
    test('raw response exposes common fields and direct output text', () {
      final response = OpenAIRawResponse.fromJson(
        const {
          'id': 'resp_123',
          'status': 'completed',
          'model': 'gpt-4o',
          'output_text': 'Hello',
          'metadata': {'source': 'test'},
        },
      );

      expect(response.id, 'resp_123');
      expect(response.status, 'completed');
      expect(response.model, 'gpt-4o');
      expect(response.outputText, 'Hello');
      expect(response['metadata'], {'source': 'test'});
      expect(response.toJson(), containsPair('id', 'resp_123'));
    });

    test('raw response extracts output text from message content fallback', () {
      final response = OpenAIRawResponse.fromJson(
        const {
          'id': 'resp_123',
          'output': [
            {
              'type': 'reasoning',
              'content': [],
            },
            {
              'type': 'message',
              'content': [
                {'type': 'refusal', 'refusal': 'no'},
                {'type': 'output_text', 'text': 'Recovered text'},
              ],
            },
          ],
        },
      );

      expect(response.outputText, 'Recovered text');
    });

    test('input items list parses default object and preserves raw items', () {
      final list = OpenAIResponseInputItemsList.fromJson(
        const {
          'data': [
            {
              'id': 'item_1',
              'type': 'message',
              'role': 'user',
              'content': [
                {'type': 'input_text', 'text': 'Hello'},
              ],
              'custom': {'kept': true},
            },
          ],
          'has_more': false,
        },
      );

      expect(list.object, 'list');
      expect(list.hasMore, isFalse);
      expect(list.data.single.id, 'item_1');
      expect(list.data.single.role, 'user');
      expect(list.data.single.content!.single['text'], 'Hello');
      expect(list.data.single.toJson(), containsPair('custom', {'kept': true}));
      expect(list.toJson(), {
        'object': 'list',
        'data': [
          {
            'id': 'item_1',
            'type': 'message',
            'role': 'user',
            'content': [
              {'type': 'input_text', 'text': 'Hello'},
            ],
            'custom': {'kept': true},
          },
        ],
        'has_more': false,
      });
    });

    test('delete result parses default object and round trips', () {
      final result = OpenAIResponseDeleteResult.fromJson(
        const {
          'id': 'resp_123',
          'deleted': true,
        },
      );

      expect(result.id, 'resp_123');
      expect(result.object, 'response.deleted');
      expect(result.deleted, isTrue);
      expect(result.toJson(), {
        'id': 'resp_123',
        'object': 'response.deleted',
        'deleted': true,
      });
    });
  });
}
