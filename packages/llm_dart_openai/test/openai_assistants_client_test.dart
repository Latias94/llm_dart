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

    test('threads messages runs and steps use Assistants v2 endpoints',
        () async {
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
                    'id': 'thread_1',
                    'object': 'thread',
                    'created_at': 1700000000,
                  },
                ),
              2 => const TransportResponse(
                  statusCode: 200,
                  body: {
                    'id': 'msg_1',
                    'object': 'thread.message',
                    'created_at': 1700000001,
                    'thread_id': 'thread_1',
                    'role': 'user',
                    'content': [
                      {
                        'type': 'text',
                        'text': {'value': 'Hello'},
                      },
                    ],
                  },
                ),
              3 => const TransportResponse(
                  statusCode: 200,
                  body: {
                    'object': 'list',
                    'data': [
                      {
                        'id': 'msg_1',
                        'object': 'thread.message',
                        'created_at': 1700000001,
                        'thread_id': 'thread_1',
                        'role': 'user',
                        'content': [],
                      },
                    ],
                    'has_more': false,
                  },
                ),
              4 => const TransportResponse(
                  statusCode: 200,
                  body: {
                    'id': 'run_1',
                    'object': 'thread.run',
                    'created_at': 1700000002,
                    'thread_id': 'thread_1',
                    'assistant_id': 'asst_1',
                    'status': 'queued',
                  },
                ),
              5 => const TransportResponse(
                  statusCode: 200,
                  body: {
                    'id': 'run_1',
                    'object': 'thread.run',
                    'created_at': 1700000002,
                    'thread_id': 'thread_1',
                    'assistant_id': 'asst_1',
                    'status': 'requires_action',
                  },
                ),
              6 => const TransportResponse(
                  statusCode: 200,
                  body: {
                    'id': 'run_1',
                    'object': 'thread.run',
                    'created_at': 1700000002,
                    'thread_id': 'thread_1',
                    'assistant_id': 'asst_1',
                    'status': 'in_progress',
                  },
                ),
              7 => const TransportResponse(
                  statusCode: 200,
                  body: {
                    'object': 'list',
                    'data': [
                      {
                        'id': 'step_1',
                        'object': 'thread.run.step',
                        'created_at': 1700000003,
                        'run_id': 'run_1',
                        'assistant_id': 'asst_1',
                        'thread_id': 'thread_1',
                        'type': 'message_creation',
                        'status': 'completed',
                        'step_details': {'type': 'message_creation'},
                      },
                    ],
                    'has_more': false,
                  },
                ),
              8 => const TransportResponse(
                  statusCode: 200,
                  body: {
                    'id': 'step_1',
                    'object': 'thread.run.step',
                    'created_at': 1700000003,
                    'run_id': 'run_1',
                    'assistant_id': 'asst_1',
                    'thread_id': 'thread_1',
                    'type': 'message_creation',
                    'status': 'completed',
                    'step_details': {'type': 'message_creation'},
                  },
                ),
              _ => throw StateError('Unexpected request $callCount'),
            };
          },
        ),
      ).assistants();

      final thread = await assistants.createThread();
      final message = await assistants.createThreadMessage(
        'thread_1',
        const OpenAICreateThreadMessageRequest(content: 'Hello'),
      );
      final messages = await assistants.listThreadMessages(
        'thread_1',
        query: const OpenAIListThreadMessagesQuery(
          limit: 10,
          runId: 'run_1',
        ),
      );
      final run = await assistants.createThreadRun(
        'thread_1',
        const OpenAICreateRunRequest(
          assistantId: 'asst_1',
          additionalInstructions: 'Be brief.',
        ),
      );
      final submitted = await assistants.submitThreadRunToolOutputs(
        'thread_1',
        'run_1',
        const OpenAISubmitToolOutputsRequest(
          toolOutputs: [
            OpenAIRunToolOutput(
              toolCallId: 'call_1',
              output: 'done',
            ),
          ],
        ),
      );
      final cancelled = await assistants.cancelThreadRun('thread_1', 'run_1');
      final steps = await assistants.listThreadRunSteps(
        'thread_1',
        'run_1',
        query: const OpenAIListRunStepsQuery(limit: 5),
      );
      final step = await assistants.retrieveThreadRunStep(
        'thread_1',
        'run_1',
        'step_1',
      );

      expect(requests, hasLength(8));
      expect(
          requests.every(
              (request) => request.headers['openai-beta'] == 'assistants=v2'),
          isTrue);

      expect(requests[0].method, TransportMethod.post);
      expect(requests[0].uri.path, '/v1/threads');
      expect(requests[0].body, <String, Object?>{});

      expect(requests[1].uri.path, '/v1/threads/thread_1/messages');
      expect(requests[1].body, {
        'role': 'user',
        'content': 'Hello',
      });

      expect(requests[2].uri.path, '/v1/threads/thread_1/messages');
      expect(requests[2].uri.queryParameters, {
        'limit': '10',
        'run_id': 'run_1',
      });

      expect(requests[3].uri.path, '/v1/threads/thread_1/runs');
      expect(requests[3].body, {
        'assistant_id': 'asst_1',
        'additional_instructions': 'Be brief.',
      });

      expect(requests[4].uri.path,
          '/v1/threads/thread_1/runs/run_1/submit_tool_outputs');
      expect(requests[4].body, {
        'tool_outputs': [
          {
            'tool_call_id': 'call_1',
            'output': 'done',
          },
        ],
      });

      expect(requests[5].uri.path, '/v1/threads/thread_1/runs/run_1/cancel');
      expect(requests[6].uri.path, '/v1/threads/thread_1/runs/run_1/steps');
      expect(requests[6].uri.queryParameters, {'limit': '5'});
      expect(
          requests[7].uri.path, '/v1/threads/thread_1/runs/run_1/steps/step_1');

      expect(thread.id, 'thread_1');
      expect(message.id, 'msg_1');
      expect(messages.data.single.id, 'msg_1');
      expect(run.status, 'queued');
      expect(submitted.status, 'requires_action');
      expect(cancelled.status, 'in_progress');
      expect(steps.data.single.id, 'step_1');
      expect(step.id, 'step_1');
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
