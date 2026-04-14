import 'package:llm_dart/legacy.dart';
import 'package:llm_dart/providers/openai/client.dart' as openai_client;
import 'package:llm_dart/providers/openai/config.dart' as openai_config;
import 'package:llm_dart/providers/openai/responses.dart' as openai_responses;
import 'package:llm_dart_transport/dio.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI Responses support extraction', () {
    test('getResponse preserves query shaping after helper extraction',
        () async {
      String? capturedPath;
      final dio = Dio();
      dio.options.baseUrl = 'https://api.openai.com/v1/';
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedPath = options.path;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 'resp_1',
                  'output': [
                    {
                      'type': 'message',
                      'content': [
                        {
                          'type': 'output_text',
                          'text': 'Done.',
                        },
                      ],
                    },
                  ],
                },
              ),
            );
          },
        ),
      );

      final config = _buildResponsesConfig(dio);
      final client = openai_client.OpenAIClient(config);
      final responses = openai_responses.OpenAIResponses(client, config);

      final response = await responses.getResponse(
        'resp_1',
        include: const ['output', 'usage'],
        startingAfter: 5,
        stream: true,
      );

      expect(
        capturedPath,
        equals(
          'responses/resp_1?include=output%2Cusage&starting_after=5&stream=true',
        ),
      );
      expect(response.text, equals('Done.'));
    });

    test('listInputItems preserves query shaping after helper extraction',
        () async {
      String? capturedPath;
      final dio = Dio();
      dio.options.baseUrl = 'https://api.openai.com/v1/';
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedPath = options.path;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'object': 'list',
                  'data': const [],
                  'first_id': null,
                  'last_id': null,
                  'has_more': false,
                },
              ),
            );
          },
        ),
      );

      final config = _buildResponsesConfig(dio);
      final client = openai_client.OpenAIClient(config);
      final responses = openai_responses.OpenAIResponses(client, config);

      final list = await responses.listInputItems(
        'resp_2',
        after: 'item_a',
        before: 'item_z',
        include: const ['content'],
        limit: 10,
        order: 'asc',
      );

      expect(
        capturedPath,
        equals(
          'responses/resp_2/input_items?limit=10&order=asc&after=item_a&before=item_z&include=content',
        ),
      );
      expect(list.object, equals('list'));
      expect(list.data, isEmpty);
    });

    test('continueConversation preserves previous_response_id after extraction',
        () async {
      Map<String, dynamic>? capturedBody;
      final dio = Dio();
      dio.options.baseUrl = 'https://api.openai.com/v1/';
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedBody = Map<String, dynamic>.from(
              options.data as Map<String, dynamic>,
            );
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 'resp_3',
                  'output': [
                    {
                      'type': 'message',
                      'content': [
                        {
                          'type': 'output_text',
                          'text': 'Continued.',
                        },
                      ],
                    },
                  ],
                },
              ),
            );
          },
        ),
      );

      final config = _buildResponsesConfig(dio);
      final client = openai_client.OpenAIClient(config);
      final responses = openai_responses.OpenAIResponses(client, config);

      final response = await responses.continueConversation(
        'resp_prev_123',
        [ChatMessage.user('Continue from here')],
      );

      expect(capturedBody, isNotNull);
      expect(capturedBody!['previous_response_id'], equals('resp_prev_123'));
      expect(response.text, equals('Continued.'));
    });

    test('chatWithToolsBackground preserves background flag after extraction',
        () async {
      Map<String, dynamic>? capturedBody;
      final dio = Dio();
      dio.options.baseUrl = 'https://api.openai.com/v1/';
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedBody = Map<String, dynamic>.from(
              options.data as Map<String, dynamic>,
            );
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 'resp_bg_1',
                  'output': [
                    {
                      'type': 'message',
                      'content': [
                        {
                          'type': 'output_text',
                          'text': 'Queued.',
                        },
                      ],
                    },
                  ],
                },
              ),
            );
          },
        ),
      );

      final config = _buildResponsesConfig(dio);
      final client = openai_client.OpenAIClient(config);
      final responses = openai_responses.OpenAIResponses(client, config);

      final response = await responses.chatWithToolsBackground(
        [ChatMessage.user('Queue this')],
        null,
      );

      expect(capturedBody, isNotNull);
      expect(capturedBody!['background'], isTrue);
      expect(capturedBody!['stream'], isFalse);
      expect(response.text, equals('Queued.'));
    });

    test('deleteResponse wraps non-LLM failures after extraction', () async {
      final config = openai_config.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4.1-mini',
        useResponsesAPI: true,
      );
      final client = _FailingDeleteResponsesClient(config);
      final responses = openai_responses.OpenAIResponses(client, config);

      expect(
        () => responses.deleteResponse('resp_bad_delete'),
        throwsA(
          isA<OpenAIResponsesError>().having(
            (error) => error.responseId,
            'responseId',
            'resp_bad_delete',
          ),
        ),
      );
    });
  });
}

openai_config.OpenAIConfig _buildResponsesConfig(Dio dio) {
  final originalConfig = LLMConfig(
    apiKey: 'test-key',
    baseUrl: 'https://api.openai.com/v1/',
    model: 'gpt-4.1-mini',
  ).withExtensions({
    'customDio': dio,
  });

  return openai_config.OpenAIConfig(
    apiKey: 'test-key',
    baseUrl: 'https://api.openai.com/v1/',
    model: 'gpt-4.1-mini',
    useResponsesAPI: true,
    originalConfig: originalConfig,
  );
}

final class _FailingDeleteResponsesClient extends openai_client.OpenAIClient {
  _FailingDeleteResponsesClient(super.config);

  @override
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    cancelToken,
  }) async {
    throw StateError('boom');
  }
}
