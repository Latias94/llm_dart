import 'package:llm_dart/ai.dart' as ai;
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as anthropic_pkg;
import 'package:llm_dart_google/llm_dart_google.dart' as google_pkg;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_pkg;
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:test/test.dart';

void main() {
  group('provider prompt normalization integration', () {
    test('OpenAI Responses receives normalized user messages', () async {
      ai.TransportRequest? capturedRequest;
      final model = openai_pkg
          .openai(
            apiKey: 'test-key',
            transport: FakeTransportClient(
              onSend: (request) async {
                capturedRequest = request;
                return const ai.TransportResponse(
                  statusCode: 200,
                  body: {
                    'id': 'resp_normalized_openai',
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
                            'text': 'Hello.',
                            'annotations': [],
                          },
                        ],
                      },
                    ],
                  },
                );
              },
            ),
          )
          .chatModel('gpt-4.1-mini');

      await ai.generateText(
        model: model,
        messages: [
          ai.UserModelMessage.text('Say hello.'),
        ],
      );

      final body = capturedRequest!.body as Map<String, Object?>;
      expect(
        body['input'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_text',
                'text': 'Say hello.',
              },
            ],
          },
        ],
      );
    });

    test('Google receives normalized system and user messages', () async {
      ai.TransportRequest? capturedRequest;
      final model = google_pkg
          .google(
            apiKey: 'test-key',
            transport: FakeTransportClient(
              onSend: (request) async {
                capturedRequest = request;
                return const ai.TransportResponse(
                  statusCode: 200,
                  body: {
                    'responseId': 'resp_normalized_google',
                    'modelVersion': 'gemini-2.5-flash',
                    'candidates': [
                      {
                        'content': {
                          'parts': [
                            {
                              'text': 'Hello.',
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
          )
          .chatModel('gemini-2.5-flash');

      await ai.generateText(
        model: model,
        messages: [
          const ai.SystemModelMessage.text('You are concise.'),
          ai.UserModelMessage.text('Say hello.'),
        ],
      );

      final body = capturedRequest!.body as Map<String, Object?>;
      expect(
        body['systemInstruction'],
        {
          'parts': [
            {
              'text': 'You are concise.',
            },
          ],
        },
      );
      expect(
        body['contents'],
        [
          {
            'role': 'user',
            'parts': [
              {
                'text': 'Say hello.',
              },
            ],
          },
        ],
      );
    });

    test('Anthropic receives normalized system and user messages', () async {
      ai.TransportRequest? capturedRequest;
      final model = anthropic_pkg
          .anthropic(
            apiKey: 'test-key',
            transport: FakeTransportClient(
              onSend: (request) async {
                capturedRequest = request;
                return const ai.TransportResponse(
                  statusCode: 200,
                  body: {
                    'id': 'msg_normalized_anthropic',
                    'model': 'claude-sonnet-4-5',
                    'content': [
                      {
                        'type': 'text',
                        'text': 'Hello.',
                      },
                    ],
                    'stop_reason': 'end_turn',
                    'usage': {
                      'input_tokens': 3,
                      'output_tokens': 2,
                    },
                  },
                );
              },
            ),
          )
          .chatModel('claude-sonnet-4-5');

      await ai.generateText(
        model: model,
        messages: [
          const ai.SystemModelMessage.text('You are concise.'),
          ai.UserModelMessage.text('Say hello.'),
        ],
      );

      final body = capturedRequest!.body as Map<String, Object?>;
      expect(
        body['system'],
        [
          {
            'type': 'text',
            'text': 'You are concise.',
          },
        ],
      );
      expect(
        body['messages'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'Say hello.',
              },
            ],
          },
        ],
      );
    });
  });
}
