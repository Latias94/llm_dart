import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAILanguageModel', () {
    test('generate maps a Responses API payload to the unified result', () async {
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
                'status': 'completed',
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
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.method, TransportMethod.post);
      expect(capturedRequest!.responseType, TransportResponseType.json);

      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(requestBody['model'], 'gpt-4.1-mini');
      expect(requestBody['stream'], isFalse);

      expect(result.text, 'Hello from OpenAI.');
      expect(result.reasoningText, 'Thinking through the answer.');
      expect(result.finishReason, FinishReason.stop);
      expect(result.usage?.reasoningTokens, 3);
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

      final events = await model.stream(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Say hello.'),
          ],
        ),
      ).toList();

      expect(events.first, isA<StartEvent>());
      expect((events.first as StartEvent).warnings, isEmpty);
      final responseMetadata = events.whereType<ResponseMetadataEvent>().single;
      expect(responseMetadata.responseId, 'resp_1');
      expect(responseMetadata.modelId, 'gpt-4.1-mini');
      expect(events.whereType<TextStartEvent>().single.id, 'msg_1');
      expect(events.whereType<TextDeltaEvent>().single.delta, 'Hello');
      expect(events.whereType<TextEndEvent>().single.id, 'msg_1');
      expect(events.whereType<CustomEvent>().single.kind, 'openai.web_search_call');

      final finish = events.whereType<FinishEvent>().single;
      expect(finish.finishReason, FinishReason.stop);
      expect(finish.usage?.totalTokens, 2);
    });
  });
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
