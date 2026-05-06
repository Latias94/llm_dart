import 'dart:convert';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_community/llm_dart_community.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('OllamaLanguageModel', () {
    test('Ollama factory exposes an Ollama language model', () {
      final model = Ollama(
        transport: const _FakeTransportClient(),
      ).chatModel('llama3.2');

      expect(model.providerId, 'ollama');
      expect(model.baseUrl, Ollama.defaultBaseUrl);
    });

    test('generate encodes prompt, tools, and response format', () async {
      TransportRequest? capturedRequest;

      final model = Ollama(
        apiKey: 'test-key',
        baseUrl: 'http://localhost:11434/',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'model': 'llama3.2',
                'created_at': '2026-04-08T10:00:00Z',
                'done': true,
                'done_reason': 'stop',
                'message': {
                  'content': 'Sunny',
                  'thinking': 'Need weather data',
                  'tool_calls': [
                    {
                      'function': {
                        'name': 'weather',
                        'arguments': {
                          'city': 'Shanghai',
                        },
                      },
                    },
                  ],
                },
                'prompt_eval_count': 7,
                'eval_count': 3,
                'total_duration': 123,
              },
            );
          },
        ),
      ).chatModel(
        'llama3.2',
        settings: const OllamaChatModelSettings(
          headers: {
            'x-settings': '1',
          },
        ),
      );

      final result = await generateText(
        model: model,
        prompt: [
          SystemPromptMessage.text('You are helpful.'),
          UserPromptMessage.text('What is the weather?'),
          AssistantPromptMessage(
            parts: [
              ReasoningPromptPart('Need weather data'),
              ToolCallPromptPart(
                toolCallId: 'tool-1',
                toolName: 'weather',
                input: {
                  'city': 'Shanghai',
                },
              ),
            ],
          ),
          ToolPromptMessage(
            toolName: 'weather',
            parts: [
              ToolResultPromptPart(
                toolCallId: 'tool-1',
                toolName: 'weather',
                output: {
                  'tempC': 20,
                },
              ),
            ],
          ),
        ],
        tools: [
          FunctionToolDefinition(
            name: 'weather',
            description: 'Look up weather.',
            inputSchema: ToolJsonSchema.raw({
              'type': 'object',
              'properties': {
                'city': {
                  'type': 'string',
                },
              },
              'required': ['city'],
            }),
          ),
        ],
        toolChoice: const SpecificToolChoice('weather'),
        options: GenerateTextOptions(
          temperature: 0.2,
          maxOutputTokens: 128,
          topP: 0.8,
          topK: 32,
          stopSequences: const ['STOP'],
          responseFormat: JsonResponseFormat(
            schema: JsonSchema.object(
              properties: {
                'answer': {
                  'type': 'string',
                },
              },
              required: ['answer'],
            ),
            name: 'answer',
            strict: true,
          ),
        ),
        callOptions: const CallOptions(
          headers: {
            'x-call': '2',
          },
          providerOptions: OllamaGenerateTextOptions(
            numCtx: 4096,
            keepAlive: '10m',
            reasoning: true,
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.uri.toString(),
        'http://localhost:11434/api/chat',
      );
      expect(capturedRequest!.headers, {
        'content-type': 'application/json',
        'accept': 'application/json',
        'authorization': 'Bearer test-key',
        'x-settings': '1',
        'x-call': '2',
      });
      expect(
        capturedRequest!.body,
        {
          'model': 'llama3.2',
          'messages': [
            {
              'role': 'system',
              'content': 'You are helpful.',
            },
            {
              'role': 'user',
              'content': 'What is the weather?',
            },
            {
              'role': 'assistant',
              'content': '',
              'thinking': 'Need weather data',
              'tool_calls': [
                {
                  'type': 'function',
                  'function': {
                    'index': 0,
                    'name': 'weather',
                    'arguments': {
                      'city': 'Shanghai',
                    },
                  },
                },
              ],
            },
            {
              'role': 'tool',
              'tool_name': 'weather',
              'content': '{"tempC":20}',
            },
          ],
          'stream': false,
          'options': {
            'temperature': 0.2,
            'top_p': 0.8,
            'top_k': 32,
            'num_predict': 128,
            'stop': ['STOP'],
            'num_ctx': 4096,
          },
          'format': {
            'type': 'object',
            'properties': {
              'answer': {
                'type': 'string',
              },
            },
            'required': ['answer'],
          },
          'tools': [
            {
              'type': 'function',
              'function': {
                'name': 'weather',
                'description': 'Look up weather.',
                'parameters': {
                  'type': 'object',
                  'properties': {
                    'city': {
                      'type': 'string',
                    },
                  },
                  'required': ['city'],
                },
              },
            },
          ],
          'keep_alive': '10m',
          'think': true,
        },
      );
      expect(result.text, 'Sunny');
      expect(result.reasoningText, 'Need weather data');
      expect(result.finishReason, FinishReason.toolCalls);
      expect(result.responseModelId, 'llama3.2');
      expect(
        result.responseTimestamp,
        DateTime.parse('2026-04-08T10:00:00Z'),
      );
      expect(
        result.usage,
        const UsageStats(
          inputTokens: 7,
          outputTokens: 3,
          totalTokens: 10,
        ),
      );
      expect(result.warnings, hasLength(2));
      expect(
        result.warnings.map((warning) => warning.field),
        containsAll([
          'toolChoice',
          'options.responseFormat',
        ]),
      );
      final toolCallPart =
          result.content.whereType<ToolCallContentPart>().single;
      expect(toolCallPart.toolCall.toolName, 'weather');
      expect(toolCallPart.toolCall.input, {
        'city': 'Shanghai',
      });
      expect(
        result.providerMetadata?.values['ollama'],
        {
          'createdAt': '2026-04-08T10:00:00Z',
          'doneReason': 'stop',
          'totalDurationNanos': 123,
        },
      );
    });

    test('generate warns when replaying tool errors as plain tool content',
        () async {
      TransportRequest? capturedRequest;

      final model = Ollama(
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'model': 'llama3.2',
                'done': true,
                'message': {
                  'content': 'Handled',
                },
              },
            );
          },
        ),
      ).chatModel('llama3.2');

      final result = await generateText(
        model: model,
        prompt: [
          UserPromptMessage.text('Handle the failed tool result.'),
          ToolPromptMessage(
            toolName: 'weather',
            parts: [
              ToolResultPromptPart(
                toolCallId: 'tool-1',
                toolName: 'weather',
                output: {
                  'error': 'timeout',
                },
                isError: true,
              ),
            ],
          ),
        ],
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.body,
        {
          'model': 'llama3.2',
          'messages': [
            {
              'role': 'user',
              'content': 'Handle the failed tool result.',
            },
            {
              'role': 'tool',
              'tool_name': 'weather',
              'content': '{"error":"timeout"}',
            },
          ],
          'stream': false,
        },
      );
      expect(
        result.warnings,
        const [
          ModelWarning(
            type: ModelWarningType.compatibility,
            field: 'prompt',
            message:
                'Ollama does not support replaying tool error state separately. The tool result has been sent as a plain tool content message.',
          ),
        ],
      );
    });

    test('stream emits reasoning, text, tool call, and finish events',
        () async {
      final model = Ollama(
        transport: _FakeTransportClient(
          onSendStream: (request) async {
            final lines = [
              jsonEncode({
                'model': 'llama3.2',
                'created_at': '2026-04-08T10:00:00Z',
                'done': false,
                'message': {
                  'thinking': 'Need weather data',
                  'content': 'Sunny',
                },
              }),
              jsonEncode({
                'model': 'llama3.2',
                'created_at': '2026-04-08T10:00:01Z',
                'done': true,
                'done_reason': 'stop',
                'message': {
                  'tool_calls': [
                    {
                      'function': {
                        'name': 'weather',
                        'arguments': {
                          'city': 'Shanghai',
                        },
                      },
                    },
                  ],
                },
                'prompt_eval_count': 7,
                'eval_count': 3,
              }),
            ].join('\n');

            return StreamingTransportResponse(
              statusCode: 200,
              stream: Stream.value(utf8.encode(lines)),
            );
          },
        ),
      ).chatModel('llama3.2');

      final events = await streamText(
        model: model,
        prompt: [
          UserPromptMessage.text('What is the weather?'),
        ],
      ).toList();

      expect(events[0], isA<StartEvent>());
      expect(events[1], isA<ResponseMetadataEvent>());
      expect(events[2], isA<ReasoningStartEvent>());
      expect(events[3], isA<ReasoningDeltaEvent>());
      expect(events[4], isA<TextStartEvent>());
      expect(events[5], isA<TextDeltaEvent>());
      expect(events[6], isA<ToolCallEvent>());
      expect(events[7], isA<ReasoningEndEvent>());
      expect(events[8], isA<TextEndEvent>());
      expect(events[9], isA<FinishEvent>());

      final toolCall = (events[6] as ToolCallEvent).toolCall;
      expect(toolCall.toolName, 'weather');
      expect(toolCall.input, {
        'city': 'Shanghai',
      });

      final finish = events[9] as FinishEvent;
      expect(finish.finishReason, FinishReason.toolCalls);
      expect(
        finish.usage,
        const UsageStats(
          inputTokens: 7,
          outputTokens: 3,
          totalTokens: 10,
        ),
      );
    });

    test('language model rejects incompatible provider options', () async {
      final model = Ollama(
        transport: const _FakeTransportClient(),
      ).chatModel('llama3.2');

      await expectLater(
        () => generateText(
          model: model,
          prompt: [
            UserPromptMessage.text('hello'),
          ],
          callOptions: const CallOptions(
            providerOptions: _BadProviderOptions(),
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('Expected OllamaGenerateTextOptions'),
          ),
        ),
      );
    });

    test(
        'generate resolves URI-backed image prompt parts through binaryResolver',
        () async {
      TransportRequest? capturedRequest;

      final model = Ollama(
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'model': 'llama3.2',
                'done': true,
                'message': {
                  'content': 'Handled image',
                },
              },
            );
          },
        ),
      ).chatModel(
        'llama3.2',
        settings: OllamaChatModelSettings(
          binaryResolver: (uri, {required mediaType, filename}) {
            expect(uri.toString(), 'https://example.com/cat.png');
            expect(mediaType, 'image/png');
            expect(filename, isNull);
            return utf8.encode('image-bytes');
          },
        ),
      );

      final result = await generateText(
        model: model,
        prompt: [
          UserPromptMessage(
            parts: [
              const TextPromptPart('Describe this image'),
              ImagePromptPart(
                mediaType: 'image/png',
                data: FileUrlData(Uri.parse('https://example.com/cat.png')),
              ),
            ],
          ),
        ],
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.body,
        {
          'model': 'llama3.2',
          'messages': [
            {
              'role': 'user',
              'content': 'Describe this image',
              'images': [base64Encode(utf8.encode('image-bytes'))],
            },
          ],
          'stream': false,
        },
      );
      expect(result.text, 'Handled image');
    });

    test('generate decodes data URI image prompt parts without binaryResolver',
        () async {
      TransportRequest? capturedRequest;
      final dataUri = Uri.dataFromBytes(
        utf8.encode('data-image'),
        mimeType: 'image/png',
      );

      final model = Ollama(
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'model': 'llama3.2',
                'done': true,
                'message': {
                  'content': 'Handled data uri',
                },
              },
            );
          },
        ),
      ).chatModel('llama3.2');

      final result = await generateText(
        model: model,
        prompt: [
          UserPromptMessage(
            parts: [
              ImagePromptPart(
                mediaType: 'image/png',
                data: FileUrlData(dataUri),
              ),
            ],
          ),
        ],
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.body,
        {
          'model': 'llama3.2',
          'messages': [
            {
              'role': 'user',
              'content': '',
              'images': [base64Encode(utf8.encode('data-image'))],
            },
          ],
          'stream': false,
        },
      );
      expect(result.text, 'Handled data uri');
    });

    test('call-level binaryResolver overrides model settings', () async {
      TransportRequest? capturedRequest;

      final model = Ollama(
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'model': 'llama3.2',
                'done': true,
                'message': {
                  'content': 'Handled override',
                },
              },
            );
          },
        ),
      ).chatModel(
        'llama3.2',
        settings: OllamaChatModelSettings(
          binaryResolver: (uri, {required mediaType, filename}) {
            return utf8.encode('model-bytes');
          },
        ),
      );

      final result = await generateText(
        model: model,
        prompt: [
          UserPromptMessage(
            parts: [
              ImagePromptPart(
                mediaType: 'image/png',
                data: FileUrlData(Uri.parse('https://example.com/call.png')),
              ),
            ],
          ),
        ],
        callOptions: CallOptions(
          providerOptions: OllamaGenerateTextOptions(
            binaryResolver: (uri, {required mediaType, filename}) {
              return utf8.encode('call-bytes');
            },
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.body,
        {
          'model': 'llama3.2',
          'messages': [
            {
              'role': 'user',
              'content': '',
              'images': [base64Encode(utf8.encode('call-bytes'))],
            },
          ],
          'stream': false,
        },
      );
      expect(result.text, 'Handled override');
    });

    test('generate throws a helpful error for unresolved URI-backed images',
        () async {
      final model = Ollama(
        transport: const _FakeTransportClient(),
      ).chatModel('llama3.2');

      await expectLater(
        () => generateText(
          model: model,
          prompt: [
            UserPromptMessage(
              parts: [
                ImagePromptPart(
                  mediaType: 'image/png',
                  data: FileUrlData(Uri.parse('https://example.com/cat.png')),
                ),
              ],
            ),
          ],
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            contains('OllamaBinaryResolver'),
          ),
        ),
      );
    });
  });
}

typedef _FakeTransportClient = FakeTransportClient;

final class _BadProviderOptions implements ProviderInvocationOptions {
  const _BadProviderOptions();
}
