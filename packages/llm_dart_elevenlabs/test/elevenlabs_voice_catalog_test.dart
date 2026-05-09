import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('ElevenLabsVoiceCatalogClient', () {
    test('ElevenLabs factory exposes a voice catalog client', () {
      final voices = ElevenLabs(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).voices();

      expect(voices.baseUrl, ElevenLabs.defaultBaseUrl);
    });

    test('listVoices fetches typed voice descriptors', () async {
      TransportRequest? capturedRequest;
      final cancelToken = TransportCancellation();

      final voices = ElevenLabs(
        apiKey: 'test-key',
        baseUrl: 'https://api.elevenlabs.io/v1/',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'voices': [
                  {
                    'voice_id': 'voice_123',
                    'name': 'Rachel',
                    'category': 'premade',
                    'description': 'Warm narration voice.',
                    'preview_url': 'https://example.com/rachel.mp3',
                    'labels': {
                      'gender': 'female',
                      'accent': 'american',
                    },
                    'available_for_tiers': ['free', 'creator'],
                  },
                ],
              },
            );
          },
        ),
      ).voices(
        settings: const ElevenLabsVoiceCatalogSettings(
          headers: {
            'x-settings': '1',
          },
        ),
      );

      final result = await voices.listVoices(
        timeout: const Duration(seconds: 5),
        cancellation: cancelToken,
        headers: const {
          'x-call': '2',
        },
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.uri.toString(),
        'https://api.elevenlabs.io/v1/voices',
      );
      expect(capturedRequest!.method, TransportMethod.get);
      expect(capturedRequest!.responseType, TransportResponseType.json);
      expect(capturedRequest!.timeout, const Duration(seconds: 5));
      expect(identical(capturedRequest!.cancellation, cancelToken), isTrue);
      expect(capturedRequest!.headers, {
        'xi-api-key': 'test-key',
        'accept': 'application/json',
        'x-settings': '1',
        'x-call': '2',
      });

      expect(result, hasLength(1));
      expect(result.single.id, 'voice_123');
      expect(result.single.name, 'Rachel');
      expect(result.single.category, 'premade');
      expect(result.single.description, 'Warm narration voice.');
      expect(result.single.previewUrl, 'https://example.com/rachel.mp3');
      expect(result.single.gender, 'female');
      expect(result.single.accent, 'american');
      expect(result.single.availableForTiers, ['free', 'creator']);
    });
  });
}

typedef _FakeTransportClient = FakeTransportClient;
