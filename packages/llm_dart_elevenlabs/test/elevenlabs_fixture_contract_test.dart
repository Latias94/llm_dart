import 'dart:convert';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  final fixtures = ProviderCodecContractRunner.forWorkspacePackage(
    'llm_dart_elevenlabs',
    label: 'ElevenLabs fixture contract',
  );
  const transportProjector = ProviderTransportContractProjector();

  group('ElevenLabs fixture contract', () {
    test('locks speech request transport contract', () async {
      TransportRequest? capturedRequest;

      final model = ElevenLabs(
        apiKey: 'test-key',
        baseUrl: 'https://api.elevenlabs.io/v1/',
        transport: FakeTransportClient(
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

      await generateSpeech(
        model: model,
        text: 'Hello world.',
        outputFormat: 'pcm',
        language: 'en',
        speed: 1.1,
        callOptions: const CallOptions(
          timeout: Duration(seconds: 5),
          headers: {
            'x-request': 'request-header',
          },
          providerOptions: ElevenLabsSpeechOptions(
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

      fixtures.expectJsonFixture(
        'elevenlabs/speech_request_contract_golden.json',
        transportProjector.requestJson(capturedRequest!),
      );
    });

    test('locks transcription multipart transport contract', () async {
      TransportRequest? capturedRequest;

      final model = ElevenLabs(
        apiKey: 'test-key',
        transport: FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'text': 'hello world',
              },
            );
          },
        ),
      ).transcriptionModel(
        'scribe_v1',
        settings: const ElevenLabsTranscriptionModelSettings(
          headers: {
            'x-settings': '1',
          },
        ),
      );

      await transcribe(
        model: model,
        audioBytes: utf8.encode('abc'),
        mediaType: 'audio/mpeg',
        callOptions: const CallOptions(
          timeout: Duration(seconds: 5),
          headers: {
            'x-request': 'request-header',
          },
          providerOptions: ElevenLabsTranscriptionOptions(
            languageCode: 'en',
            tagAudioEvents: false,
            numSpeakers: 2,
            timestampGranularity:
                ElevenLabsTranscriptionTimestampGranularity.character,
            diarize: true,
            fileFormat: ElevenLabsTranscriptionFileFormat.pcmS16le16,
            enableLogging: false,
          ),
        ),
      );

      fixtures.expectJsonFixture(
        'elevenlabs/transcription_request_contract_golden.json',
        transportProjector.multipartRequestJson(
          capturedRequest!,
          headerNames: const [
            'xi-api-key',
            'x-settings',
            'x-request',
            'accept',
          ],
        ),
      );
    });
  });
}
