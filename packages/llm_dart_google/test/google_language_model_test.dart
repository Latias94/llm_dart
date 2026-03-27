import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('GoogleLanguageModel', () {
    test('generate sends generateContent requests and maps unified results',
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

      final result = await model.generate(
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
          callOptions: const CallOptions(
            timeout: Duration(seconds: 5),
            headers: {
              'x-call': '2',
            },
            providerOptions: GoogleGenerateTextOptions(
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
          .stream(
            GenerateTextRequest(
              prompt: [
                UserPromptMessage.text('Say hello.'),
              ],
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
    });

    test('rejects provider options from a different provider', () async {
      final model = Google(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).chatModel('gemini-3-pro-preview');

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

final class _FakeTransportClient implements TransportClient {
  final Future<TransportResponse> Function(TransportRequest request)? onSend;
  final Future<StreamingTransportResponse> Function(TransportRequest request)?
      onSendStream;

  const _FakeTransportClient({
    this.onSend,
    this.onSendStream,
  });

  @override
  Future<TransportResponse> send(TransportRequest request) {
    if (onSend == null) {
      throw UnimplementedError('send() was not configured for this test.');
    }

    return onSend!(request);
  }

  @override
  Future<StreamingTransportResponse> sendStream(TransportRequest request) {
    if (onSendStream == null) {
      throw UnimplementedError(
        'sendStream() was not configured for this test.',
      );
    }

    return onSendStream!(request);
  }
}
