import 'dart:convert';

import 'package:llm_dart_transport/dio.dart';
import 'package:llm_dart/legacy.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIProvider root chat bridge', () {
    test(
        'routes structured chat through the modern Responses bridge and keeps residual responses helpers',
        () async {
      TransportRequest? capturedRequest;
      const jsonSchema = StructuredOutputFormat(
        name: 'answer',
        description: 'Structured answer payload.',
        strict: true,
        schema: {
          'type': 'object',
          'properties': {
            'value': {'type': 'string'},
          },
          'required': ['value'],
        },
      );

      final provider = _buildProvider(
        useResponsesAPI: true,
        jsonSchema: jsonSchema,
        transport: FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'id': 'resp_root_structured',
                'model': 'gpt-4.1-mini',
                'created_at': 1710000500,
                'status': 'completed',
                'output': [
                  {
                    'id': 'msg_1',
                    'type': 'message',
                    'status': 'completed',
                    'role': 'assistant',
                    'content': [
                      {
                        'type': 'output_text',
                        'text': '{"value":"Done."}',
                        'annotations': [],
                      },
                    ],
                  },
                ],
              },
            );
          },
        ),
      );

      expect(provider.responses, isA<OpenAIResponses>());

      final response = await provider.chat([
        ChatMessage.user('Return JSON.'),
      ]);

      expect(response.text, '{"value":"Done."}');
      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.uri.toString(), contains('/responses'));

      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['response_format'],
        {
          'type': 'json_schema',
          'json_schema': {
            'name': 'answer',
            'description': 'Structured answer payload.',
            'schema': {
              'type': 'object',
              'properties': {
                'value': {'type': 'string'},
              },
              'required': ['value'],
              'additionalProperties': false,
            },
            'strict': true,
          },
        },
      );
    });

    test(
        'routes user image and file messages through the modern Responses bridge even when responses compatibility is disabled',
        () async {
      TransportRequest? capturedRequest;

      final provider = _buildProvider(
        useResponsesAPI: false,
        transport: FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'id': 'resp_root_multimodal',
                'model': 'gpt-4.1-mini',
                'created_at': 1710000600,
                'status': 'completed',
                'output': [
                  {
                    'id': 'msg_1',
                    'type': 'message',
                    'status': 'completed',
                    'role': 'assistant',
                    'content': [
                      {
                        'type': 'output_text',
                        'text': 'Done.',
                        'annotations': [],
                      },
                    ],
                  },
                ],
              },
            );
          },
        ),
      );

      expect(provider.responses, isNull);

      final response = await provider.chat([
        ChatMessage.user('Describe both inputs.'),
        ChatMessage.image(
          role: ChatRole.user,
          mime: ImageMime.png,
          data: const [1, 2, 3, 4],
        ),
        ChatMessage.file(
          role: ChatRole.user,
          mime: FileMime.pdf,
          data: const [5, 6, 7, 8],
        ),
      ]);

      expect(response.text, 'Done.');
      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.uri.toString(), contains('/responses'));

      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['input'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_text',
                'text': 'Describe both inputs.',
              },
            ],
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_image',
                'image_url': 'data:image/png;base64,AQIDBA==',
              },
            ],
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_file',
                'filename': 'part-0.pdf',
                'file_data': 'data:application/pdf;base64,BQYHCA==',
              },
            ],
          },
        ],
      );
    });

    test('routes common function-tool replay through the modern bridge',
        () async {
      TransportRequest? capturedRequest;
      final toolCall = ToolCall(
        id: 'call_1',
        callType: 'function',
        function: const FunctionCall(
          name: 'weather',
          arguments: '{"city":"Hong Kong"}',
        ),
      );

      final provider = _buildProvider(
        useResponsesAPI: false,
        toolChoice: const AutoToolChoice(),
        transport: FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'id': 'resp_root_tool_replay',
                'model': 'gpt-4.1-mini',
                'created_at': 1710000700,
                'status': 'completed',
                'output': [
                  {
                    'id': 'msg_1',
                    'type': 'message',
                    'status': 'completed',
                    'role': 'assistant',
                    'content': [
                      {
                        'type': 'output_text',
                        'text': 'Done.',
                        'annotations': [],
                      },
                    ],
                  },
                ],
              },
            );
          },
        ),
      );

      final response = await provider.chatWithTools(
        [
          ChatMessage.user('Check the weather.'),
          ChatMessage.toolUse(toolCalls: [toolCall]),
          ChatMessage.toolResult(results: [toolCall]),
        ],
        [
          Tool.function(
            name: 'weather',
            description: 'Get weather information.',
            parameters: const ParametersSchema(
              schemaType: 'object',
              properties: {
                'city': ParameterProperty(
                  propertyType: 'string',
                  description: 'City name.',
                ),
              },
              required: ['city'],
            ),
          ),
        ],
      );

      expect(response.text, 'Done.');
      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.uri.toString(), contains('/responses'));

      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['input'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_text',
                'text': 'Check the weather.',
              },
            ],
          },
          {
            'type': 'function_call',
            'call_id': 'call_1',
            'name': 'weather',
            'arguments': '{"city":"Hong Kong"}',
          },
          {
            'type': 'function_call_output',
            'call_id': 'call_1',
            'output': '{"city":"Hong Kong"}',
          },
        ],
      );
    });

    test('keeps non-OpenAI hosts on the compatibility fallback path', () async {
      RequestOptions? capturedRequest;

      final fallbackDio = Dio();
      fallbackDio.options.baseUrl = 'https://openrouter.ai/api/v1/';
      fallbackDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedRequest = options;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 'chatcmpl_root_openrouter_1',
                  'model': 'openai/gpt-4o-mini',
                  'created': 1710000800,
                  'choices': [
                    {
                      'index': 0,
                      'finish_reason': 'stop',
                      'message': {
                        'role': 'assistant',
                        'content': 'Fallback path used.',
                      },
                    },
                  ],
                },
              ),
            );
          },
        ),
      );

      final originalConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://openrouter.ai/api/v1/',
        model: 'openai/gpt-4o-mini',
      ).withExtensions({
        'customDio': fallbackDio,
        'customTransportClient': FakeTransportClient(
          onSend: (_) async => throw StateError(
            'Modern bridge transport should not be used for non-OpenAI hosts.',
          ),
          onSendStream: (_) async => throw StateError(
            'Modern bridge stream transport should not be used for non-OpenAI hosts.',
          ),
        ),
      });

      final provider = OpenAIProvider(
        OpenAIConfig(
          apiKey: 'test-key',
          baseUrl: 'https://openrouter.ai/api/v1/',
          model: 'openai/gpt-4o-mini',
          originalConfig: originalConfig,
        ),
      );

      final response = await provider.chat([
        ChatMessage.user('Use the compatibility fallback.'),
      ]);

      expect(response.text, 'Fallback path used.');
      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.uri.toString(), contains('/chat/completions'));
    });

    test(
        'routes streaming chat through the modern bridge even when responses compatibility is disabled',
        () async {
      TransportRequest? capturedRequest;

      final provider = _buildProvider(
        useResponsesAPI: false,
        transport: FakeTransportClient(
          onSendStream: (request) async {
            capturedRequest = request;
            return StreamingTransportResponse(
              statusCode: 200,
              stream: Stream.fromIterable([
                utf8.encode(
                  'data: {"type":"response.created","response":{"id":"resp_1","model":"gpt-4.1-mini","created_at":1710000000,"service_tier":"default"}}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"response.output_item.added","output_index":0,"item":{"id":"msg_1","type":"message","status":"in_progress"}}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"response.output_text.delta","item_id":"msg_1","output_index":0,"content_index":0,"delta":"Hello"}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"response.output_text.done","item_id":"msg_1","output_index":0,"content_index":0,"text":"Hello"}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"response.completed","response":{"id":"resp_1","model":"gpt-4.1-mini","created_at":1710000000,"status":"completed","output":[{"id":"msg_1","type":"message","status":"completed","role":"assistant","content":[{"type":"output_text","text":"Hello","annotations":[]}]}],"usage":{"input_tokens":1,"output_tokens":1,"total_tokens":2,"output_tokens_details":{"reasoning_tokens":0}}}}\n\n',
                ),
              ]),
            );
          },
        ),
      );

      expect(provider.responses, isNull);

      final events = await provider.chatStream([
        ChatMessage.user('Say hello.'),
      ]).toList();

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.uri.toString(), contains('/responses'));
      expect(events.whereType<TextDeltaEvent>().single.delta, 'Hello');
      final completion = events.whereType<CompletionEvent>().single;
      expect(completion.response.text, 'Hello');
      expect(completion.response.usage?.totalTokens, 2);
    });
  });
}

OpenAIProvider _buildProvider({
  required FakeTransportClient transport,
  bool useResponsesAPI = false,
  StructuredOutputFormat? jsonSchema,
  ToolChoice? toolChoice,
}) {
  final fallbackDio = Dio();
  fallbackDio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.reject(
          DioException(
            requestOptions: options,
            error: StateError(
              'Legacy OpenAI fallback should not be used in this test.',
            ),
          ),
        );
      },
    ),
  );

  final originalConfig = LLMConfig(
    apiKey: 'test-key',
    baseUrl: 'https://api.openai.com/v1/',
    model: 'gpt-4.1-mini',
    toolChoice: toolChoice,
  ).withExtensions({
    'customTransportClient': transport,
    'customDio': fallbackDio,
    if (jsonSchema != null) 'jsonSchema': jsonSchema,
  });

  return OpenAIProvider(
    OpenAIConfig(
      apiKey: 'test-key',
      baseUrl: 'https://api.openai.com/v1/',
      model: 'gpt-4.1-mini',
      toolChoice: toolChoice,
      useResponsesAPI: useResponsesAPI,
      jsonSchema: jsonSchema,
      originalConfig: originalConfig,
    ),
  );
}
