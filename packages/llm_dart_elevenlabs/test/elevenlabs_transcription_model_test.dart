import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'dart:convert';

import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('ElevenLabsTranscriptionModel', () {
    test('ElevenLabs factory exposes a transcription model', () {
      final model = ElevenLabs(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).transcriptionModel('scribe_v1');

      expect(model.providerId, 'elevenlabs');
      expect(model.baseUrl, ElevenLabs.defaultBaseUrl);
      expect(model.defaultHeaders, {
        'xi-api-key': 'test-key',
      });
    });

    test('transcribe sends multipart data and decodes ElevenLabs metadata',
        () async {
      TransportRequest? capturedRequest;
      final cancelToken = TransportCancellation();

      final model = ElevenLabs(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              headers: {
                'x-request-id': 'req_456',
              },
              body: {
                'text': 'hello world',
                'language_code': 'en',
                'language_probability': 0.98,
                'words': [
                  {
                    'text': 'hello',
                    'type': 'word',
                    'start': 0.0,
                    'end': 0.5,
                  },
                ],
                'additional_formats': {
                  'segments': [
                    {
                      'text': 'hello world',
                    },
                  ],
                },
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

      final result = await transcribe(
        model: model,
        audioBytes: utf8.encode('abc'),
        mediaType: 'audio/mpeg',
        callOptions: CallOptions(
          timeout: const Duration(seconds: 5),
          headers: const {
            'x-request': 'request-header',
          },
          cancellation: cancelToken,
          providerOptions: const ElevenLabsTranscriptionOptions(
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

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.uri.toString(),
        'https://api.elevenlabs.io/v1/speech-to-text?enable_logging=false',
      );
      expect(capturedRequest!.method, TransportMethod.post);
      expect(capturedRequest!.responseType, TransportResponseType.json);
      expect(capturedRequest!.timeout, const Duration(seconds: 5));
      expect(identical(capturedRequest!.cancellation, cancelToken), isTrue);
      expect(capturedRequest!.headers['xi-api-key'], 'test-key');
      expect(capturedRequest!.headers['x-settings'], '1');
      expect(capturedRequest!.headers['x-request'], 'request-header');
      expect(capturedRequest!.headers['accept'], 'application/json');
      final contentType = capturedRequest!.headers['content-type'];
      expect(contentType, isNotNull);
      expect(contentType, startsWith('multipart/form-data; boundary='));

      final bodyBytes = capturedRequest!.body;
      expect(bodyBytes, isA<List<int>>());
      final bodyText = utf8.decode(bodyBytes! as List<int>);
      expect(bodyText, contains('name="file"; filename="audio.mp3"'));
      expect(bodyText, contains('Content-Type: audio/mpeg'));
      expect(bodyText, contains('name="model_id"'));
      expect(bodyText, contains('scribe_v1'));
      expect(bodyText, contains('name="language_code"'));
      expect(bodyText, contains('name="tag_audio_events"'));
      expect(bodyText, contains('name="num_speakers"'));
      expect(bodyText, contains('name="timestamps_granularity"'));
      expect(bodyText, contains('character'));
      expect(bodyText, contains('name="diarize"'));
      expect(bodyText, contains('name="file_format"'));
      expect(bodyText, contains('pcm_s16le_16'));

      expect(result.text, 'hello world');
      expect(result.language, 'en');
      expect(result.durationSeconds, 0.5);
      expect(result.warnings, isEmpty);
      expect(result.segments, hasLength(1));
      expect(result.segments.first.text, 'hello');
      expect(result.segments.first.startSeconds, 0.0);
      expect(result.segments.first.endSeconds, 0.5);
      expect(result.responseMetadata, isNotNull);
      expect(result.responseMetadata!.modelId, 'scribe_v1');
      expect(result.responseMetadata!.timestamp, isA<DateTime>());
      expect(
        result.responseMetadata!.headers,
        containsPair('x-request-id', 'req_456'),
      );
      expect(
        result.providerMetadata?.namespace('elevenlabs'),
        {
          'requestId': 'req_456',
          'languageCode': 'en',
          'languageProbability': 0.98,
          'words': [
            {
              'text': 'hello',
              'type': 'word',
              'start': 0.0,
              'end': 0.5,
            },
          ],
          'additionalFormats': {
            'segments': [
              {
                'text': 'hello world',
              },
            ],
          },
        },
      );
    });

    test('transcription model rejects incompatible provider options', () async {
      final model = ElevenLabs(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).transcriptionModel('scribe_v1');

      await expectLater(
        () => transcribe(
          model: model,
          audioBytes: utf8.encode('abc'),
          mediaType: 'audio/mpeg',
          callOptions: const CallOptions(
            providerOptions: ElevenLabsSpeechOptions(),
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('Expected ElevenLabsTranscriptionOptions'),
          ),
        ),
      );
    });

    test('transcription response accepts string JSON bodies', () async {
      final model = ElevenLabs(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (_) async => const TransportResponse(
            statusCode: 200,
            body: '{"text":"hello","language_code":"en"}',
          ),
        ),
      ).transcriptionModel('scribe_v1');

      final result = await transcribe(
        model: model,
        audioBytes: utf8.encode('abc'),
        mediaType: 'audio/mpeg',
      );

      expect(result.text, 'hello');
      expect(result.language, 'en');
    });

    test('transcription response rejects non-object JSON bodies', () async {
      final model = ElevenLabs(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (_) async => const TransportResponse(
            statusCode: 200,
            body: '[]',
          ),
        ),
      ).transcriptionModel('scribe_v1');

      await expectLater(
        () => transcribe(
          model: model,
          audioBytes: utf8.encode('abc'),
          mediaType: 'audio/mpeg',
        ),
        throwsA(
          isA<TransportResponseFormatException>().having(
            (error) => error.message,
            'message',
            contains(
                'ElevenLabs transcription API returned JSON that is not an object'),
          ),
        ),
      );
    });
  });
}

typedef _FakeTransportClient = FakeTransportClient;
