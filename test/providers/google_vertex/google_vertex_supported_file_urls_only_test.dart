import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

void main() {
  group('Google Vertex supportedFileUrlsOnly', () {
    test('rejects arbitrary https FileUrlPart URLs when enabled', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: googleVertexBaseUrl,
        model: 'gemini-2.5-pro',
        providerOptions: const {
          'google-vertex': {
            'supportedFileUrlsOnly': true,
          },
        },
      );

      final config = GoogleConfig.fromLLMConfig(
        llmConfig,
        providerId: 'vertex',
        providerOptionsName: 'vertex',
        providerOptionsFallbackIds: const ['google-vertex', 'google'],
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
            role: PromptRole.user,
            parts: [
              FileUrlPart(
                mime: FileMime.pdf,
                url: 'https://example.com/a.pdf',
              ),
            ],
          ),
        ],
      );

      await expectLater(
        chat.chatPrompt(prompt),
        throwsA(isA<InvalidRequestError>()),
      );
    });

    test('accepts Google Files API URLs when enabled', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: googleVertexBaseUrl,
        model: 'gemini-2.5-pro',
        providerOptions: const {
          'google-vertex': {
            'supportedFileUrlsOnly': true,
          },
        },
      );

      final config = GoogleConfig.fromLLMConfig(
        llmConfig,
        providerId: 'vertex',
        providerOptionsName: 'vertex',
        providerOptionsFallbackIds: const ['google-vertex', 'google'],
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
            role: PromptRole.user,
            parts: [
              FileUrlPart(
                mime: FileMime.pdf,
                url:
                    'https://generativelanguage.googleapis.com/v1beta/files/abc',
              ),
            ],
          ),
        ],
      );

      await chat.chatPrompt(prompt);

      final contents = client.lastBody?['contents'] as List?;
      expect(contents, isNotNull);
      expect(contents, hasLength(1));

      final parts = ((contents!.single as Map)['parts'] as List);
      expect(parts, hasLength(1));
      final fileData = (parts.single as Map)['fileData'] as Map;
      expect(
        fileData['fileUri'],
        equals('https://generativelanguage.googleapis.com/v1beta/files/abc'),
      );
    });
  });
}
