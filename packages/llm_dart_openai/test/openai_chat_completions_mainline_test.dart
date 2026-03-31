import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI chat-completions mainline', () {
    test(
        'OpenAI can opt out of Responses API and uses chat completions request encoding',
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
                'id': 'chatcmpl_1',
                'model': 'gpt-4.1-mini',
                'created': 1710000000,
                'service_tier': 'flex',
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'tool_calls',
                    'message': {
                      'role': 'assistant',
                      'reasoning_content': 'Plan first.',
                      'content': 'Here is the answer.',
                      'tool_calls': [
                        {
                          'id': 'call_1',
                          'type': 'function',
                          'function': {
                            'name': 'weather',
                            'arguments': '{"city":"Shanghai"}',
                          },
                        },
                      ],
                    },
                  },
                ],
                'usage': {
                  'prompt_tokens': 10,
                  'completion_tokens': 5,
                  'total_tokens': 15,
                  'completion_tokens_details': {
                    'reasoning_tokens': 2,
                  },
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      final result = await model.generate(
        GenerateTextRequest(
          prompt: [
            SystemPromptMessage.text('Be concise.'),
            UserPromptMessage.text('Use the weather tool and answer in JSON.'),
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
              serviceTier: 'flex',
              verbosity: 'low',
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
      expect(capturedRequest!.uri.toString(), contains('/chat/completions'));

      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(requestBody['model'], 'gpt-4.1-mini');
      expect(requestBody['stream'], isFalse);
      expect(
        requestBody['messages'],
        [
          {
            'role': 'system',
            'content': 'Be concise.',
          },
          {
            'role': 'user',
            'content': 'Use the weather tool and answer in JSON.',
          },
        ],
      );
      expect(
        requestBody['tools'],
        [
          {
            'type': 'function',
            'function': {
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
      expect(requestBody['service_tier'], 'flex');
      expect(requestBody['verbosity'], 'low');
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

      expect(result.finishReason, FinishReason.toolCalls);
      expect(result.rawFinishReason, 'tool_calls');
      expect(result.text, 'Here is the answer.');
      expect(result.reasoningText, 'Plan first.');
      expect(result.usage?.reasoningTokens, 2);

      final toolCall = result.content.whereType<ToolCallContentPart>().single;
      expect(toolCall.toolCall.toolCallId, 'call_1');
      expect(toolCall.toolCall.toolName, 'weather');
      expect(
        toolCall.toolCall.input,
        {
          'city': 'Shanghai',
        },
      );
    });

    test(
        'chat completions encode PDF file prompt parts with a default filename',
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
                'id': 'chatcmpl_pdf_1',
                'model': 'gpt-4.1-mini',
                'created': 1710000000,
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'stop',
                    'message': {
                      'role': 'assistant',
                      'content': 'Done.',
                    },
                  },
                ],
                'usage': {
                  'prompt_tokens': 4,
                  'completion_tokens': 1,
                  'total_tokens': 5,
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      await model.generate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage(
              parts: const [
                TextPromptPart('Summarize this document.'),
                FilePromptPart(
                  mediaType: 'application/pdf',
                  bytes: [1, 2, 3, 4, 5],
                ),
              ],
            ),
          ],
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['messages'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'Summarize this document.',
              },
              {
                'type': 'file',
                'file': {
                  'filename': 'part-1.pdf',
                  'file_data': 'data:application/pdf;base64,AQIDBAU=',
                },
              },
            ],
          },
        ],
      );
    });

    test(
        'chat completions encode OpenAI-owned PDF file handles through provider metadata',
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
                'id': 'chatcmpl_pdf_file_id_1',
                'model': 'gpt-4.1-mini',
                'created': 1710000000,
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'stop',
                    'message': {
                      'role': 'assistant',
                      'content': 'Done.',
                    },
                  },
                ],
                'usage': {
                  'prompt_tokens': 4,
                  'completion_tokens': 1,
                  'total_tokens': 5,
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      await model.generate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage(
              parts: const [
                FilePromptPart(
                  mediaType: 'application/pdf',
                  providerMetadata: ProviderMetadata({
                    'openai': {
                      'fileId': 'file-pdf-12345',
                    },
                  }),
                ),
              ],
            ),
          ],
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['messages'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'file',
                'file': {
                  'file_id': 'file-pdf-12345',
                },
              },
            ],
          },
        ],
      );
    });

    test(
        'chat completions encode OpenAI image detail through provider metadata',
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
                'id': 'chatcmpl_image_detail_1',
                'model': 'gpt-4.1-mini',
                'created': 1710000000,
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'stop',
                    'message': {
                      'role': 'assistant',
                      'content': 'Done.',
                    },
                  },
                ],
                'usage': {
                  'prompt_tokens': 4,
                  'completion_tokens': 1,
                  'total_tokens': 5,
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      await model.generate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage(
              parts: const [
                ImagePromptPart(
                  mediaType: 'image/png',
                  bytes: [0, 1, 2, 3],
                  providerMetadata: ProviderMetadata({
                    'openai': {
                      'imageDetail': 'low',
                    },
                  }),
                ),
              ],
            ),
          ],
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['messages'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/png;base64,AAECAw==',
                  'detail': 'low',
                },
              },
            ],
          },
        ],
      );
    });

    test('chat completions encode audio file prompt parts', () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_audio_1',
                'model': 'gpt-4.1-mini',
                'created': 1710000000,
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'stop',
                    'message': {
                      'role': 'assistant',
                      'content': 'Done.',
                    },
                  },
                ],
                'usage': {
                  'prompt_tokens': 4,
                  'completion_tokens': 1,
                  'total_tokens': 5,
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      await model.generate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage(
              parts: const [
                FilePromptPart(
                  mediaType: 'audio/mpeg',
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
        requestBody['messages'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_audio',
                'input_audio': {
                  'data': 'AQIDBA==',
                  'format': 'mp3',
                },
              },
            ],
          },
        ],
      );
    });

    test('chat completions encode image file prompt parts as image_url',
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
                'id': 'chatcmpl_image_1',
                'model': 'gpt-4.1-mini',
                'created': 1710000000,
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'stop',
                    'message': {
                      'role': 'assistant',
                      'content': 'Done.',
                    },
                  },
                ],
                'usage': {
                  'prompt_tokens': 4,
                  'completion_tokens': 1,
                  'total_tokens': 5,
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      await model.generate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage(
              parts: const [
                FilePromptPart(
                  mediaType: 'image/png',
                  bytes: [0, 1, 2, 3],
                ),
              ],
            ),
          ],
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['messages'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/png;base64,AAECAw==',
                },
              },
            ],
          },
        ],
      );
    });

    test('chat completions reject unsupported file media types before send',
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
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      await expectLater(
        model.generate(
          GenerateTextRequest(
            prompt: [
              UserPromptMessage(
                parts: const [
                  FilePromptPart(
                    mediaType: 'text/plain',
                    bytes: [1, 2, 3],
                  ),
                ],
              ),
            ],
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            contains('file prompt media type text/plain'),
          ),
        ),
      );

      expect(sendCount, 0);
    });

    test('chat completions reject PDF file URIs before send', () async {
      var sendCount = 0;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            sendCount += 1;
            return TransportResponse(statusCode: 200, body: const {});
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      await expectLater(
        model.generate(
          GenerateTextRequest(
            prompt: [
              UserPromptMessage(
                parts: [
                  FilePromptPart(
                    mediaType: 'application/pdf',
                    uri: Uri.parse('https://example.com/document.pdf'),
                  ),
                ],
              ),
            ],
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            contains('PDF file prompt parts do not support URIs'),
          ),
        ),
      );

      expect(sendCount, 0);
    });

    test('chat completions stream maps reasoning, text, and tool-call deltas',
        () async {
      final model = OpenAI(
        apiKey: 'test-key',
        profile: const DeepSeekProfile(),
        transport: _FakeTransportClient(
          onSendStream: (request) async {
            expect(request.uri.toString(), contains('/chat/completions'));

            return StreamingTransportResponse(
              statusCode: 200,
              stream: Stream.fromIterable([
                utf8.encode(
                  'data: {"id":"chatcmpl_1","object":"chat.completion.chunk","created":1710000000,"model":"deepseek-reasoner","choices":[{"index":0,"delta":{"role":"assistant","reasoning_content":"Plan"},"finish_reason":null}]}\n\n',
                ),
                utf8.encode(
                  'data: {"id":"chatcmpl_1","object":"chat.completion.chunk","created":1710000000,"model":"deepseek-reasoner","choices":[{"index":0,"delta":{"content":"Hello"},"finish_reason":null}]}\n\n',
                ),
                utf8.encode(
                  'data: {"id":"chatcmpl_1","object":"chat.completion.chunk","created":1710000000,"model":"deepseek-reasoner","choices":[{"index":0,"delta":{"tool_calls":[{"index":0,"id":"call_1","type":"function","function":{"name":"weather","arguments":"{\\"city\\":\\"Sh"}}]},"finish_reason":null}]}\n\n',
                ),
                utf8.encode(
                  'data: {"id":"chatcmpl_1","object":"chat.completion.chunk","created":1710000000,"model":"deepseek-reasoner","choices":[{"index":0,"delta":{"tool_calls":[{"index":0,"function":{"arguments":"anghai\\"}"}}]},"finish_reason":null}]}\n\n',
                ),
                utf8.encode(
                  'data: {"id":"chatcmpl_1","object":"chat.completion.chunk","created":1710000000,"model":"deepseek-reasoner","system_fingerprint":"fp_1","choices":[{"index":0,"delta":{},"finish_reason":"tool_calls"}],"usage":{"prompt_tokens":12,"completion_tokens":8,"total_tokens":20,"completion_tokens_details":{"reasoning_tokens":3}}}\n\n',
                ),
                utf8.encode('data: [DONE]\n\n'),
              ]),
            );
          },
        ),
      ).chatModel('deepseek-reasoner');

      final events = await model
          .stream(
            GenerateTextRequest(
              prompt: [
                UserPromptMessage.text('Think and call the weather tool.'),
              ],
            ),
          )
          .toList();

      expect(events.first, isA<StartEvent>());

      final responseMetadata = events.whereType<ResponseMetadataEvent>().single;
      expect(responseMetadata.responseId, 'chatcmpl_1');
      expect(responseMetadata.modelId, 'deepseek-reasoner');
      expect(
        responseMetadata.providerMetadata?['deepseek'],
        containsPair('responseId', 'chatcmpl_1'),
      );

      expect(events.whereType<ReasoningStartEvent>().single.id, 'reasoning_0');
      expect(events.whereType<ReasoningDeltaEvent>().single.delta, 'Plan');
      expect(events.whereType<ReasoningEndEvent>().single.id, 'reasoning_0');

      expect(events.whereType<TextStartEvent>().single.id, 'text_0');
      expect(events.whereType<TextDeltaEvent>().single.delta, 'Hello');
      expect(events.whereType<TextEndEvent>().single.id, 'text_0');

      final toolInputStart = events.whereType<ToolInputStartEvent>().single;
      expect(toolInputStart.toolCallId, 'call_1');
      expect(toolInputStart.toolName, 'weather');

      final toolInputDeltas =
          events.whereType<ToolInputDeltaEvent>().map((event) => event.delta);
      expect(toolInputDeltas, ['{"city":"Sh', 'anghai"}']);

      expect(events.whereType<ToolInputEndEvent>().single.toolCallId, 'call_1');

      final toolCall = events.whereType<ToolCallEvent>().single.toolCall;
      expect(toolCall.toolCallId, 'call_1');
      expect(toolCall.toolName, 'weather');
      expect(
        toolCall.input,
        {
          'city': 'Shanghai',
        },
      );

      final finish = events.whereType<FinishEvent>().single;
      expect(finish.finishReason, FinishReason.toolCalls);
      expect(finish.rawFinishReason, 'tool_calls');
      expect(finish.usage?.reasoningTokens, 3);
      expect(finish.usage?.totalTokens, 20);
      expect(
        finish.providerMetadata?['deepseek'],
        allOf(
          containsPair('responseId', 'chatcmpl_1'),
          containsPair('systemFingerprint', 'fp_1'),
        ),
      );
    });

    test(
        'chat completions mainline rejects Responses-only provider options before sending',
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
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      await expectLater(
        model.generate(
          GenerateTextRequest(
            prompt: [
              UserPromptMessage.text('hello'),
            ],
            callOptions: const CallOptions(
              providerOptions: OpenAIGenerateTextOptions(
                previousResponseId: 'resp_prev',
              ),
            ),
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            contains('previousResponseId'),
          ),
        ),
      );

      await expectLater(
        model.generate(
          GenerateTextRequest(
            prompt: [
              UserPromptMessage.text('hello'),
            ],
            callOptions: const CallOptions(
              providerOptions: OpenAIGenerateTextOptions(
                builtInTools: [
                  OpenAIWebSearchTool(),
                ],
              ),
            ),
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            contains('built-in tools'),
          ),
        ),
      );

      expect(sendCount, 0);
    });

    test(
        'chat completions replay drops provider-native approval continuation with warnings',
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
                'id': 'chatcmpl_approval_1',
                'model': 'gpt-4.1-mini',
                'created': 1710000100,
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'stop',
                    'message': {
                      'role': 'assistant',
                      'content': 'Fallback answer.',
                    },
                  },
                ],
                'usage': {
                  'prompt_tokens': 4,
                  'completion_tokens': 2,
                  'total_tokens': 6,
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      final result = await model.generate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Continue after approval.'),
            AssistantPromptMessage(
              parts: const [
                ToolCallPromptPart(
                  toolCallId: 'approval-1',
                  toolName: 'mcp.create_short_url',
                  input: {
                    'url': 'https://ai-sdk.dev',
                  },
                  providerExecuted: true,
                  isDynamic: true,
                ),
                ToolApprovalRequestPromptPart(
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
                  reason: 'User approved the MCP action.',
                ),
                ToolResultPromptPart(
                  toolCallId: 'approval-1',
                  toolName: 'mcp.create_short_url',
                  output: {
                    'shortUrl': 'https://zip1.dev/abc123',
                  },
                ),
              ],
            ),
          ],
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['messages'],
        [
          {
            'role': 'user',
            'content': 'Continue after approval.',
          },
        ],
      );

      expect(result.text, 'Fallback answer.');
      expect(
        result.warnings.map((warning) => warning.message),
        containsAll([
          'Chat-completions replay drops provider-executed or dynamic assistant tool calls.',
          'Chat-completions replay does not support tool approval responses.',
          'Chat-completions replay drops provider-native MCP tool results.',
        ]),
      );
      expect(
        result.warnings
            .where((warning) => warning.field == 'prompt.assistant.parts'),
        isNotEmpty,
      );
      expect(
        result.warnings
            .where((warning) => warning.field == 'prompt.tool.parts'),
        isNotEmpty,
      );
    });

    test(
        'chat completions replay keeps assistant text and common tool calls while warning-dropping unsupported assistant parts',
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
                'id': 'chatcmpl_assistant_replay_1',
                'model': 'gpt-4.1-mini',
                'created': 1710000101,
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'stop',
                    'message': {
                      'role': 'assistant',
                      'content': 'Replay accepted.',
                    },
                  },
                ],
                'usage': {
                  'prompt_tokens': 4,
                  'completion_tokens': 2,
                  'total_tokens': 6,
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      final result = await model.generate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Continue the conversation.'),
            AssistantPromptMessage(
              parts: const [
                TextPromptPart('I will continue.'),
                ToolCallPromptPart(
                  toolCallId: 'call_1',
                  toolName: 'weather',
                  input: {
                    'city': 'Hong Kong',
                  },
                ),
                ReasoningPromptPart('private reasoning'),
                CustomPromptPart(
                  kind: 'openai.custom_note',
                  data: {'state': 'hidden'},
                ),
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
        requestBody['messages'],
        [
          {
            'role': 'user',
            'content': 'Continue the conversation.',
          },
          {
            'role': 'assistant',
            'content': 'I will continue.',
            'tool_calls': [
              {
                'id': 'call_1',
                'type': 'function',
                'function': {
                  'name': 'weather',
                  'arguments': '{"city":"Hong Kong"}',
                },
              },
            ],
          },
        ],
      );

      expect(result.text, 'Replay accepted.');
      expect(
        result.warnings.map((warning) => warning.message),
        containsAll([
          'Chat-completions replay dropped unsupported assistant part: ReasoningPromptPart.',
          'Chat-completions replay dropped unsupported assistant part: CustomPromptPart.',
          'Chat-completions replay dropped unsupported assistant part: ImagePromptPart.',
          'Chat-completions replay dropped unsupported assistant part: FilePromptPart.',
        ]),
      );
    });

    test(
        'xAI chat completions encode typed live-search options and decode citations',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        profile: const XAIProfile(),
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_xai_1',
                'model': 'grok-3',
                'created': 1710000200,
                'citations': [
                  'https://example.com/news',
                  'https://x.ai/blog',
                ],
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'stop',
                    'message': {
                      'role': 'assistant',
                      'content': 'Here is the summary.',
                    },
                  },
                ],
                'usage': {
                  'prompt_tokens': 9,
                  'completion_tokens': 6,
                  'total_tokens': 15,
                  'completion_tokens_details': {
                    'reasoning_tokens': 0,
                  },
                },
              },
            );
          },
        ),
      ).chatModel('grok-3');

      final result = await model.generate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Search the latest xAI news.'),
          ],
          callOptions: CallOptions(
            providerOptions: XAIGenerateTextOptions(
              search: XAILiveSearchOptions(
                mode: XAISearchMode.on,
                maxSearchResults: 7,
                fromDate: DateTime.utc(2026, 3, 1),
                toDate: DateTime.utc(2026, 3, 30),
                sources: const [
                  XAIWebSearchSource(
                    countryCode: 'US',
                    excludedWebsites: ['spam.example'],
                  ),
                  XAINewsSearchSource(countryCode: 'US'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['search_parameters'],
        {
          'mode': 'on',
          'return_citations': true,
          'from_date': '2026-03-01',
          'to_date': '2026-03-30',
          'max_search_results': 7,
          'sources': [
            {
              'type': 'web',
              'country': 'US',
              'excluded_websites': ['spam.example'],
            },
            {
              'type': 'news',
              'country': 'US',
            },
          ],
        },
      );

      final sources = result.content.whereType<SourceContentPart>().toList();
      expect(sources, hasLength(2));
      expect(sources[0].source.sourceId, 'https://example.com/news');
      expect(sources[0].source.kind, SourceReferenceKind.url);
      expect(
        sources[0].source.providerMetadata?['xai'],
        containsPair('citationIndex', 0),
      );
      expect(sources[1].source.sourceId, 'https://x.ai/blog');
      expect(result.text, 'Here is the summary.');
    });

    test('xAI chat completions stream emits source events from citations',
        () async {
      final model = OpenAI(
        apiKey: 'test-key',
        profile: const XAIProfile(),
        transport: _FakeTransportClient(
          onSendStream: (request) async {
            expect(request.uri.toString(), contains('/chat/completions'));

            return StreamingTransportResponse(
              statusCode: 200,
              stream: Stream.fromIterable([
                utf8.encode(
                  'data: {"id":"chatcmpl_xai_stream_1","object":"chat.completion.chunk","created":1710000200,"model":"grok-3","choices":[{"index":0,"delta":{"content":"Latest summary"},"finish_reason":null}]}\n\n',
                ),
                utf8.encode(
                  'data: {"id":"chatcmpl_xai_stream_1","object":"chat.completion.chunk","created":1710000200,"model":"grok-3","citations":["https://example.com/news"],"choices":[{"index":0,"delta":{},"finish_reason":"stop"}],"usage":{"prompt_tokens":4,"completion_tokens":3,"total_tokens":7,"completion_tokens_details":{"reasoning_tokens":0}}}\n\n',
                ),
                utf8.encode('data: [DONE]\n\n'),
              ]),
            );
          },
        ),
      ).chatModel('grok-3');

      final events = await model
          .stream(
            GenerateTextRequest(
              prompt: [
                UserPromptMessage.text('Search the latest news.'),
              ],
              callOptions: const CallOptions(
                providerOptions: XAIGenerateTextOptions(
                  search: XAILiveSearchOptions.autoWeb(),
                ),
              ),
            ),
          )
          .toList();

      final sourceEvent = events.whereType<SourceEvent>().single;
      expect(sourceEvent.source.sourceId, 'https://example.com/news');
      expect(sourceEvent.source.kind, SourceReferenceKind.url);
      expect(
        sourceEvent.source.providerMetadata?['xai'],
        allOf(
          containsPair('responseId', 'chatcmpl_xai_stream_1'),
          containsPair('citationIndex', 0),
        ),
      );

      final finish = events.whereType<FinishEvent>().single;
      expect(finish.finishReason, FinishReason.stop);
      expect(finish.usage?.totalTokens, 7);
    });

    test('xAI typed provider options are rejected on non-xAI profiles',
        () async {
      var sendCount = 0;

      final model = OpenAI(
        apiKey: 'test-key',
        profile: const OpenRouterProfile(),
        transport: _FakeTransportClient(
          onSend: (request) async {
            sendCount += 1;
            return TransportResponse(statusCode: 200, body: const {});
          },
        ),
      ).chatModel('openai/gpt-4o-mini');

      await expectLater(
        model.generate(
          GenerateTextRequest(
            prompt: [
              UserPromptMessage.text('hello'),
            ],
            callOptions: const CallOptions(
              providerOptions: XAIGenerateTextOptions(
                search: XAILiveSearchOptions.autoWeb(),
              ),
            ),
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('only valid for xAI'),
          ),
        ),
      );

      expect(sendCount, 0);
    });
  });
}

typedef _FakeTransportClient = FakeTransportClient;
