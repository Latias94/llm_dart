import 'package:llm_dart/providers/openai/responses.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIResponses models', () {
    test('serialize and deserialize response input items list', () {
      final item1 = ResponseInputItem(
        id: 'item_1',
        type: 'message',
        role: 'user',
        content: [
          {'type': 'input_text', 'text': 'Hello'},
        ],
      );
      final item2 = ResponseInputItem(
        id: 'item_2',
        type: 'message',
      );

      final list = ResponseInputItemsList(
        object: 'list',
        data: [item1, item2],
        firstId: 'item_1',
        lastId: 'item_2',
        hasMore: false,
      );

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
          },
          {
            'id': 'item_2',
            'type': 'message',
          },
        ],
        'first_id': 'item_1',
        'last_id': 'item_2',
        'has_more': false,
      });

      final reconstructed = ResponseInputItemsList.fromJson(list.toJson());
      expect(reconstructed.object, equals('list'));
      expect(reconstructed.data, hasLength(2));
      expect(reconstructed.data.first.id, equals('item_1'));
      expect(reconstructed.data.last.id, equals('item_2'));
    });
  });
}
