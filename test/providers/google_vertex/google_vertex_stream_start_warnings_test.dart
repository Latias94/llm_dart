import 'dart:convert';

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

String _sseData(Map<String, dynamic> json) => 'data: ${jsonEncode(json)}\n\n';

void main() {
  group('Google Vertex stream-start warnings', () {
    test('emits toolWarnings via LLMStreamStartPart when streaming', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-2.5-flash',
        providerOptions: const {
          'google-vertex': {
            'webSearchEnabled': true,
          },
        },
      );

      final config = GoogleConfig.fromLLMConfig(
        llmConfig,
        providerId: 'google-vertex',
        providerOptionsName: 'google-vertex',
      );

      final client = FakeGoogleClient(config)
        ..streamResponse = Stream<String>.fromIterable([
          _sseData({
            'modelVersion': config.model,
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'ok'}
                  ],
                },
              },
            ],
          }),
          _sseData({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': ''}
                  ],
                },
                'finishReason': 'STOP',
              },
            ],
          }),
        ]);

      final chat = GoogleChat(client, config);

      final parts = await chat.chatStreamParts(
        [ChatMessage.user('hi')],
        tools: [
          Tool.function(
            name: 'testFunction',
            description: 'Test',
            parameters: const ParametersSchema(
              schemaType: 'object',
              properties: {},
              required: [],
            ),
          ),
        ],
      ).toList();

      expect(parts.first, isA<LLMStreamStartPart>());
      final start = parts.first as LLMStreamStartPart;
      expect(start.warnings, hasLength(1));
      expect(start.warnings.single, isA<LLMUnsupportedWarning>());
      expect(
        (start.warnings.single as LLMUnsupportedWarning).feature,
        equals('combination of function and provider-defined tools'),
      );
    });
  });
}
