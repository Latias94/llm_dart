import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAILanguageModel', () {
    test('generate maps a Responses API payload to the unified result',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'resp_1',
                'model': 'gpt-4.1-mini',
                'created_at': 1710000000,
                'status': 'completed',
                'service_tier': 'default',
                'output': [
                  {
                    'id': 'rs_1',
                    'type': 'reasoning',
                    'summary': [
                      {
                        'type': 'summary_text',
                        'text': 'Thinking through the answer.',
                      },
                    ],
                  },
                  {
                    'id': 'msg_1',
                    'type': 'message',
                    'status': 'completed',
                    'role': 'assistant',
                    'content': [
                      {
                        'type': 'output_text',
                        'text': 'Hello from OpenAI.',
                        'annotations': [],
                      },
                    ],
                  },
                ],
                'usage': {
                  'input_tokens': 11,
                  'output_tokens': 7,
                  'total_tokens': 18,
                  'output_tokens_details': {
                    'reasoning_tokens': 3,
                  },
                },
              },
            );
          },
        ),
      ).chatModel('gpt-4.1-mini');

      final result = await model.generate(
        GenerateTextRequest(
          prompt: [
            SystemPromptMessage.text('You are concise.'),
            UserPromptMessage.text('Say hello.'),
          ],
          callOptions: const CallOptions(
            timeout: Duration(seconds: 5),
            headers: {
              'x-test': '1',
            },
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.method, TransportMethod.post);
      expect(capturedRequest!.responseType, TransportResponseType.json);
      expect(capturedRequest!.timeout, const Duration(seconds: 5));
      expect(capturedRequest!.headers['x-test'], '1');

      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(requestBody['model'], 'gpt-4.1-mini');
      expect(requestBody['stream'], isFalse);

      expect(result.text, 'Hello from OpenAI.');
      expect(result.reasoningText, 'Thinking through the answer.');
      expect(result.finishReason, FinishReason.stop);
      expect(result.rawFinishReason, isNull);
      expect(result.responseId, 'resp_1');
      expect(result.responseModelId, 'gpt-4.1-mini');
      expect(
        result.responseTimestamp,
        DateTime.fromMillisecondsSinceEpoch(1710000000 * 1000, isUtc: true),
      );
      expect(result.usage?.reasoningTokens, 3);
      expect(
        result.providerMetadata!['openai'],
        allOf(
          containsPair('status', 'completed'),
          containsPair('serviceTier', 'default'),
        ),
      );
    });

    test('generate encodes user multimodal prompt parts for the Responses API',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'resp_multimodal',
                'model': 'gpt-4.1-mini',
                'created_at': 1710000000,
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
                'usage': {
                  'input_tokens': 6,
                  'output_tokens': 1,
                  'total_tokens': 7,
                  'output_tokens_details': {
                    'reasoning_tokens': 0,
                  },
                },
              },
            );
          },
        ),
      ).chatModel('gpt-4.1-mini');

      await model.generate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage(
              parts: const [
                TextPromptPart('Describe both inputs.'),
                ImagePromptPart(
                  mediaType: 'image/png',
                  bytes: [0, 1, 2, 3],
                ),
                FilePromptPart(
                  mediaType: 'application/pdf',
                  bytes: [1, 2, 3, 4],
                ),
              ],
            ),
          ],
        ),
      );

      expect(capturedRequest, isNotNull);
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
              {
                'type': 'input_image',
                'image_url': 'data:image/png;base64,AAECAw==',
              },
              {
                'type': 'input_file',
                'filename': 'part-2.pdf',
                'file_data': 'data:application/pdf;base64,AQIDBA==',
              },
            ],
          },
        ],
      );
    });

    test(
        'generate encodes OpenAI-owned imageDetail and PDF file handles for the Responses API',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'resp_prompt_hints',
                'model': 'gpt-4.1-mini',
                'created_at': 1710000000,
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
                'usage': {
                  'input_tokens': 6,
                  'output_tokens': 1,
                  'total_tokens': 7,
                  'output_tokens_details': {
                    'reasoning_tokens': 0,
                  },
                },
              },
            );
          },
        ),
      ).chatModel('gpt-4.1-mini');

      await model.generate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage(
              parts: [
                const ImagePromptPart(
                  mediaType: 'image/png',
                  providerMetadata: ProviderMetadata({
                    'openai': {
                      'fileId': 'assistant-img-abc123',
                      'imageDetail': 'high',
                    },
                  }),
                ),
                const FilePromptPart(
                  mediaType: 'application/pdf',
                  providerMetadata: ProviderMetadata({
                    'openai': {
                      'fileId': 'file-pdf-12345',
                    },
                  }),
                ),
                FilePromptPart(
                  mediaType: 'application/pdf',
                  uri: Uri.parse('https://example.com/document.pdf'),
                ),
              ],
            ),
          ],
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['input'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_image',
                'file_id': 'assistant-img-abc123',
                'detail': 'high',
              },
              {
                'type': 'input_file',
                'file_id': 'file-pdf-12345',
              },
              {
                'type': 'input_file',
                'file_url': 'https://example.com/document.pdf',
              },
            ],
          },
        ],
      );
    });

    test(
        'generate forwards common tools, built-in tools, tool choice, and structured output to the Responses request body',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'resp_tools',
                'model': 'gpt-4.1-mini',
                'created_at': 1710000000,
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
                'usage': {
                  'input_tokens': 1,
                  'output_tokens': 1,
                  'total_tokens': 2,
                  'output_tokens_details': {
                    'reasoning_tokens': 0,
                  },
                },
              },
            );
          },
        ),
      ).chatModel('gpt-4.1-mini');

      await model.generate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Use tools and return JSON.'),
          ],
          tools: [
            FunctionToolDefinition(
              name: 'weather',
              description: 'Get the weather.',
              inputSchema: ToolJsonSchema.object(
                properties: {
                  'city': {'type': 'string'},
                },
                required: ['city'],
              ),
              strict: true,
            ),
          ],
          toolChoice: const SpecificToolChoice('weather'),
          callOptions: const CallOptions(
            providerOptions: OpenAIGenerateTextOptions(
              parallelToolCalls: true,
              builtInTools: [
                OpenAIWebSearchTool(),
                OpenAIFileSearchTool(
                  vectorStoreIds: ['vs_123'],
                ),
              ],
              responseFormat: OpenAIJsonSchemaResponseFormat(
                name: 'answer',
                schema: {
                  'type': 'object',
                  'properties': {
                    'value': {'type': 'string'},
                  },
                },
                strict: true,
              ),
            ),
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;

      expect(
        requestBody['tools'],
        [
          {
            'type': 'function',
            'name': 'weather',
            'description': 'Get the weather.',
            'parameters': {
              'type': 'object',
              'properties': {
                'city': {'type': 'string'},
              },
              'required': ['city'],
            },
            'strict': true,
          },
          {
            'type': 'web_search_preview',
          },
          {
            'type': 'file_search',
            'vector_store_ids': ['vs_123'],
          },
        ],
      );
      expect(
        requestBody['tool_choice'],
        {
          'type': 'function',
          'function': {'name': 'weather'},
        },
      );
      expect(requestBody['parallel_tool_calls'], isTrue);
      expect(
        requestBody['response_format'],
        {
          'type': 'json_schema',
          'json_schema': {
            'name': 'answer',
            'schema': {
              'type': 'object',
              'properties': {
                'value': {'type': 'string'},
              },
              'additionalProperties': false,
            },
            'strict': true,
          },
        },
      );
    });

    test('generate forwards OpenAI Responses provider-owned request options',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'resp_request_options',
                'model': 'gpt-4.1-mini',
                'created_at': 1710000000,
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
                'usage': {
                  'input_tokens': 1,
                  'output_tokens': 1,
                  'total_tokens': 2,
                  'output_tokens_details': {
                    'reasoning_tokens': 0,
                  },
                },
              },
            );
          },
        ),
      ).chatModel('gpt-4.1-mini');

      await model.generate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Use provider-owned request options.'),
          ],
          callOptions: const CallOptions(
            providerOptions: OpenAIGenerateTextOptions(
              instructions: 'Keep the original system framing.',
              maxToolCalls: 3,
              metadata: {
                'traceId': 'trace_123',
                'flags': ['alpha', 'beta'],
              },
              truncation: OpenAIResponseTruncation.disabled,
              user: 'user_123',
            ),
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody,
        allOf(
          containsPair('instructions', 'Keep the original system framing.'),
          containsPair('max_tool_calls', 3),
          containsPair('metadata', {
            'traceId': 'trace_123',
            'flags': ['alpha', 'beta'],
          }),
          containsPair('truncation', 'disabled'),
          containsPair('user', 'user_123'),
        ),
      );
    });

    test(
        'generate forwards shared responseFormat from GenerateTextOptions to the Responses request body',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'resp_shared_format',
                'model': 'gpt-4.1-mini',
                'created_at': 1710000000,
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
                'usage': {
                  'input_tokens': 1,
                  'output_tokens': 1,
                  'total_tokens': 2,
                  'output_tokens_details': {
                    'reasoning_tokens': 0,
                  },
                },
              },
            );
          },
        ),
      ).chatModel('gpt-4.1-mini');

      await model.generate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Return JSON.'),
          ],
          options: GenerateTextOptions(
            responseFormat: JsonResponseFormat(
              name: 'answer',
              description: 'Structured answer payload.',
              strict: true,
              schema: JsonSchema.object(
                properties: const {
                  'value': {'type': 'string'},
                },
                required: const ['value'],
              ),
            ),
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
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
        'generate preserves OpenAI provider options when overlaying shared responseFormat',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'resp_shared_format_overlay',
                'model': 'gpt-4.1-mini',
                'created_at': 1710000000,
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
                'usage': {
                  'input_tokens': 1,
                  'output_tokens': 1,
                  'total_tokens': 2,
                  'output_tokens_details': {
                    'reasoning_tokens': 0,
                  },
                },
              },
            );
          },
        ),
      ).chatModel('gpt-4.1-mini');

      await model.generate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Return JSON.'),
          ],
          options: GenerateTextOptions(
            responseFormat: JsonResponseFormat(
              name: 'answer',
              strict: true,
              schema: JsonSchema.object(
                properties: const {
                  'value': {'type': 'string'},
                },
                required: const ['value'],
              ),
            ),
          ),
          callOptions: const CallOptions(
            providerOptions: OpenAIGenerateTextOptions(
              previousResponseId: 'resp_prev',
              parallelToolCalls: true,
              serviceTier: 'flex',
              verbosity: 'high',
              instructions: 'Retain the response behavior.',
              maxToolCalls: 2,
              metadata: {
                'traceId': 'trace_overlay',
              },
              truncation: OpenAIResponseTruncation.auto,
              user: 'user_overlay',
              builtInTools: [
                OpenAIWebSearchTool(),
              ],
            ),
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(requestBody['previous_response_id'], 'resp_prev');
      expect(requestBody['parallel_tool_calls'], isTrue);
      expect(requestBody['service_tier'], 'flex');
      expect(requestBody['instructions'], 'Retain the response behavior.');
      expect(requestBody['max_tool_calls'], 2);
      expect(
        requestBody['metadata'],
        {
          'traceId': 'trace_overlay',
        },
      );
      expect(requestBody['truncation'], 'auto');
      expect(requestBody['user'], 'user_overlay');
      expect(
        requestBody['text'],
        {
          'verbosity': 'high',
        },
      );
      expect(
        requestBody['tools'],
        [
          {
            'type': 'web_search_preview',
          },
        ],
      );
      expect(
        requestBody['response_format'],
        {
          'type': 'json_schema',
          'json_schema': {
            'name': 'answer',
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
        'generate rejects configuring shared and OpenAI-specific response formats at the same time',
        () async {
      var sendCount = 0;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            sendCount += 1;
            return TransportResponse(statusCode: 200, body: const {});
          },
        ),
      ).chatModel('gpt-4.1-mini');

      await expectLater(
        model.generate(
          GenerateTextRequest(
            prompt: [
              UserPromptMessage.text('Return JSON.'),
            ],
            options: GenerateTextOptions(
              responseFormat: JsonResponseFormat(
                schema: JsonSchema.object(
                  properties: const {
                    'value': {'type': 'string'},
                  },
                ),
              ),
            ),
            callOptions: const CallOptions(
              providerOptions: OpenAIGenerateTextOptions(
                responseFormat: OpenAIJsonSchemaResponseFormat(
                  name: 'answer',
                  schema: {
                    'type': 'object',
                    'properties': {
                      'value': {'type': 'string'},
                    },
                  },
                ),
              ),
            ),
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('responseFormat'),
          ),
        ),
      );

      expect(sendCount, 0);
    });

    test('generate maps source annotations to typed source references',
        () async {
      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'resp_sources',
                'model': 'gpt-4.1-mini',
                'created_at': 1710000000,
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
                        'text': 'Based on cited sources.',
                        'annotations': [
                          {
                            'type': 'url_citation',
                            'url': 'https://example.com',
                            'title': 'Example URL',
                            'start_index': 0,
                            'end_index': 5,
                          },
                          {
                            'type': 'file_citation',
                            'file_id': 'file_1',
                            'filename': 'resource1.json',
                            'index': 12,
                          },
                        ],
                      },
                    ],
                  },
                ],
                'usage': {
                  'input_tokens': 5,
                  'output_tokens': 4,
                  'total_tokens': 9,
                  'output_tokens_details': {
                    'reasoning_tokens': 0,
                  },
                },
              },
            );
          },
        ),
      ).chatModel('gpt-4.1-mini');

      final result = await model.generate(
        GenerateTextRequest(
          prompt: [UserPromptMessage.text('Summarize the sources.')],
        ),
      );

      final sources = result.content.whereType<SourceContentPart>().toList();
      expect(sources, hasLength(2));

      final urlSource = sources[0].source;
      expect(urlSource.kind, SourceReferenceKind.url);
      expect(urlSource.sourceId, 'https://example.com');
      expect(urlSource.uri, Uri.parse('https://example.com'));
      expect(urlSource.title, 'Example URL');

      final documentSource = sources[1].source;
      expect(documentSource.kind, SourceReferenceKind.document);
      expect(documentSource.sourceId, 'file_1');
      expect(documentSource.title, 'resource1.json');
      expect(documentSource.filename, 'resource1.json');
      expect(documentSource.mediaType, 'text/plain');
      expect(
        documentSource.providerMetadata!['openai'],
        allOf(
          containsPair('annotationType', 'file_citation'),
          containsPair('fileId', 'file_1'),
          containsPair('index', 12),
        ),
      );
    });

    test('generate exposes raw finish reason for incomplete responses',
        () async {
      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'resp_incomplete',
                'model': 'gpt-4.1-mini',
                'created_at': 1710000100,
                'status': 'incomplete',
                'incomplete_details': {
                  'reason': 'max_output_tokens',
                },
                'output': [
                  {
                    'id': 'msg_1',
                    'type': 'message',
                    'status': 'completed',
                    'role': 'assistant',
                    'content': [
                      {
                        'type': 'output_text',
                        'text': 'Partial answer',
                        'annotations': [],
                      },
                    ],
                  },
                ],
                'usage': {
                  'input_tokens': 11,
                  'output_tokens': 7,
                  'total_tokens': 18,
                  'output_tokens_details': {
                    'reasoning_tokens': 3,
                  },
                },
              },
            );
          },
        ),
      ).chatModel('gpt-4.1-mini');

      final result = await model.generate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Say hello.'),
          ],
        ),
      );

      expect(result.finishReason, FinishReason.maxTokens);
      expect(result.rawFinishReason, 'max_output_tokens');
    });

    test('stream maps SSE responses to unified stream events', () async {
      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSendStream: (request) async {
            expect(request.method, TransportMethod.post);

            return StreamingTransportResponse(
              statusCode: 200,
              stream: Stream.fromIterable([
                utf8.encode(
                  'data: {"type":"response.created","response":{"id":"resp_1","model":"gpt-4.1-mini","created_at":1710000000,"service_tier":"default"}}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"response.output_item.added","output_index":0,"item":{"id":"msg_1","type":"message","status":"in_progress"}}\n',
                ),
                utf8.encode('\n'),
                utf8.encode(
                  'data: {"type":"response.output_text.delta","item_id":"msg_1","output_index":0,"content_index":0,"delta":"Hel',
                ),
                utf8.encode('lo"}\n\n'),
                utf8.encode(
                  'data: {"type":"response.output_text.done","item_id":"msg_1","output_index":0,"content_index":0,"text":"Hello"}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"response.output_item.done","output_index":1,"item":{"id":"ws_1","type":"web_search_call","status":"completed","action":{"type":"search","query":"hello"}}}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"response.completed","response":{"id":"resp_1","model":"gpt-4.1-mini","created_at":1710000000,"status":"completed","output":[{"id":"msg_1","type":"message","status":"completed","role":"assistant","content":[{"type":"output_text","text":"Hello","annotations":[]}]}],"usage":{"input_tokens":1,"output_tokens":1,"total_tokens":2,"output_tokens_details":{"reasoning_tokens":0}}}}\n\n',
                ),
              ]),
            );
          },
        ),
      ).chatModel('gpt-4.1-mini');

      final events = await model
          .stream(
            GenerateTextRequest(
              prompt: [
                UserPromptMessage.text('Say hello.'),
              ],
            ),
          )
          .toList();

      expect(events.first, isA<StartEvent>());
      expect((events.first as StartEvent).warnings, isEmpty);
      final responseMetadata = events.whereType<ResponseMetadataEvent>().single;
      expect(responseMetadata.responseId, 'resp_1');
      expect(responseMetadata.modelId, 'gpt-4.1-mini');
      expect(events.whereType<TextStartEvent>().single.id, 'msg_1');
      expect(events.whereType<TextDeltaEvent>().single.delta, 'Hello');
      expect(events.whereType<TextEndEvent>().single.id, 'msg_1');
      expect(events.whereType<CustomEvent>().single.kind,
          'openai.web_search_call');

      final finish = events.whereType<FinishEvent>().single;
      expect(finish.finishReason, FinishReason.stop);
      expect(finish.usage?.totalTokens, 2);
    });

    test('stream maps output annotations to typed source events', () async {
      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSendStream: (request) async {
            expect(request.method, TransportMethod.post);

            return StreamingTransportResponse(
              statusCode: 200,
              stream: Stream.fromIterable([
                utf8.encode(
                  'data: {"type":"response.created","response":{"id":"resp_sources","model":"gpt-4.1-mini","created_at":1710000000,"service_tier":"default"}}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"response.output_text.annotation.added","item_id":"msg_1","output_index":0,"content_index":0,"annotation_index":0,"annotation":{"type":"url_citation","url":"https://example.com","title":"Example URL","start_index":0,"end_index":5}}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"response.output_text.annotation.added","item_id":"msg_1","output_index":0,"content_index":0,"annotation_index":1,"annotation":{"type":"file_citation","file_id":"file_1","filename":"resource1.json","index":12}}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"response.completed","response":{"id":"resp_sources","model":"gpt-4.1-mini","created_at":1710000000,"status":"completed","output":[],"usage":{"input_tokens":5,"output_tokens":4,"total_tokens":9,"output_tokens_details":{"reasoning_tokens":0}}}}\n\n',
                ),
              ]),
            );
          },
        ),
      ).chatModel('gpt-4.1-mini');

      final events = await model
          .stream(
            GenerateTextRequest(
              prompt: [
                UserPromptMessage.text('Summarize the annotated sources.'),
              ],
            ),
          )
          .toList();

      final sources =
          events.whereType<SourceEvent>().map((event) => event.source).toList();
      expect(sources, hasLength(2));

      expect(sources[0].kind, SourceReferenceKind.url);
      expect(sources[0].sourceId, 'https://example.com');
      expect(sources[0].uri, Uri.parse('https://example.com'));
      expect(sources[0].title, 'Example URL');

      expect(sources[1].kind, SourceReferenceKind.document);
      expect(sources[1].sourceId, 'file_1');
      expect(sources[1].filename, 'resource1.json');
      expect(
        sources[1].providerMetadata!['openai'],
        allOf(
          containsPair('annotationType', 'file_citation'),
          containsPair('fileId', 'file_1'),
          containsPair('index', 12),
        ),
      );

      final finish = events.whereType<FinishEvent>().single;
      expect(finish.finishReason, FinishReason.stop);
      expect(finish.usage?.totalTokens, 9);
    });

    test('stream maps reasoning summary events to unified reasoning events',
        () async {
      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSendStream: (request) async {
            expect(request.method, TransportMethod.post);

            return StreamingTransportResponse(
              statusCode: 200,
              stream: Stream.fromIterable([
                utf8.encode(
                  'data: {"type":"response.created","response":{"id":"resp_reasoning","model":"gpt-4.1-mini","created_at":1710000000,"service_tier":"default"}}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"response.reasoning_summary_part.added","item_id":"rs_1","output_index":0,"summary_index":0}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"response.reasoning_summary_text.delta","item_id":"rs_1","output_index":0,"summary_index":0,"delta":"Plan"}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"response.reasoning_summary_part.done","item_id":"rs_1","output_index":0,"summary_index":0}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"response.completed","response":{"id":"resp_reasoning","model":"gpt-4.1-mini","created_at":1710000000,"status":"completed","output":[],"usage":{"input_tokens":2,"output_tokens":3,"total_tokens":5,"output_tokens_details":{"reasoning_tokens":3}}}}\n\n',
                ),
              ]),
            );
          },
        ),
      ).chatModel('gpt-4.1-mini');

      final events = await model
          .stream(
            GenerateTextRequest(
              prompt: [
                UserPromptMessage.text('Think before you answer.'),
              ],
            ),
          )
          .toList();

      expect(events.first, isA<StartEvent>());
      expect(events.whereType<ResponseMetadataEvent>().single.responseId,
          'resp_reasoning');

      final reasoningStart = events.whereType<ReasoningStartEvent>().single;
      expect(reasoningStart.id, 'rs_1:0');

      final reasoningDelta = events.whereType<ReasoningDeltaEvent>().single;
      expect(reasoningDelta.id, 'rs_1:0');
      expect(reasoningDelta.delta, 'Plan');

      final reasoningEnd = events.whereType<ReasoningEndEvent>().single;
      expect(reasoningEnd.id, 'rs_1:0');

      final finish = events.whereType<FinishEvent>().single;
      expect(finish.finishReason, FinishReason.stop);
      expect(finish.usage?.reasoningTokens, 3);
      expect(finish.usage?.totalTokens, 5);
    });

    test('stream maps MCP approval requests to unified approval events',
        () async {
      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSendStream: (request) async {
            expect(request.method, TransportMethod.post);

            return StreamingTransportResponse(
              statusCode: 200,
              stream: Stream.fromIterable([
                utf8.encode(
                  'data: {"type":"response.created","response":{"id":"resp_approval","model":"gpt-4.1-mini","created_at":1710000000,"service_tier":"default"}}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"response.output_item.done","output_index":0,"item":{"id":"approval-1","type":"mcp_approval_request","name":"create_short_url","arguments":"{\\"url\\":\\"https://ai-sdk.dev\\"}","server_label":"zip1"}}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"response.completed","response":{"id":"resp_approval","model":"gpt-4.1-mini","created_at":1710000000,"status":"completed","output":[],"usage":{"input_tokens":1,"output_tokens":1,"total_tokens":2,"output_tokens_details":{"reasoning_tokens":0}}}}\n\n',
                ),
              ]),
            );
          },
        ),
      ).chatModel('gpt-4.1-mini');

      final events = await model
          .stream(
            GenerateTextRequest(
              prompt: [
                UserPromptMessage.text('Open the short URL tool.'),
              ],
            ),
          )
          .toList();

      final toolCall = events.whereType<ToolCallEvent>().single.toolCall;
      expect(toolCall.toolCallId, 'approval-1');
      expect(toolCall.toolName, 'mcp.create_short_url');
      expect(toolCall.providerExecuted, isTrue);
      expect(toolCall.isDynamic, isTrue);
      expect(toolCall.title, 'zip1');
      expect((toolCall.input as Map<String, Object?>)['url'],
          'https://ai-sdk.dev');

      final approval = events.whereType<ToolApprovalRequestEvent>().single;
      expect(approval.approvalId, 'approval-1');
      expect(approval.toolCallId, 'approval-1');
      expect(events.whereType<FinishEvent>().single.finishReason,
          FinishReason.toolCalls);
    });

    test('stream maps malformed function-call arguments to tool input errors',
        () async {
      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSendStream: (request) async {
            expect(request.method, TransportMethod.post);

            return StreamingTransportResponse(
              statusCode: 200,
              stream: Stream.fromIterable([
                utf8.encode(
                  'data: {"type":"response.created","response":{"id":"resp_invalid_tool","model":"gpt-4.1-mini","created_at":1710000000,"service_tier":"default"}}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"response.output_item.added","output_index":0,"item":{"id":"fc_1","type":"function_call","call_id":"call_1","name":"weather","arguments":"","status":"in_progress"}}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"response.function_call_arguments.delta","output_index":0,"delta":"{\\"city\\":"}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"response.output_item.done","output_index":0,"item":{"id":"fc_1","type":"function_call","call_id":"call_1","name":"weather","arguments":"{\\"city\\":","status":"completed"}}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"response.completed","response":{"id":"resp_invalid_tool","model":"gpt-4.1-mini","created_at":1710000000,"status":"completed","output":[],"usage":{"input_tokens":1,"output_tokens":1,"total_tokens":2,"output_tokens_details":{"reasoning_tokens":0}}}}\n\n',
                ),
              ]),
            );
          },
        ),
      ).chatModel('gpt-4.1-mini');

      final events = await model
          .stream(
            GenerateTextRequest(
              prompt: [
                UserPromptMessage.text('Call the weather tool.'),
              ],
            ),
          )
          .toList();

      expect(
          events.whereType<ToolInputStartEvent>().single.toolCallId, 'call_1');
      expect(events.whereType<ToolInputDeltaEvent>().single.delta, '{"city":');
      expect(events.whereType<ToolInputEndEvent>(), isEmpty);
      expect(events.whereType<ToolCallEvent>(), isEmpty);

      final toolInputError = events.whereType<ToolInputErrorEvent>().single;
      expect(toolInputError.toolCallId, 'call_1');
      expect(toolInputError.toolName, 'weather');
      expect(toolInputError.input, '{"city":');
      expect(
        toolInputError.errorText,
        contains('Invalid JSON tool arguments for "weather"'),
      );
      expect(toolInputError.providerExecuted, isFalse);
      expect(toolInputError.isDynamic, isFalse);

      final finish = events.whereType<FinishEvent>().single;
      expect(finish.finishReason, FinishReason.toolCalls);
    });

    test('stream maps failed responses to error and finish events', () async {
      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSendStream: (request) async {
            expect(request.method, TransportMethod.post);

            return StreamingTransportResponse(
              statusCode: 200,
              stream: Stream.fromIterable([
                utf8.encode(
                  'data: {"type":"response.failed","response":{"id":"resp_failed","model":"gpt-4.1-mini","created_at":1710000200,"status":"failed","error":{"type":"server_error","message":"upstream failed"},"usage":{"input_tokens":2,"output_tokens":0,"total_tokens":2,"output_tokens_details":{"reasoning_tokens":0}}}}\n\n',
                ),
              ]),
            );
          },
        ),
      ).chatModel('gpt-4.1-mini');

      final events = await model
          .stream(
            GenerateTextRequest(
              prompt: [
                UserPromptMessage.text('Trigger a failure.'),
              ],
            ),
          )
          .toList();

      expect(events.first, isA<StartEvent>());

      final responseMetadata = events.whereType<ResponseMetadataEvent>().single;
      expect(responseMetadata.responseId, 'resp_failed');
      expect(responseMetadata.modelId, 'gpt-4.1-mini');

      final errorEvent = events.whereType<ErrorEvent>().single;
      expect(errorEvent.error.kind, ModelErrorKind.provider);
      expect(errorEvent.error.code, 'server_error');
      expect(errorEvent.error.message, 'upstream failed');

      final finish = events.whereType<FinishEvent>().single;
      expect(finish.finishReason, FinishReason.error);
      expect(finish.rawFinishReason, isNull);
      expect(finish.usage?.totalTokens, 2);
      expect(
        finish.providerMetadata?.values['openai'],
        containsPair('status', 'failed'),
      );
    });

    test('stream maps MCP calls to unified tool call and result events',
        () async {
      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSendStream: (request) async {
            expect(request.method, TransportMethod.post);

            return StreamingTransportResponse(
              statusCode: 200,
              stream: Stream.fromIterable([
                utf8.encode(
                  'data: {"type":"response.created","response":{"id":"resp_mcp","model":"gpt-4.1-mini","created_at":1710000000,"service_tier":"default"}}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"response.output_item.done","output_index":0,"item":{"id":"mcp-call-1","type":"mcp_call","approval_request_id":"approval-1","name":"create_short_url","arguments":"{\\"url\\":\\"https://ai-sdk.dev\\"}","server_label":"zip1","output":{"shortUrl":"https://zip1.dev/abc123"}}}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"response.completed","response":{"id":"resp_mcp","model":"gpt-4.1-mini","created_at":1710000000,"status":"completed","output":[],"usage":{"input_tokens":1,"output_tokens":1,"total_tokens":2,"output_tokens_details":{"reasoning_tokens":0}}}}\n\n',
                ),
              ]),
            );
          },
        ),
      ).chatModel('gpt-4.1-mini');

      final events = await model
          .stream(
            GenerateTextRequest(
              prompt: [
                UserPromptMessage.text('Continue after approval.'),
              ],
            ),
          )
          .toList();

      final toolCall = events.whereType<ToolCallEvent>().single.toolCall;
      expect(toolCall.toolCallId, 'approval-1');
      expect(toolCall.toolName, 'mcp.create_short_url');
      expect(toolCall.providerExecuted, isTrue);
      expect(toolCall.isDynamic, isTrue);

      final toolResult = events.whereType<ToolResultEvent>().single.toolResult;
      expect(toolResult.toolCallId, 'approval-1');
      expect(toolResult.toolName, 'mcp.create_short_url');
      expect(toolResult.isDynamic, isTrue);
      expect(toolResult.isError, isFalse);
      expect((toolResult.output as Map<String, Object?>)['type'], 'mcp_call');
      expect(
        ((toolResult.output as Map<String, Object?>)['output']
            as Map<String, Object?>)['shortUrl'],
        'https://zip1.dev/abc123',
      );
    });

    test('generate maps MCP approval requests to unified result content',
        () async {
      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'resp_approval',
                'model': 'gpt-4.1-mini',
                'created_at': 1710000000,
                'status': 'completed',
                'output': [
                  {
                    'id': 'approval-1',
                    'type': 'mcp_approval_request',
                    'name': 'create_short_url',
                    'arguments': '{"url":"https://ai-sdk.dev"}',
                    'server_label': 'zip1',
                  },
                ],
                'usage': {
                  'input_tokens': 1,
                  'output_tokens': 1,
                  'total_tokens': 2,
                  'output_tokens_details': {
                    'reasoning_tokens': 0,
                  },
                },
              },
            );
          },
        ),
      ).chatModel('gpt-4.1-mini');

      final result = await model.generate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Open the short URL tool.'),
          ],
        ),
      );

      expect(result.finishReason, FinishReason.toolCalls);
      expect(result.content, hasLength(2));

      final toolCall = result.content.whereType<ToolCallContentPart>().single;
      expect(toolCall.toolCall.toolCallId, 'approval-1');
      expect(toolCall.toolCall.toolName, 'mcp.create_short_url');
      expect(toolCall.toolCall.providerExecuted, isTrue);
      expect(toolCall.toolCall.isDynamic, isTrue);
      expect(toolCall.toolCall.title, 'zip1');
      expect(
        (toolCall.toolCall.input as Map<String, Object?>)['url'],
        'https://ai-sdk.dev',
      );

      final approval =
          result.content.whereType<ToolApprovalRequestContentPart>().single;
      expect(approval.approvalRequest.approvalId, 'approval-1');
      expect(approval.approvalRequest.toolCallId, 'approval-1');
    });

    test('generate maps MCP calls to unified tool call and tool result content',
        () async {
      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'resp_mcp',
                'model': 'gpt-4.1-mini',
                'created_at': 1710000000,
                'status': 'completed',
                'output': [
                  {
                    'id': 'mcp-call-1',
                    'type': 'mcp_call',
                    'approval_request_id': 'approval-1',
                    'name': 'create_short_url',
                    'arguments': '{"url":"https://ai-sdk.dev"}',
                    'server_label': 'zip1',
                    'output': {
                      'shortUrl': 'https://zip1.dev/abc123',
                    },
                  },
                ],
                'usage': {
                  'input_tokens': 1,
                  'output_tokens': 1,
                  'total_tokens': 2,
                  'output_tokens_details': {
                    'reasoning_tokens': 0,
                  },
                },
              },
            );
          },
        ),
      ).chatModel('gpt-4.1-mini');

      final result = await model.generate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Continue after approval.'),
          ],
        ),
      );

      expect(result.finishReason, FinishReason.toolCalls);
      expect(result.content, hasLength(2));

      final toolCall = result.content.whereType<ToolCallContentPart>().single;
      expect(toolCall.toolCall.toolCallId, 'approval-1');
      expect(toolCall.toolCall.toolName, 'mcp.create_short_url');
      expect(toolCall.toolCall.providerExecuted, isTrue);
      expect(toolCall.toolCall.isDynamic, isTrue);

      final toolResult =
          result.content.whereType<ToolResultContentPart>().single;
      expect(toolResult.toolResult.toolCallId, 'approval-1');
      expect(toolResult.toolResult.toolName, 'mcp.create_short_url');
      expect(toolResult.toolResult.isDynamic, isTrue);
      expect(toolResult.toolResult.isError, isFalse);
      expect(
        (toolResult.toolResult.output as Map<String, Object?>)['type'],
        'mcp_call',
      );
      expect(
        (((toolResult.toolResult.output as Map<String, Object?>)['output']
            as Map<String, Object?>)['shortUrl']),
        'https://zip1.dev/abc123',
      );
    });

    test(
        'generate encodes MCP approval continuations for Responses API and ignores unsupported approval reasons',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'resp_2',
                'status': 'completed',
                'output': [
                  {
                    'id': 'msg_2',
                    'type': 'message',
                    'status': 'completed',
                    'role': 'assistant',
                    'content': [
                      {
                        'type': 'output_text',
                        'text': 'Approved.',
                        'annotations': [],
                      },
                    ],
                  },
                ],
                'usage': {
                  'input_tokens': 4,
                  'output_tokens': 1,
                  'total_tokens': 5,
                  'output_tokens_details': {
                    'reasoning_tokens': 0,
                  },
                },
              },
            );
          },
        ),
      ).chatModel('gpt-4.1-mini');

      await model.generate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Approve the MCP tool.'),
            AssistantPromptMessage(
              parts: [
                const ToolCallPromptPart(
                  toolCallId: 'approval-1',
                  toolName: 'mcp.create_short_url',
                  input: {
                    'url': 'https://ai-sdk.dev',
                  },
                  providerExecuted: true,
                  isDynamic: true,
                ),
                const ToolApprovalRequestPromptPart(
                  approvalId: 'approval-1',
                  toolCallId: 'approval-1',
                ),
              ],
            ),
            ToolPromptMessage(
              toolName: 'mcp.create_short_url',
              parts: const [
                ToolApprovalResponsePromptPart(
                  approvalId: 'approval-1',
                  toolCallId: 'approval-1',
                  approved: true,
                  reason: 'User approved the MCP server action.',
                ),
              ],
            ),
          ],
          callOptions: const CallOptions(
            providerOptions: OpenAIGenerateTextOptions(
              previousResponseId: 'resp_prev',
            ),
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(requestBody['previous_response_id'], 'resp_prev');

      final input = requestBody['input'] as List<Object?>;
      expect(input, hasLength(2));
      expect((input[0] as Map<String, Object?>)['role'], 'user');
      expect(
        input[1],
        {
          'type': 'mcp_approval_response',
          'approval_request_id': 'approval-1',
          'approve': true,
        },
      );
      expect((input[1] as Map<String, Object?>).containsKey('reason'), isFalse);
    });
  });
}

typedef _FakeTransportClient = FakeTransportClient;
