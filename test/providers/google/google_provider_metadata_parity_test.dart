import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

void main() {
  group('Google providerMetadata (AI SDK parity)', () {
    test('exposes usageMetadata and safety/prompt/grounding metadata',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-2.5-flash',
      );

      final config = GoogleConfig.fromLLMConfig(llmConfig);
      final endpoint = 'models/${config.model}:generateContent';

      const promptFeedback = {
        'blockReason': 'SAFETY',
        'safetyRatings': [
          {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'probability': 'LOW'},
        ],
      };

      const usageMetadata = {
        'promptTokenCount': 12,
        'candidatesTokenCount': 34,
        'totalTokenCount': 46,
        'thoughtsTokenCount': 5,
      };

      const candidateSafetyRatings = [
        {'category': 'HARM_CATEGORY_HARASSMENT', 'probability': 'NEGLIGIBLE'},
      ];

      const groundingMetadata = {
        'webSearchQueries': ['llm_dart'],
      };

      const urlContextMetadata = {
        'urlMetadata': [
          {'url': 'https://example.com', 'title': 'Example'},
        ],
      };

      final client = FakeGoogleClient(
        config,
        responsesByEndpoint: {
          endpoint: {
            'promptFeedback': promptFeedback,
            'usageMetadata': usageMetadata,
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'ok'},
                  ],
                },
                'finishReason': 'STOP',
                'safetyRatings': candidateSafetyRatings,
                'groundingMetadata': groundingMetadata,
                'urlContextMetadata': urlContextMetadata,
              },
            ],
          },
        },
      );
      final chat = GoogleChat(client, config);

      final response = await chat.chatWithTools(
        [ChatMessage.user('hi')],
        const [],
      );

      final metadata = response.providerMetadata;
      expect(metadata, isNotNull);
      expect(metadata!.keys,
          containsAll(['google', 'google.chat', 'google.generative-ai']));

      final google = metadata['google'] as Map?;
      expect(google, isNotNull);

      expect(google!['promptFeedback'], equals(promptFeedback));
      expect(google['safetyRatings'], equals(candidateSafetyRatings));
      expect(google['groundingMetadata'], equals(groundingMetadata));
      expect(google['urlContextMetadata'], equals(urlContextMetadata));

      expect(google['usageMetadata'], equals(usageMetadata));

      final usage = google['usage'] as Map?;
      expect(usage, isNotNull);
      expect(usage!['promptTokens'], equals(usageMetadata['promptTokenCount']));
      expect(
        usage['completionTokens'],
        equals(usageMetadata['candidatesTokenCount']),
      );
      expect(usage['totalTokens'], equals(usageMetadata['totalTokenCount']));
      expect(usage['reasoningTokens'],
          equals(usageMetadata['thoughtsTokenCount']));
    });
  });
}
