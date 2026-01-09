import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

void main() {
  group('Google thoughtSignature (AI SDK parity)', () {
    test('propagates thoughtSignature on non-stream toolCalls', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-2.5-flash',
      );

      final config = GoogleConfig.fromLLMConfig(llmConfig);
      final endpoint = 'models/${config.model}:generateContent';

      final client = FakeGoogleClient(
        config,
        responsesByEndpoint: {
          endpoint: {
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'functionCall': {
                        'name': 'test',
                        'args': {'value': 'ok'},
                      },
                      'thoughtSignature': 'sig1',
                    },
                  ],
                },
              },
            ],
          },
        },
      );
      final chat = GoogleChat(client, config);

      final response = await chat.chatWithTools(
        [ChatMessage.user('hi')],
        [
          Tool.function(
            name: 'test',
            description: 'Test',
            parameters: const ParametersSchema(
              schemaType: 'object',
              properties: {},
              required: [],
            ),
          ),
        ],
      );

      final calls = response.toolCalls;
      expect(calls, isNotNull);
      expect(calls, isNotEmpty);

      final sig = calls!.first.providerOptions['google']?['thoughtSignature'];
      expect(sig, equals('sig1'));
    });

    test('propagates thoughtSignature on streaming tool call parts', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-2.5-flash',
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = FakeGoogleClient(config)
        ..streamResponse = Stream.fromIterable([
          '{"candidates":[{"content":{"parts":[{"functionCall":{"name":"test","args":{"value":"ok"}},"thoughtSignature":"sig2"}]}}]}',
          '{"candidates":[{"finishReason":"STOP","content":{"parts":[]}}]}',
        ]);
      final chat = GoogleChat(client, config);

      final parts = await chat.chatStreamParts(
        [ChatMessage.user('hi')],
        tools: [
          Tool.function(
            name: 'test',
            description: 'Test',
            parameters: const ParametersSchema(
              schemaType: 'object',
              properties: {},
              required: [],
            ),
          ),
        ],
      ).toList();

      final start = parts.whereType<LLMToolCallStartPart>().toList();
      expect(start, isNotEmpty);

      final sig =
          start.first.toolCall.providerOptions['google']?['thoughtSignature'];
      expect(sig, equals('sig2'));
    });
  });
}
