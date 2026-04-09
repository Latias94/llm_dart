import 'dart:convert';

import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('AnthropicLanguageModel', () {
    test('generate maps a messages response to the unified result', () async {
      TransportRequest? capturedRequest;
      final cancelToken = TransportCancellation();

      final model = Anthropic(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'id': 'msg_1',
                'model': 'claude-sonnet-4-5',
                'content': [
                  {
                    'type': 'thinking',
                    'thinking': 'Plan first.',
                    'signature': 'sig_1',
                  },
                  {
                    'type': 'text',
                    'text': 'Hello from Anthropic.',
                    'citations': [],
                  },
                ],
                'stop_reason': 'end_turn',
                'stop_sequence': null,
                'usage': {
                  'input_tokens': 11,
                  'output_tokens': 7,
                },
              },
            );
          },
        ),
      ).chatModel(
        'claude-sonnet-4-5',
        settings: const AnthropicChatModelSettings(
          anthropicVersion: '2023-06-01',
          betaFeatures: ['tools-2024-04-04'],
          headers: {
            'anthropic-beta': 'message-batches-2024-09-24',
            'x-settings': '1',
          },
        ),
      );

      final result = await model.generate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Think carefully.'),
          ],
          tools: [
            FunctionToolDefinition(
              name: 'weather',
              description: 'Get weather details for a city.',
              inputSchema: ToolJsonSchema.object(
                properties: const {
                  'city': {
                    'type': 'string',
                  },
                },
                required: const ['city'],
              ),
            ),
          ],
          toolChoice: const AutoToolChoice(),
          options: const GenerateTextOptions(
            maxOutputTokens: 200,
          ),
          callOptions: CallOptions(
            timeout: const Duration(seconds: 5),
            headers: const {
              'anthropic-beta': 'prompt-caching-2024-07-31',
              'x-call': '2',
            },
            cancellation: cancelToken,
            providerOptions: const AnthropicGenerateTextOptions(
              extendedThinking: true,
              interleavedThinking: true,
              mcpServers: [
                AnthropicMcpServer.url(
                  name: 'workspace',
                  url: 'https://mcp.example.com',
                ),
              ],
              tools: [
                AnthropicCodeExecutionTool20260120(),
              ],
            ),
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.uri.toString(),
          'https://api.anthropic.com/v1/messages');
      expect(capturedRequest!.method, TransportMethod.post);
      expect(capturedRequest!.responseType, TransportResponseType.json);
      expect(capturedRequest!.timeout, const Duration(seconds: 5));
      expect(identical(capturedRequest!.cancellation, cancelToken), isTrue);
      expect(capturedRequest!.headers['x-api-key'], 'test-key');
      expect(capturedRequest!.headers['anthropic-version'], '2023-06-01');
      expect(capturedRequest!.headers['accept'], 'application/json');
      expect(capturedRequest!.headers['x-settings'], '1');
      expect(capturedRequest!.headers['x-call'], '2');
      expect(
        capturedRequest!.headers['anthropic-beta']!.split(',').toSet(),
        {
          'interleaved-thinking-2025-05-14',
          'mcp-client-2025-04-04',
          'message-batches-2024-09-24',
          'prompt-caching-2024-07-31',
          'tools-2024-04-04',
        },
      );

      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(requestBody['model'], 'claude-sonnet-4-5');
      expect(requestBody['stream'], isFalse);
      expect(requestBody['max_tokens'], 1224);
      expect(
        requestBody['thinking'],
        {
          'type': 'enabled',
          'budget_tokens': 1024,
        },
      );
      expect(
        requestBody['tools'],
        [
          {
            'name': 'weather',
            'description': 'Get weather details for a city.',
            'input_schema': {
              'type': 'object',
              'properties': {
                'city': {
                  'type': 'string',
                },
              },
              'required': ['city'],
            },
          },
          {
            'type': 'code_execution_20260120',
            'name': 'code_execution',
          },
        ],
      );
      expect(
        requestBody['tool_choice'],
        {
          'type': 'auto',
        },
      );

      expect(result.text, 'Hello from Anthropic.');
      expect(result.reasoningText, 'Plan first.');
      expect(result.finishReason, FinishReason.stop);
      expect(result.rawFinishReason, 'end_turn');
      expect(result.responseId, 'msg_1');
      expect(result.responseModelId, 'claude-sonnet-4-5');
      expect(result.usage?.totalTokens, 18);
      expect(
        result.providerMetadata?.values['anthropic'],
        containsPair(
          'usage',
          {
            'input_tokens': 11,
            'output_tokens': 7,
          },
        ),
      );
      expect(
        result.warnings.map((warning) => warning.field),
        contains('thinkingBudgetTokens'),
      );
    });

    test('countTokens sends a provider-owned token count request', () async {
      TransportRequest? capturedRequest;
      final cancellation = TransportCancellation();

      final model = Anthropic(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'input_tokens': 77,
              },
            );
          },
        ),
      ).chatModel(
        'claude-sonnet-4-5',
        settings: const AnthropicChatModelSettings(
          headers: {
            'anthropic-beta': 'settings-beta',
            'x-settings': '1',
          },
        ),
      );

      final result = await model.countTokens(
        AnthropicTokenCountRequest(
          prompt: [
            UserPromptMessage.text('Count this request.'),
          ],
          tools: [
            FunctionToolDefinition(
              name: 'weather',
              description: 'Get weather details for a city.',
              inputSchema: ToolJsonSchema.object(
                properties: const {
                  'city': {
                    'type': 'string',
                  },
                },
                required: const ['city'],
              ),
            ),
          ],
          toolChoice: const AutoToolChoice(),
          callOptions: CallOptions(
            timeout: const Duration(seconds: 6),
            cancellation: cancellation,
            headers: const {
              'anthropic-beta': 'runtime-beta',
              'x-call': '2',
            },
            providerOptions: const AnthropicGenerateTextOptions(
              extendedThinking: true,
              thinkingBudgetTokens: 2048,
              interleavedThinking: true,
              serviceTier: 'standard_only',
              metadata: {
                'session': 'abc',
              },
              container: 'container_123',
              mcpServers: [
                AnthropicMcpServer.url(
                  name: 'workspace',
                  url: 'https://mcp.example.com',
                ),
              ],
              tools: [
                AnthropicCodeExecutionTool20260120(),
              ],
              toolsCacheControl: AnthropicCacheControl.ephemeral(
                ttl: '1h',
              ),
            ),
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.uri.toString(),
        'https://api.anthropic.com/v1/messages/count_tokens',
      );
      expect(capturedRequest!.method, TransportMethod.post);
      expect(capturedRequest!.responseType, TransportResponseType.json);
      expect(capturedRequest!.timeout, const Duration(seconds: 6));
      expect(identical(capturedRequest!.cancellation, cancellation), isTrue);
      expect(capturedRequest!.headers['x-api-key'], 'test-key');
      expect(capturedRequest!.headers['anthropic-version'], '2023-06-01');
      expect(capturedRequest!.headers['accept'], 'application/json');
      expect(capturedRequest!.headers['content-type'], 'application/json');
      expect(capturedRequest!.headers['x-settings'], '1');
      expect(capturedRequest!.headers['x-call'], '2');
      expect(
        capturedRequest!.headers['anthropic-beta']!.split(',').toSet(),
        {
          'extended-cache-ttl-2025-04-11',
          'interleaved-thinking-2025-05-14',
          'mcp-client-2025-04-04',
          'runtime-beta',
          'settings-beta',
        },
      );

      final body = capturedRequest!.body as Map<String, Object?>;
      expect(body['model'], 'claude-sonnet-4-5');
      expect(body['messages'], [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': 'Count this request.',
            },
          ],
        },
      ]);
      expect(body['thinking'], {
        'type': 'enabled',
        'budget_tokens': 2048,
      });
      expect(body['mcp_servers'], [
        {
          'name': 'workspace',
          'type': 'url',
          'url': 'https://mcp.example.com',
        },
      ]);
      expect(body['tools'], [
        {
          'name': 'weather',
          'description': 'Get weather details for a city.',
          'input_schema': {
            'type': 'object',
            'properties': {
              'city': {
                'type': 'string',
              },
            },
            'required': ['city'],
          },
        },
        {
          'type': 'code_execution_20260120',
          'name': 'code_execution',
          'cache_control': {
            'type': 'ephemeral',
            'ttl': '1h',
          },
        },
      ]);
      expect(body['tool_choice'], {
        'type': 'auto',
      });
      expect(body.containsKey('max_tokens'), isFalse);
      expect(body.containsKey('stream'), isFalse);
      expect(body.containsKey('temperature'), isFalse);
      expect(body.containsKey('top_p'), isFalse);
      expect(body.containsKey('top_k'), isFalse);
      expect(body.containsKey('stop_sequences'), isFalse);
      expect(body.containsKey('service_tier'), isFalse);
      expect(body.containsKey('metadata'), isFalse);
      expect(body.containsKey('container'), isFalse);

      expect(result.inputTokens, 77);
      expect(
        result.warnings.map((warning) => warning.field),
        containsAll([
          'serviceTier',
          'metadata',
          'container',
        ]),
      );
    });

    test('stream maps SSE responses to unified stream events', () async {
      TransportRequest? capturedRequest;

      final model = Anthropic(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSendStream: (request) async {
            capturedRequest = request;

            return StreamingTransportResponse(
              statusCode: 200,
              stream: Stream.fromIterable([
                utf8.encode(
                  'event: message_start\n'
                  'data: {"type":"message_start","message":{"id":"msg_1","model":"claude-sonnet-4-5","usage":{"input_tokens":12,"output_tokens":0}}}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello"}}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"content_block_stop","index":0}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"content_block_start","index":1,"content_block":{"type":"tool_use","id":"toolu_1","name":"weather"}}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"{\\"city\\":\\"Hong Kong\\"}"}}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"content_block_stop","index":1}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"message_delta","delta":{"stop_reason":"tool_use"},"usage":{"input_tokens":12,"output_tokens":4}}\n\n',
                ),
                utf8.encode(
                  'data: {"type":"message_stop"}\n\n',
                ),
              ]),
            );
          },
        ),
      ).chatModel('claude-sonnet-4-5');

      final events = await model
          .stream(
            GenerateTextRequest(
              prompt: [
                UserPromptMessage.text('Call the weather tool.'),
              ],
            ),
          )
          .toList();

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.headers['accept'], 'text/event-stream');

      expect(events.first, isA<StartEvent>());
      expect((events.first as StartEvent).warnings, isEmpty);
      final responseMetadata = events.whereType<ResponseMetadataEvent>().single;
      expect(responseMetadata.responseId, 'msg_1');
      expect(responseMetadata.modelId, 'claude-sonnet-4-5');
      expect(events.whereType<TextStartEvent>().single.id, '0');
      expect(events.whereType<TextDeltaEvent>().single.delta, 'Hello');
      expect(events.whereType<TextEndEvent>().single.id, '0');
      expect(
          events.whereType<ToolInputStartEvent>().single.toolCallId, 'toolu_1');
      expect(events.whereType<ToolInputDeltaEvent>().single.delta,
          '{"city":"Hong Kong"}');

      final toolCall = events.whereType<ToolCallEvent>().single.toolCall;
      expect(toolCall.toolCallId, 'toolu_1');
      expect(toolCall.toolName, 'weather');
      expect(
        toolCall.input,
        {
          'city': 'Hong Kong',
        },
      );

      final finish = events.whereType<FinishEvent>().single;
      expect(finish.finishReason, FinishReason.toolCalls);
      expect(finish.usage?.totalTokens, 16);
    });

    test(
        'generate adds the extended cache TTL beta when prompt caching is used',
        () async {
      TransportRequest? capturedRequest;

      final model = Anthropic(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'id': 'msg_1',
                'model': 'claude-sonnet-4-5',
                'content': [
                  {
                    'type': 'text',
                    'text': 'Cached response.',
                  },
                ],
                'stop_reason': 'end_turn',
              },
            );
          },
        ),
      ).chatModel('claude-sonnet-4-5');

      await model.generate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage(
              parts: [
                TextPromptPart(
                  'Cache this prompt.',
                  providerMetadata: const ProviderMetadata({
                    'anthropic': {
                      'cacheControl': {
                        'type': 'ephemeral',
                        'ttl': '1h',
                      },
                    },
                  }),
                ),
              ],
            ),
          ],
          tools: [
            FunctionToolDefinition(
              name: 'weather',
              inputSchema: ToolJsonSchema.object(),
            ),
          ],
          toolChoice: const AutoToolChoice(),
          callOptions: const CallOptions(
            providerOptions: AnthropicGenerateTextOptions(
              toolsCacheControl: AnthropicCacheControl.ephemeral(
                ttl: '1h',
              ),
            ),
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.headers['anthropic-beta']!.split(','),
        contains('extended-cache-ttl-2025-04-11'),
      );
    });

    test('rejects provider options from a different provider', () async {
      final model = Anthropic(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).chatModel('claude-sonnet-4-5');

      expect(
        () => model.generate(
          GenerateTextRequest(
            prompt: [
              UserPromptMessage.text('Hello'),
            ],
            callOptions: const CallOptions(
              providerOptions: _InvalidProviderOptions(),
            ),
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

final class _InvalidProviderOptions implements ProviderInvocationOptions {
  const _InvalidProviderOptions();
}

typedef _FakeTransportClient = FakeTransportClient;
