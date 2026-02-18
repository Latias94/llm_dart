import 'dart:convert';

import 'package:llm_dart_google/google.dart';
import 'package:llm_dart_google/provider.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

void main() {
  group('Google ProviderV3 factory', () {
    test('creates a v3 provider and language models are per-model', () {
      final google = createGoogleGenerativeAI(
        apiKey: 'test-key',
        baseUrl: 'https://example.com/v1beta/',
      );

      expect(google.specificationVersion, equals('v3'));

      final model = google('gemini-2.5-flash');
      expect(model, isA<GoogleProvider>());
      expect(model.config.model, equals('gemini-2.5-flash'));
      expect(model.config.baseUrl, equals('https://example.com/v1beta'));
    });

    test('speechModel injects default model id into requests', () async {
      FakeGoogleClient? lastClient;

      const ttsModel = 'gemini-2.5-flash-preview-tts';
      const endpoint = 'models/$ttsModel:generateContent';

      final google = createGoogleGenerativeAI(
        apiKey: 'test-key',
        baseUrl: 'https://example.com/v1beta/',
        providerFactory: (GoogleConfig config) {
          final client = FakeGoogleClient(
            config,
            responsesByEndpoint: {
              endpoint: <String, dynamic>{
                'candidates': [
                  {
                    'content': {
                      'parts': [
                        {
                          'inlineData': {
                            'data': base64Encode(const [1, 2, 3]),
                            'mimeType': 'audio/pcm',
                          }
                        }
                      ],
                    }
                  }
                ],
                'modelVersion': ttsModel,
              },
            },
          );
          lastClient = client;
          return GoogleProvider(config, client: client);
        },
      );

      final tts = google.speechModel(ttsModel);
      await tts.textToSpeech(const TTSRequest(text: 'hi'));

      expect(lastClient, isNotNull);
      expect(lastClient!.lastEndpoint, equals(endpoint));
    });
  });
}

