import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('GoogleLanguageModel', () {
    test(
        'generate keeps Google native tools exclusive and surfaces mixed-tool warnings for Gemini 3',
        () async {
      TransportRequest? capturedRequest;
      final cancelToken = ProviderCancellation();

      final model = Google(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'responseId': 'resp_1',
                'modelVersion': 'gemini-3-pro-preview',
                'candidates': [
                  {
                    'content': {
                      'parts': [
                        {
                          'text': 'Plan first.',
                          'thought': true,
                        },
                        {
                          'text': 'Hello from Google.',
                        },
                      ],
                    },
                    'finishReason': 'STOP',
                  },
                ],
                'usageMetadata': {
                  'promptTokenCount': 10,
                  'candidatesTokenCount': 3,
                  'thoughtsTokenCount': 5,
                  'totalTokenCount': 18,
                },
              },
            );
          },
        ),
      ).chatModel(
        'gemini-3-pro-preview',
        settings: const GoogleChatModelSettings(
          headers: {
            'x-settings': '1',
          },
        ),
      );

      final result = await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            SystemPromptMessage.text('You are concise.'),
            UserPromptMessage.text('Say hello.'),
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
            timeout: const Duration(seconds: 5),
            headers: const {
              'x-call': '2',
            },
            cancellation: cancelToken,
            providerOptions: const GoogleGenerateTextOptions(
              includeThoughts: true,
              thinkingLevel: GoogleThinkingLevel.high,
              tools: [
                GoogleCodeExecutionTool(),
              ],
            ),
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.uri.toString(),
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-pro-preview:generateContent',
      );
      expect(capturedRequest!.method, TransportMethod.post);
      expect(capturedRequest!.responseType, TransportResponseType.json);
      expect(capturedRequest!.timeout, const Duration(seconds: 5));
      expect(capturedRequest!.cancellation, isNotNull);
      expect(capturedRequest!.headers['x-goog-api-key'], 'test-key');
      expect(capturedRequest!.headers['x-settings'], '1');
      expect(capturedRequest!.headers['x-call'], '2');
      expect(capturedRequest!.headers['accept'], 'application/json');

      final body = capturedRequest!.body as Map<String, Object?>;
      expect(body['systemInstruction'], isNotNull);
      expect(
        body['generationConfig'],
        {
          'thinkingConfig': {
            'includeThoughts': true,
            'thinkingLevel': 'high',
          },
        },
      );
      expect(
        body['tools'],
        [
          {
            'codeExecution': <String, Object?>{},
          },
        ],
      );
      expect(body.containsKey('toolConfig'), isFalse);

      expect(result.responseId, 'resp_1');
      expect(result.responseModelId, 'gemini-3-pro-preview');
      expect(result.text, 'Hello from Google.');
      expect(result.reasoningText, 'Plan first.');
      expect(result.finishReason, FinishReason.stop);
      expect(result.usage?.outputTokens, 8);
      expect(result.usage?.reasoningTokens, 5);
      expect(
        result.warnings.map((warning) => warning.field),
        containsAll([
          'tools',
          'toolChoice',
        ]),
      );
    });

    test(
        'generate encodes mixed Google native tools and common function tools for Gemini 3 when includeServerSideToolInvocations is enabled',
        () async {
      TransportRequest? capturedRequest;

      final model = Google(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'responseId': 'resp_2',
                'modelVersion': 'gemini-3-pro-preview',
                'candidates': [
                  {
                    'content': {
                      'parts': [
                        {
                          'text': 'Mixed tools are enabled.',
                        },
                      ],
                    },
                    'finishReason': 'STOP',
                  },
                ],
              },
            );
          },
        ),
      ).chatModel('gemini-3-pro-preview');

      final result = await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Search the web and check the weather.'),
          ],
          tools: [
            FunctionToolDefinition(
              name: 'weather',
              inputSchema: ToolJsonSchema.object(
                properties: const {
                  'city': {'type': 'string'},
                },
                required: const ['city'],
              ),
            ),
          ],
          toolChoice: const SpecificToolChoice('weather'),
          callOptions: const CallOptions(
            providerOptions: GoogleGenerateTextOptions(
              includeServerSideToolInvocations: true,
              tools: [
                GoogleSearchTool(),
              ],
            ),
          ),
        ),
      );

      final body = capturedRequest!.body as Map<String, Object?>;
      expect(
        body['tools'],
        [
          {
            'googleSearch': <String, Object?>{},
          },
          {
            'functionDeclarations': [
              {
                'name': 'weather',
                'description': '',
                'parameters': {
                  'type': 'object',
                  'properties': {
                    'city': {'type': 'string'},
                  },
                  'required': ['city'],
                },
              },
            ],
          },
        ],
      );
      expect(
        body['toolConfig'],
        {
          'includeServerSideToolInvocations': true,
          'functionCallingConfig': {
            'mode': 'ANY',
            'allowedFunctionNames': ['weather'],
          },
        },
      );
      expect(result.text, 'Mixed tools are enabled.');
      expect(result.warnings, isEmpty);
    });

    test(
        'generate forwards shared responseFormat from GenerateTextOptions to the Google request body',
        () async {
      TransportRequest? capturedRequest;

      final model = Google(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'responseId': 'resp_structured',
                'modelVersion': 'gemini-2.5-flash',
                'candidates': [
                  {
                    'content': {
                      'parts': [
                        {
                          'text': '{"answer":"Hello"}',
                        },
                      ],
                    },
                    'finishReason': 'STOP',
                  },
                ],
              },
            );
          },
        ),
      ).chatModel('gemini-2.5-flash');

      await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Return JSON.'),
          ],
          options: GenerateTextOptions(
            responseFormat: JsonResponseFormat(
              name: 'answer',
              description: 'Structured answer payload.',
              schema: JsonSchema.object(
                properties: const {
                  'answer': {'type': 'string'},
                },
                required: const ['answer'],
                additionalProperties: false,
              ),
            ),
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      final body = capturedRequest!.body as Map<String, Object?>;
      expect(
        body['generationConfig'],
        {
          'responseMimeType': 'application/json',
          'responseSchema': {
            'type': 'object',
            'properties': {
              'answer': {'type': 'string'},
            },
            'required': ['answer'],
          },
        },
      );
    });

    test(
        'generate preserves Google provider options when applying shared responseFormat',
        () async {
      TransportRequest? capturedRequest;

      final model = Google(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'responseId': 'resp_structured_options',
                'modelVersion': 'gemini-2.5-flash',
                'candidates': [
                  {
                    'content': {
                      'parts': [
                        {
                          'text': '{"answer":"Hello"}',
                        },
                      ],
                    },
                    'finishReason': 'STOP',
                  },
                ],
              },
            );
          },
        ),
      ).chatModel('gemini-2.5-flash');

      await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Return JSON.'),
          ],
          options: GenerateTextOptions(
            responseFormat: JsonResponseFormat(
              schema: JsonSchema.object(
                properties: const {
                  'answer': {'type': 'string'},
                },
              ),
            ),
          ),
          callOptions: const CallOptions(
            providerOptions: GoogleGenerateTextOptions(
              candidateCount: 1,
              includeThoughts: true,
              cachedContent: 'cachedContents/demo',
            ),
          ),
        ),
      );

      final body = capturedRequest!.body as Map<String, Object?>;
      expect(body['cachedContent'], 'cachedContents/demo');
      expect(
        body['generationConfig'],
        {
          'candidateCount': 1,
          'thinkingConfig': {
            'includeThoughts': true,
          },
          'responseMimeType': 'application/json',
          'responseSchema': {
            'type': 'object',
            'properties': {
              'answer': {'type': 'string'},
            },
          },
        },
      );
    });

    test(
        'generate rejects configuring shared and Google-specific response formats at the same time',
        () async {
      final model = Google(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).chatModel('gemini-2.5-flash');

      await expectLater(
        model.doGenerate(
          GenerateTextRequest(
            prompt: [
              UserPromptMessage.text('Return JSON.'),
            ],
            options: GenerateTextOptions(
              responseFormat: JsonResponseFormat(
                schema: JsonSchema.object(
                  properties: const {
                    'answer': {'type': 'string'},
                  },
                ),
              ),
            ),
            callOptions: const CallOptions(
              providerOptions: GoogleGenerateTextOptions(
                responseFormat: GoogleJsonSchemaResponseFormat(
                  schema: {
                    'type': 'object',
                    'properties': {
                      'answer': {'type': 'string'},
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
    });

    test('stream sends SSE requests and maps unified events', () async {
      TransportRequest? capturedRequest;

      final model = Google(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSendStream: (request) async {
            capturedRequest = request;
            return StreamingTransportResponse(
              statusCode: 200,
              stream: Stream.fromIterable([
                utf8.encode(
                  'data: {"responseId":"resp_1","modelVersion":"gemini-3-pro-preview","usageMetadata":{"promptTokenCount":5,"candidatesTokenCount":1,"totalTokenCount":6},"candidates":[{"content":{"parts":[{"text":"Hello"}]}}]}\n\n',
                ),
                utf8.encode(
                  'data: {"usageMetadata":{"promptTokenCount":5,"candidatesTokenCount":2,"thoughtsTokenCount":3,"totalTokenCount":10},"candidates":[{"content":{"parts":[{"functionCall":{"name":"weather","args":{"city":"Hong Kong"}}}]},"finishReason":"STOP"}]}\n\n',
                ),
              ]),
            );
          },
        ),
      ).chatModel('gemini-3-pro-preview');

      final events = await model
          .doStream(
            GenerateTextRequest(
              prompt: [
                UserPromptMessage.text('Say hello.'),
              ],
              options: const GenerateTextOptions(
                includeRawChunks: true,
              ),
            ),
          )
          .toList();

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.uri.toString(),
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-pro-preview:streamGenerateContent?alt=sse',
      );
      expect(capturedRequest!.headers['accept'], 'text/event-stream');

      expect(events.first, isA<StartEvent>());
      expect(events.whereType<ResponseMetadataEvent>().single.responseId,
          'resp_1');
      expect(events.whereType<TextDeltaEvent>().single.delta, 'Hello');
      expect(events.whereType<ToolInputDeltaEvent>().single.delta,
          '{"city":"Hong Kong"}');
      expect(events.whereType<ToolCallEvent>().single.toolCall.toolName,
          'weather');
      expect(events.whereType<FinishEvent>().single.finishReason,
          FinishReason.toolCalls);
      final rawChunks = events.whereType<RawChunkEvent>().toList();
      expect(rawChunks, hasLength(2));
      expect(rawChunks.first.raw, containsPair('responseId', 'resp_1'));
    });

    test(
        'stream maps source, file, reasoning-file, and finish events end to end',
        () async {
      final model = Google(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSendStream: (request) async {
            return StreamingTransportResponse(
              statusCode: 200,
              stream: Stream.fromIterable([
                utf8.encode(
                  'data: {"responseId":"resp_2","modelVersion":"gemini-3-pro-preview","usageMetadata":{"promptTokenCount":5,"candidatesTokenCount":2,"thoughtsTokenCount":3,"totalTokenCount":10},"candidates":[{"content":{"parts":[{"inlineData":{"mimeType":"application/pdf","data":"AQID"}},{"inlineData":{"mimeType":"image/png","data":"BAUG"},"thought":true,"thoughtSignature":"sig_reasoning_file"}]},"groundingMetadata":{"groundingChunks":[{"web":{"uri":"https://example.com","title":"Example"}}]},"finishReason":"STOP"}]}\n\n',
                ),
              ]),
            );
          },
        ),
      ).chatModel('gemini-3-pro-preview');

      final events = await model
          .doStream(
            GenerateTextRequest(
              prompt: [
                UserPromptMessage.text('Summarize the source.'),
              ],
            ),
          )
          .toList();

      expect(events.first, isA<StartEvent>());
      expect(events.whereType<ResponseMetadataEvent>().single.responseId,
          'resp_2');

      final sourceEvent = events.whereType<SourceEvent>().single;
      expect(sourceEvent.source.uri, Uri.parse('https://example.com'));
      expect(sourceEvent.source.title, 'Example');

      final fileEvent = events.whereType<FileEvent>().single;
      expect(fileEvent.file.mediaType, 'application/pdf');
      expect(fileEvent.file.bytes, [1, 2, 3]);

      final reasoningFileEvent = events.whereType<ReasoningFileEvent>().single;
      expect(reasoningFileEvent.file.mediaType, 'image/png');
      expect(reasoningFileEvent.file.bytes, [4, 5, 6]);
      expect(
        reasoningFileEvent.providerMetadata?.values['google'],
        {
          'thoughtSignature': 'sig_reasoning_file',
          'thought': true,
        },
      );

      final finishEvent = events.whereType<FinishEvent>().single;
      expect(finishEvent.finishReason, FinishReason.stop);
      expect(finishEvent.rawFinishReason, 'STOP');
      expect(finishEvent.usage?.totalTokens, 10);
      expect(finishEvent.usage?.reasoningTokens, 3);
      expect(
        finishEvent.providerMetadata?.values['google'],
        allOf(
          contains('groundingMetadata'),
          containsPair(
            'usageMetadata',
            {
              'promptTokenCount': 5,
              'candidatesTokenCount': 2,
              'thoughtsTokenCount': 3,
              'totalTokenCount': 10,
            },
          ),
        ),
      );
    });

    test('rejects provider options from a different provider', () async {
      final model = Google(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).chatModel('gemini-3-pro-preview');

      expect(
        () => model.doGenerate(
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
