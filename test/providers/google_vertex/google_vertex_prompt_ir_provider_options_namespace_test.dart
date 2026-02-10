import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

void main() {
  group('Google Vertex Prompt IR providerOptions namespace', () {
    test(
        'reads thoughtSignature from providerOptions[google-vertex] (not vertex)',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: googleVertexBaseUrl,
        model: 'gemini-2.5-pro',
      );

      final config = GoogleConfig.fromLLMConfig(
        llmConfig,
        providerId: 'google-vertex',
        providerOptionsName: 'google-vertex',
      );

      final client = FakeGoogleClient(
        config,
        defaultJsonResponse: {
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
        },
      );
      final chat = GoogleChat(client, config);

      final prompt = Prompt(
        messages: [
          const PromptMessage(
            role: ChatRole.assistant,
            parts: [
              TextPart(
                'Thinking...',
                providerOptions: {
                  'google-vertex': {'thoughtSignature': 'sigV'},
                },
              ),
            ],
          ),
        ],
      );

      await chat.chatPrompt(prompt);

      final contents = client.lastBody?['contents'] as List?;
      expect(contents, isNotNull);
      expect(contents, hasLength(1));

      final entry = contents!.single as Map;
      expect(entry['role'], equals('model'));
      final parts = entry['parts'] as List;
      expect(parts, hasLength(1));
      expect(
        parts.single,
        equals({'text': 'Thinking...', 'thoughtSignature': 'sigV'}),
      );
    });
  });
}
