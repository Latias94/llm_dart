import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

void main() {
  group('Google non-stream response metadata timestamp fallback', () {
    test('fills responseMetadata.timestamp when provider does not supply it',
        () async {
      final config = const GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.5-pro',
      );

      final client = FakeGoogleClient(
        config,
        responsesByEndpoint: const {
          'models/gemini-2.5-pro:generateContent': {
            'modelVersion': 'gemini-2.5-pro',
            'candidates': [
              {
                'content': {
                  'role': 'model',
                  'parts': [
                    {'text': 'Hello'}
                  ],
                },
                'finishReason': 'STOP',
                'index': 0,
              }
            ],
          },
        },
      )..jsonHeaders = const {'x-test': '1'};

      final provider = GoogleProvider(config, client: client);

      final result = await generateText(model: provider, prompt: 'hi');

      expect(result.responseMetadata, isNotNull);
      expect(result.responseMetadata!.headers, containsPair('x-test', '1'));
      expect(result.responseMetadata!.timestamp, isNotNull);
      expect(result.responseMetadata!.modelId, equals('gemini-2.5-pro'));
    });
  });
}
