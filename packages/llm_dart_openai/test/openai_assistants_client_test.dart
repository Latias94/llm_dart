import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIAssistantsClient', () {
    test('serializes assistant requests and parses list responses', () {
      final request = OpenAICreateAssistantRequest(
        model: 'gpt-4.1-mini',
        name: 'Support Assistant',
        instructions: 'Answer support questions.',
        tools: [
          const OpenAIAssistantCodeInterpreterTool(),
          OpenAIAssistantFunctionTool(
            function: FunctionToolDefinition(
              name: 'lookup_ticket',
              description: 'Lookup a support ticket.',
              inputSchema: ToolJsonSchema.object(
                properties: const {
                  'ticket_id': {'type': 'string'},
                },
                required: const ['ticket_id'],
              ),
            ),
          ),
        ],
      );

      final requestJson = request.toJson();
      expect(requestJson['model'], 'gpt-4.1-mini');
      expect(requestJson['tools'], hasLength(2));

      final response = OpenAIListAssistantsResponse.fromJson({
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
            'metadata': <String, Object?>{},
          },
        ],
        'first_id': 'asst_1',
        'last_id': 'asst_1',
        'has_more': false,
      });

      expect(response.data, hasLength(1));
      expect(response.data.single.id, 'asst_1');
      expect(response.data.single.tools, hasLength(2));
      expect(
        response.data.single.createdAt,
        DateTime.fromMillisecondsSinceEpoch(
          1700000000 * 1000,
          isUtc: true,
        ),
      );
    });

    test('listAssistants uses focused transport and configured headers',
        () async {
      TransportRequest? capturedRequest;

      final assistants = OpenAI(
        apiKey: 'test-key',
        transport: FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'object': 'list',
                'data': [
                  {
                    'id': 'asst_1',
                    'created_at': 1700000000,
                    'model': 'gpt-4o',
                    'name': 'Planner',
                    'tools': [],
                  },
                ],
                'has_more': false,
              },
            );
          },
        ),
      ).assistants(
        settings: const OpenAIAssistantsSettings(
          organization: 'org_123',
          project: 'proj_456',
          headers: {'x-settings': '1'},
        ),
      );

      final response = await assistants.listAssistants(
        query: const OpenAIListAssistantsQuery(
          limit: 20,
          order: 'desc',
          after: 'cursor 1',
        ),
        timeout: const Duration(seconds: 5),
        headers: const {'x-call': '2'},
      );

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.method, TransportMethod.get);
      expect(capturedRequest!.uri.path, '/v1/assistants');
      expect(capturedRequest!.uri.queryParameters, {
        'limit': '20',
        'order': 'desc',
        'after': 'cursor 1',
      });
      expect(capturedRequest!.timeout, const Duration(seconds: 5));
      expect(
        capturedRequest!.headers,
        containsPair('authorization', 'Bearer test-key'),
      );
      expect(
        capturedRequest!.headers,
        containsPair('openai-organization', 'org_123'),
      );
      expect(
        capturedRequest!.headers,
        containsPair('openai-project', 'proj_456'),
      );
      expect(capturedRequest!.headers, containsPair('x-settings', '1'));
      expect(capturedRequest!.headers, containsPair('x-call', '2'));
      expect(
          capturedRequest!.headers, containsPair('accept', 'application/json'));

      expect(response.data.single.id, 'asst_1');
      expect(response.data.single.name, 'Planner');
    });

    test('cloneAssistant preserves provider-owned assistant fields', () async {
      final requests = <TransportRequest>[];
      var callCount = 0;

      final assistants = OpenAI(
        apiKey: 'test-key',
        transport: FakeTransportClient(
          onSend: (request) async {
            requests.add(request);
            callCount += 1;

            return switch (callCount) {
              1 => const TransportResponse(
                  statusCode: 200,
                  body: {
                    'id': 'asst_1',
                    'created_at': 1700000000,
                    'model': 'gpt-4o',
                    'name': 'Researcher',
                    'description': 'Original assistant',
                    'instructions': 'Think carefully.',
                    'metadata': {'team': 'core'},
                    'tools': [
                      {'type': 'code_interpreter'},
                    ],
                  },
                ),
              2 => const TransportResponse(
                  statusCode: 200,
                  body: {
                    'id': 'asst_clone',
                    'created_at': 1700000100,
                    'model': 'gpt-4o',
                    'name': 'Researcher Copy',
                    'tools': [
                      {'type': 'code_interpreter'},
                    ],
                  },
                ),
              _ => throw StateError('Unexpected request $callCount'),
            };
          },
        ),
      ).assistants();

      final cloned = await assistants.cloneAssistant(
        'asst_1',
        newName: 'Researcher Copy',
        additionalMetadata: const {'env': 'test'},
      );

      expect(requests, hasLength(2));
      expect(requests[0].uri.toString(),
          'https://api.openai.com/v1/assistants/asst_1');
      expect(requests[1].method, TransportMethod.post);
      expect(
          requests[1].uri.toString(), 'https://api.openai.com/v1/assistants');

      final body = requests[1].body! as Map<String, Object?>;
      expect(body['name'], 'Researcher Copy');
      expect(body['description'], 'Original assistant');
      expect(body['instructions'], 'Think carefully.');
      expect(body['tools'], [
        {'type': 'code_interpreter'},
      ]);

      final metadata = body['metadata']! as Map<String, Object?>;
      expect(metadata['team'], 'core');
      expect(metadata['env'], 'test');
      expect(metadata['cloned_from'], 'asst_1');
      expect(metadata['cloned_at'], isA<String>());
      expect(cloned.id, 'asst_clone');
    });

    test('rejects non-openai profiles', () {
      expect(
        () => OpenAI(apiKey: 'test-key', profile: const XAIProfile())
            .assistants(),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            contains('supports only the OpenAI profile'),
          ),
        ),
      );
    });
  });
}
