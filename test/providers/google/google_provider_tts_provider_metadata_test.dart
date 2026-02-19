import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/google.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

void main() {
  group('GoogleProvider textToSpeech providerMetadata', () {
    test('attaches canonical google providerMetadata with endpoint + model',
        () async {
      final config = GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.5-flash-preview-tts',
      );

      const endpoint = 'models/gemini-2.5-flash-preview-tts:generateContent';

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
                  ]
                }
              }
            ],
            'usageMetadata': {
              'promptTokenCount': 1,
              'candidatesTokenCount': 1,
              'totalTokenCount': 2,
            },
            'modelVersion': 'gemini-2.5-flash-preview-tts',
          },
        },
      );
      client.jsonHeaders = const {'x-request-id': 'rid-123'};
      final provider = GoogleProvider(config, client: client);

      final response = await provider.textToSpeech(
        const TTSRequest(
          text: 'hi',
          model: 'gemini-2.5-flash-preview-tts',
          voice: 'Kore',
        ),
      );

      expect(client.lastEndpoint, endpoint);
      expect(response.responses, hasLength(1));
      expect(response.responses.single.headers,
          equals({'x-request-id': 'rid-123'}));

      final meta = response.providerMetadata;
      expect(meta, isNotNull);
      expect(meta!.containsKey('google'), isTrue);
      expect(meta.containsKey('google.speech'), isFalse);
      expect(
        meta['google'],
        equals({
          'model': 'gemini-2.5-flash-preview-tts',
          'endpoint': endpoint,
        }),
      );
    });
  });
}
