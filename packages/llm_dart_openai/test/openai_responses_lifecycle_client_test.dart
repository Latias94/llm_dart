import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIResponsesLifecycleClient', () {
    test('createResponse sends raw Responses payload with headers', () async {
      TransportRequest? capturedRequest;

      final responses = OpenAI(
        apiKey: 'test-key',
        transport: FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'id': 'resp_123',
                'object': 'response',
                'status': 'completed',
                'model': 'gpt-4o',
                'output_text': 'Hello',
              },
            );
          },
        ),
      ).responsesLifecycle(
        settings: const OpenAIResponsesLifecycleSettings(
          organization: 'org_123',
          project: 'proj_456',
          headers: {'x-settings': '1'},
        ),
      );

      final response = await responses.createResponse(
        const {
          'model': 'gpt-4o',
          'input': 'Hello',
          'background': true,
        },
        timeout: const Duration(seconds: 5),
        headers: const {'x-call': '2'},
      );

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.uri.toString(),
          'https://api.openai.com/v1/responses');
      expect(capturedRequest!.method, TransportMethod.post);
      expect(capturedRequest!.responseType, TransportResponseType.json);
      expect(capturedRequest!.timeout, const Duration(seconds: 5));
      expect(capturedRequest!.headers,
          containsPair('authorization', 'Bearer test-key'));
      expect(capturedRequest!.headers,
          containsPair('openai-organization', 'org_123'));
      expect(
          capturedRequest!.headers, containsPair('openai-project', 'proj_456'));
      expect(capturedRequest!.headers,
          containsPair('content-type', 'application/json'));
      expect(
          capturedRequest!.headers, containsPair('accept', 'application/json'));
      expect(capturedRequest!.headers, containsPair('x-settings', '1'));
      expect(capturedRequest!.headers, containsPair('x-call', '2'));
      expect(capturedRequest!.body, {
        'model': 'gpt-4o',
        'input': 'Hello',
        'background': true,
      });

      expect(response.id, 'resp_123');
      expect(response.status, 'completed');
      expect(response.model, 'gpt-4o');
      expect(response.outputText, 'Hello');
    });

    test('get delete cancel and list input items use lifecycle endpoints',
        () async {
      final requests = <TransportRequest>[];
      var callCount = 0;

      final responses = OpenAI(
        apiKey: 'test-key',
        transport: FakeTransportClient(
          onSend: (request) async {
            requests.add(request);
            callCount += 1;

            return switch (callCount) {
              1 => const TransportResponse(
                  statusCode: 200,
                  body: {
                    'id': 'resp_123',
                    'status': 'completed',
                    'output': [
                      {
                        'type': 'message',
                        'content': [
                          {'type': 'output_text', 'text': 'Recovered text'},
                        ],
                      },
                    ],
                  },
                ),
              2 => const TransportResponse(
                  statusCode: 200,
                  body: {
                    'id': 'resp_123',
                    'object': 'response.deleted',
                    'deleted': true,
                  },
                ),
              3 => const TransportResponse(
                  statusCode: 200,
                  body: {
                    'id': 'resp_bg',
                    'status': 'cancelled',
                  },
                ),
              4 => const TransportResponse(
                  statusCode: 200,
                  body: {
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
                    ],
                    'first_id': 'item_1',
                    'last_id': 'item_1',
                    'has_more': false,
                  },
                ),
              _ => throw StateError('Unexpected request $callCount'),
            };
          },
        ),
      ).responsesLifecycle();

      final retrieved = await responses.getResponse(
        'resp_123',
        include: const ['output'],
        startingAfter: 10,
        stream: true,
      );
      final deleted = await responses.deleteResponse('resp_123');
      final cancelled = await responses.cancelResponse('resp_bg');
      final inputItems = await responses.listInputItems(
        'resp_123',
        after: 'item_0',
        include: const ['message.output_text'],
        limit: 20,
      );

      expect(requests, hasLength(4));
      expect(requests[0].method, TransportMethod.get);
      expect(requests[0].uri.path, '/v1/responses/resp_123');
      expect(requests[0].uri.queryParameters, {
        'include': 'output',
        'starting_after': '10',
        'stream': 'true',
      });
      expect(requests[1].method, TransportMethod.delete);
      expect(requests[1].uri.toString(),
          'https://api.openai.com/v1/responses/resp_123');
      expect(requests[2].method, TransportMethod.post);
      expect(requests[2].uri.toString(),
          'https://api.openai.com/v1/responses/resp_bg/cancel');
      expect(requests[3].uri.path, '/v1/responses/resp_123/input_items');
      expect(requests[3].uri.queryParameters, {
        'limit': '20',
        'order': 'desc',
        'after': 'item_0',
        'include': 'message.output_text',
      });

      expect(retrieved.outputText, 'Recovered text');
      expect(deleted.deleted, isTrue);
      expect(cancelled.status, 'cancelled');
      expect(inputItems.data.single.id, 'item_1');
      expect(inputItems.data.single.content!.single['text'], 'Hello');
    });

    test('continue and fork encode previous_response_id explicitly', () async {
      final requests = <TransportRequest>[];

      final responses = OpenAI(
        apiKey: 'test-key',
        transport: FakeTransportClient(
          onSend: (request) async {
            requests.add(request);
            return const TransportResponse(
              statusCode: 200,
              body: {
                'id': 'resp_next',
                'status': 'queued',
              },
            );
          },
        ),
      ).responsesLifecycle();

      await responses.continueConversation(
        'resp_prev',
        const {
          'model': 'gpt-4o',
          'input': 'Continue',
        },
        background: true,
      );
      await responses.forkConversation(
        'resp_fork',
        const {
          'model': 'gpt-4o',
          'input': 'Branch',
        },
      );

      expect(requests, hasLength(2));
      expect(requests[0].body, {
        'model': 'gpt-4o',
        'input': 'Continue',
        'previous_response_id': 'resp_prev',
        'background': true,
      });
      expect(requests[1].body, {
        'model': 'gpt-4o',
        'input': 'Branch',
        'previous_response_id': 'resp_fork',
      });
    });

    test('rejects non-openai profiles', () {
      expect(
        () => OpenAI(apiKey: 'test-key', profile: const XAIProfile())
            .responsesLifecycle(),
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
