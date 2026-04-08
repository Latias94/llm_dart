import 'package:llm_dart_community/llm_dart_community.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('ElevenLabsSpeechModel', () {
    test('ElevenLabs factory exposes a speech model', () {
      final model = ElevenLabs(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).speechModel('eleven_multilingual_v2');

      expect(model.providerId, 'elevenlabs');
      expect(model.baseUrl, ElevenLabs.defaultBaseUrl);
      expect(model.defaultHeaders, {
        'xi-api-key': 'test-key',
      });
    });

    test('generateSpeech sends ElevenLabs request shape and decodes audio',
        () async {
      TransportRequest? capturedRequest;
      final cancelToken = TransportCancellation();

      final model = ElevenLabs(
        apiKey: 'test-key',
        baseUrl: 'https://api.elevenlabs.io/v1/',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              headers: {
                'content-type': 'audio/mpeg',
                'x-request-id': 'req_123',
              },
              body: [1, 2, 3, 4],
            );
          },
        ),
      ).speechModel(
        'eleven_multilingual_v2',
        settings: const ElevenLabsSpeechModelSettings(
          headers: {
            'x-settings': '1',
          },
          defaultVoiceId: 'voice_default',
          stability: 0.3,
          similarityBoost: 0.4,
          style: 0.5,
          useSpeakerBoost: true,
        ),
      );

      final result = await generateSpeech(
        model: model,
        text: 'Hello world.',
        callOptions: CallOptions(
          timeout: const Duration(seconds: 5),
          headers: const {
            'x-request': 'request-header',
          },
          cancellation: cancelToken,
          providerOptions: const ElevenLabsSpeechOptions(
            outputFormat: 'pcm',
            languageCode: 'en',
            speed: 1.1,
            pronunciationDictionaryLocators: [
              ElevenLabsPronunciationDictionaryLocator(
                pronunciationDictionaryId: 'dict_1',
                versionId: 'v1',
              ),
            ],
            seed: 7,
            previousText: 'Earlier text.',
            nextText: 'Later text.',
            previousRequestIds: ['req_prev'],
            nextRequestIds: ['req_next'],
            textNormalization: ElevenLabsTextNormalization.off,
            applyLanguageTextNormalization: true,
            enableLogging: false,
            optimizeStreamingLatency: 2,
            stability: 0.8,
            similarityBoost: 0.9,
            style: 1.0,
            useSpeakerBoost: false,
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.uri.toString(),
        'https://api.elevenlabs.io/v1/text-to-speech/voice_default?output_format=pcm_44100&enable_logging=false&optimize_streaming_latency=2',
      );
      expect(capturedRequest!.method, TransportMethod.post);
      expect(capturedRequest!.responseType, TransportResponseType.bytes);
      expect(capturedRequest!.timeout, const Duration(seconds: 5));
      expect(identical(capturedRequest!.cancellation, cancelToken), isTrue);
      expect(
        capturedRequest!.headers,
        {
          'xi-api-key': 'test-key',
          'x-settings': '1',
          'content-type': 'application/json',
          'accept': 'application/octet-stream',
          'x-request': 'request-header',
        },
      );
      expect(
        capturedRequest!.body,
        {
          'text': 'Hello world.',
          'model_id': 'eleven_multilingual_v2',
          'voice_settings': {
            'stability': 0.8,
            'similarity_boost': 0.9,
            'style': 1.0,
            'speed': 1.1,
            'use_speaker_boost': false,
          },
          'language_code': 'en',
          'pronunciation_dictionary_locators': [
            {
              'pronunciation_dictionary_id': 'dict_1',
              'version_id': 'v1',
            },
          ],
          'seed': 7,
          'previous_text': 'Earlier text.',
          'next_text': 'Later text.',
          'previous_request_ids': ['req_prev'],
          'next_request_ids': ['req_next'],
          'apply_text_normalization': 'off',
          'apply_language_text_normalization': true,
        },
      );
      expect(result.audioBytes, [1, 2, 3, 4]);
      expect(result.mediaType, 'audio/mpeg');
      expect(
        result.providerMetadata?.namespace('elevenlabs'),
        {
          'requestId': 'req_123',
        },
      );
    });

    test('speech model rejects incompatible provider options', () async {
      final model = ElevenLabs(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).speechModel('eleven_multilingual_v2');

      await expectLater(
        () => generateSpeech(
          model: model,
          text: 'Hello',
          callOptions: const CallOptions(
            providerOptions: ElevenLabsTranscriptionOptions(),
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('Expected ElevenLabsSpeechOptions'),
          ),
        ),
      );
    });
  });
}

typedef _FakeTransportClient = FakeTransportClient;
