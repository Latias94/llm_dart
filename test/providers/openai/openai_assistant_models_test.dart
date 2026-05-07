import 'package:llm_dart/models/tool_models.dart';
import 'package:llm_dart/src/compatibility/providers/openai/assistant_models.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI assistant models', () {
    test('serialize create request and parse list response', () {
      final request = CreateAssistantRequest(
        model: 'gpt-4.1-mini',
        name: 'Support Assistant',
        instructions: 'Answer support questions.',
        tools: [
          const CodeInterpreterTool(),
          AssistantFunctionTool(
            function: FunctionObject(
              name: 'lookup_ticket',
              description: 'Lookup a support ticket.',
              parameters: {
                'type': 'object',
                'properties': {
                  'ticket_id': {'type': 'string'},
                },
                'required': ['ticket_id'],
              },
            ),
          ),
        ],
      );

      final requestJson = request.toJson();
      expect(requestJson['model'], equals('gpt-4.1-mini'));
      expect(requestJson['tools'], hasLength(2));

      final response = ListAssistantsResponse.fromJson({
        'object': 'list',
        'data': [
          {
            'id': 'asst_1',
            'object': 'assistant',
            'created_at': 1700000000,
            'name': 'Support Assistant',
            'description': null,
            'model': 'gpt-4.1-mini',
            'instructions': 'Answer support questions.',
            'tools': requestJson['tools'],
            'metadata': <String, dynamic>{},
          },
        ],
        'first_id': 'asst_1',
        'last_id': 'asst_1',
        'has_more': false,
      });

      expect(response.data, hasLength(1));
      expect(response.data.single.id, equals('asst_1'));
      expect(response.data.single.tools, hasLength(2));
    });
  });
}
