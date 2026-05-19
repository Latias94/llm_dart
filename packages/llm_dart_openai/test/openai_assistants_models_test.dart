import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI Assistants models', () {
    test('assistant parses typed and raw tools with response format', () {
      final assistant = OpenAIAssistant.fromJson(
        const {
          'id': 'asst_1',
          'object': 'assistant',
          'created_at': 1700000000,
          'name': 'Planner',
          'model': 'gpt-4o',
          'tools': [
            {'type': 'code_interpreter'},
            {
              'type': 'file_search',
              'file_search': {'max_num_results': 4},
            },
            {
              'type': 'function',
              'function': {
                'name': 'lookup',
                'description': 'Lookup data.',
                'parameters': {
                  'type': 'object',
                  'properties': {
                    'id': {'type': 'string'},
                  },
                },
                'strict': true,
              },
            },
            {
              'type': 'custom_tool',
              'custom': {'kept': true},
            },
          ],
          'response_format': {
            'type': 'json_schema',
            'json_schema': {
              'name': 'result',
              'schema': {'type': 'object'},
              'strict': true,
            },
            'native_flag': 'kept',
          },
          'metadata': {'team': 'core'},
        },
      );

      expect(assistant.tools, hasLength(4));
      expect(assistant.tools[0], isA<OpenAIAssistantCodeInterpreterTool>());
      expect(
        (assistant.tools[1] as OpenAIAssistantFileSearchTool).maxNumResults,
        4,
      );
      expect(
        (assistant.tools[2] as OpenAIAssistantFunctionTool).function.name,
        'lookup',
      );
      expect(assistant.tools[3], isA<OpenAIAssistantRawTool>());
      expect(assistant.tools[3].toJson(), {
        'type': 'custom_tool',
        'custom': {'kept': true},
      });
      expect(assistant.responseFormat!.toJson(), {
        'type': 'json_schema',
        'json_schema': {
          'name': 'result',
          'schema': {'type': 'object'},
          'strict': true,
        },
        'native_flag': 'kept',
      });
    });

    test('create and modify requests encode optional assistant fields', () {
      final tool = OpenAIAssistantFunctionTool(
        function: FunctionToolDefinition(
          name: 'lookup_ticket',
          inputSchema: ToolJsonSchema.object(
            properties: const {
              'ticket_id': {'type': 'string'},
            },
            required: const ['ticket_id'],
          ),
          strict: true,
        ),
      );

      final create = OpenAICreateAssistantRequest(
        model: 'gpt-4o',
        name: 'Support',
        tools: [tool],
        toolResources: const OpenAIAssistantToolResources(
          codeInterpreter: OpenAIAssistantCodeInterpreterResources(
            fileIds: ['file_1'],
          ),
        ),
        metadata: const {'team': 'support'},
        responseFormat: const OpenAIAssistantResponseFormat.jsonObject(),
      );

      expect(create.toJson(), {
        'model': 'gpt-4o',
        'name': 'Support',
        'tools': [
          {
            'type': 'function',
            'function': {
              'name': 'lookup_ticket',
              'parameters': {
                'type': 'object',
                'properties': {
                  'ticket_id': {'type': 'string'},
                },
                'required': ['ticket_id'],
              },
              'strict': true,
            },
          },
        ],
        'tool_resources': {
          'code_interpreter': {
            'file_ids': ['file_1'],
          },
        },
        'metadata': {'team': 'support'},
        'response_format': {'type': 'json_object'},
      });

      expect(
        const OpenAIModifyAssistantRequest(
          instructions: 'Updated',
          tools: [],
        ).toJson(),
        {
          'instructions': 'Updated',
          'tools': [],
        },
      );
    });

    test('list and delete responses round trip', () {
      final response = OpenAIListAssistantsResponse.fromJson(
        const {
          'data': [
            {
              'id': 'asst_1',
              'created_at': 1700000000,
              'model': 'gpt-4o',
              'tools': [],
            },
          ],
          'first_id': 'asst_1',
          'last_id': 'asst_1',
          'has_more': false,
        },
      );

      expect(response.object, 'list');
      expect(response.data.single.id, 'asst_1');
      expect(response.toJson(), {
        'object': 'list',
        'data': [
          {
            'id': 'asst_1',
            'object': 'assistant',
            'created_at': 1700000000,
            'model': 'gpt-4o',
            'tools': [],
          },
        ],
        'first_id': 'asst_1',
        'last_id': 'asst_1',
        'has_more': false,
      });

      expect(
        OpenAIDeleteAssistantResponse.fromJson(
          const {'id': 'asst_1', 'deleted': true},
        ).toJson(),
        {
          'id': 'asst_1',
          'object': 'assistant.deleted',
          'deleted': true,
        },
      );
    });

    test('list query validates limit and filters empty cursors', () {
      expect(
        const OpenAIListAssistantsQuery(
          limit: 25,
          order: 'asc',
          after: '',
          before: 'asst_1',
        ).toQueryParameters(),
        {
          'limit': '25',
          'order': 'asc',
          'before': 'asst_1',
        },
      );
      expect(
        () => const OpenAIListAssistantsQuery(limit: 0).toQueryParameters(),
        throwsArgumentError,
      );
    });
  });
}
