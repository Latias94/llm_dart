import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAITranscriptionModel', () {
    test('OpenAI factory exposes an OpenAI-family transcription model', () {
      final model = OpenAI(
        apiKey: 'test-key',
        profile: const OpenRouterProfile(),
        transport: const _FakeTransportClient(),
      ).transcriptionModel('whisper-1');

      expect(model.providerId, 'openrouter');
      expect(model.baseUrl, 'https://openrouter.ai/api/v1');
      expect(
        model.defaultHeaders,
        {'authorization': 'Bearer test-key'},
      );
    });

    test('transcribe sends multipart data and decodes verbose JSON metadata',
        () async {
      TransportRequest? capturedRequest;
      final cancelToken = TransportCancellation();

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'text': 'hello world',
                'language': 'en',
                'duration': 1.25,
                'words': [
                  {
                    'word': 'hello',
                    'start': 0.0,
                    'end': 0.5,
                  },
                ],
                'segments': [
                  {
                    'id': 0,
                    'start': 0.0,
                    'end': 1.25,
                    'text': 'hello world',
                  },
                ],
              },
            );
          },
        ),
      ).transcriptionModel(
        'whisper-1',
        settings: const OpenAITranscriptionModelSettings(
          organization: 'org_123',
          project: 'proj_456',
          headers: {
            'x-profile': 'transcription',
          },
        ),
      );

      final result = await transcribe(
        model: model,
        audioBytes: utf8.encode('abc'),
        mediaType: 'audio/wav',
        callOptions: CallOptions(
          timeout: const Duration(seconds: 5),
          headers: const {
            'x-request': 'request-header',
          },
          cancellation: cancelToken,
          providerOptions: const OpenAITranscriptionOptions(
            language: 'en',
            prompt: 'Prefer short output.',
            temperature: 0.2,
            responseFormat: OpenAITranscriptionResponseFormat.verboseJson,
            timestampGranularities: [
              OpenAITranscriptionTimestampGranularity.word,
            ],
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.uri.toString(),
          'https://api.openai.com/v1/audio/transcriptions');
      expect(capturedRequest!.method, TransportMethod.post);
      expect(capturedRequest!.responseType, TransportResponseType.json);
      expect(capturedRequest!.timeout, const Duration(seconds: 5));
      expect(identical(capturedRequest!.cancellation, cancelToken), isTrue);
      expect(capturedRequest!.headers['authorization'], 'Bearer test-key');
      expect(capturedRequest!.headers['openai-organization'], 'org_123');
      expect(capturedRequest!.headers['openai-project'], 'proj_456');
      expect(capturedRequest!.headers['x-profile'], 'transcription');
      expect(capturedRequest!.headers['x-request'], 'request-header');
      expect(
        capturedRequest!.headers['accept'],
        'application/json',
      );
      final contentType = capturedRequest!.headers['content-type'];
      expect(contentType, isNotNull);
      expect(contentType, startsWith('multipart/form-data; boundary='));

      final bodyBytes = capturedRequest!.body;
      expect(bodyBytes, isA<List<int>>());
      final bodyText = utf8.decode(bodyBytes! as List<int>);
      expect(bodyText, contains('name="file"; filename="audio.wav"'));
      expect(bodyText, contains('Content-Type: audio/wav'));
      expect(bodyText, contains('name="model"'));
      expect(bodyText, contains('whisper-1'));
      expect(bodyText, contains('name="language"'));
      expect(bodyText, contains('Prefer short output.'));
      expect(bodyText, contains('name="response_format"'));
      expect(bodyText, contains('verbose_json'));
      expect(bodyText, contains('timestamp_granularities[]'));
      expect(bodyText, contains('word'));

      expect(result.text, 'hello world');
      expect(
        result.providerMetadata?.namespace('openai'),
        {
          'responseFormat': 'verbose_json',
          'language': 'en',
          'durationSeconds': 1.25,
          'words': [
            {
              'word': 'hello',
              'start': 0.0,
              'end': 0.5,
            },
          ],
          'segments': [
            {
              'id': 0,
              'start': 0.0,
              'end': 1.25,
              'text': 'hello world',
            },
          ],
        },
      );
    });

    test('transcribe supports plain text response formats', () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: 'plain transcript',
            );
          },
        ),
      ).transcriptionModel('whisper-1');

      final result = await transcribe(
        model: model,
        audioBytes: utf8.encode('abc'),
        mediaType: 'audio/mpeg',
        callOptions: const CallOptions(
          providerOptions: OpenAITranscriptionOptions(
            responseFormat: OpenAITranscriptionResponseFormat.text,
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.responseType, TransportResponseType.plainText);
      expect(capturedRequest!.headers['accept'], 'text/plain');
      expect(result.text, 'plain transcript');
      expect(
        result.providerMetadata?.namespace('openai'),
        {
          'responseFormat': 'text',
        },
      );
    });

    test(
        'transcription model rejects timestamp granularities without verbose JSON',
        () async {
      final model = OpenAI(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).transcriptionModel('whisper-1');

      await expectLater(
        () => transcribe(
          model: model,
          audioBytes: utf8.encode('abc'),
          callOptions: const CallOptions(
            providerOptions: OpenAITranscriptionOptions(
              responseFormat: OpenAITranscriptionResponseFormat.json,
              timestampGranularities: [
                OpenAITranscriptionTimestampGranularity.word,
              ],
            ),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('transcription model rejects incompatible provider options', () async {
      final model = OpenAI(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).transcriptionModel('whisper-1');

      await expectLater(
        () => transcribe(
          model: model,
          audioBytes: utf8.encode('abc'),
          callOptions: const CallOptions(
            providerOptions: OpenAISpeechOptions(),
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('Expected OpenAITranscriptionOptions'),
          ),
        ),
      );
    });
  });
}

typedef _FakeTransportClient = FakeTransportClient;
