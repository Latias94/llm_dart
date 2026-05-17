import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAISpeechModel', () {
    test('OpenAI factory exposes an OpenAI-family speech model', () {
      final model = OpenAI(
        apiKey: 'test-key',
        profile: const OpenAIProfile(),
        transport: const _FakeTransportClient(),
      ).speechModel('gpt-4o-mini-tts');

      expect(model.providerId, 'openai');
      expect(model.baseUrl, 'https://api.openai.com/v1');
      expect(
        model.defaultHeaders,
        {'authorization': 'Bearer test-key'},
      );
    });

    test('generateSpeech sends a bytes request and decodes audio output',
        () async {
      TransportRequest? capturedRequest;
      final cancelToken = TransportCancellation();

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              headers: {
                'content-type': 'audio/wav',
                'x-request-id': 'req_speech_1',
              },
              body: [1, 2, 3, 4],
            );
          },
        ),
      ).speechModel(
        'gpt-4o-mini-tts',
        settings: const OpenAISpeechModelSettings(
          organization: 'org_123',
          project: 'proj_456',
          headers: {
            'x-profile': 'speech',
          },
        ),
      );

      final result = await generateSpeech(
        model: model,
        text: 'Hello world.',
        voice: 'alloy',
        callOptions: CallOptions(
          timeout: const Duration(seconds: 5),
          headers: const {
            'x-request': 'request-header',
          },
          cancellation: cancelToken,
          providerOptions: const OpenAISpeechOptions(
            outputFormat: 'wav',
            instructions: 'Speak calmly.',
            speed: 1.1,
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.uri.toString(),
          'https://api.openai.com/v1/audio/speech');
      expect(capturedRequest!.method, TransportMethod.post);
      expect(capturedRequest!.responseType, TransportResponseType.bytes);
      expect(capturedRequest!.timeout, const Duration(seconds: 5));
      expect(identical(capturedRequest!.cancellation, cancelToken), isTrue);
      expect(
        capturedRequest!.headers,
        {
          'authorization': 'Bearer test-key',
          'openai-organization': 'org_123',
          'openai-project': 'proj_456',
          'x-profile': 'speech',
          'content-type': 'application/json',
          'accept': 'application/octet-stream',
          'x-request': 'request-header',
        },
      );
      expect(
        capturedRequest!.body,
        {
          'model': 'gpt-4o-mini-tts',
          'input': 'Hello world.',
          'voice': 'alloy',
          'response_format': 'wav',
          'instructions': 'Speak calmly.',
          'speed': 1.1,
        },
      );
      expect(result.audioBytes, [1, 2, 3, 4]);
      expect(result.mediaType, 'audio/wav');
      expect(result.warnings, isEmpty);
      expect(result.responseMetadata, isNotNull);
      expect(result.responseMetadata!.modelId, 'gpt-4o-mini-tts');
      expect(result.responseMetadata!.timestamp, isA<DateTime>());
      expect(
        result.responseMetadata!.headers,
        containsPair('x-request-id', 'req_speech_1'),
      );
    });

    test('generateSpeech defaults voice and output format for OpenAI',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: [1, 2, 3],
            );
          },
        ),
      ).speechModel('tts-1');

      final result = await generateSpeech(
        model: model,
        text: 'Hello world.',
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.body,
        {
          'model': 'tts-1',
          'input': 'Hello world.',
          'voice': 'alloy',
          'response_format': 'mp3',
        },
      );
      expect(result.mediaType, 'audio/mpeg');
      expect(result.warnings, isEmpty);
    });

    test('generateSpeech warning-drops unsupported language option', () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: [1, 2, 3],
            );
          },
        ),
      ).speechModel('gpt-4o-mini-tts');

      final result = await generateSpeech(
        model: model,
        text: 'Hello world.',
        callOptions: const CallOptions(
          providerOptions: OpenAISpeechOptions(
            language: 'en',
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.body, isNot(containsPair('language', 'en')));
      expect(
        result.warnings,
        [
          const ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'providerOptions.language',
            message:
                'OpenAI speech models do not support language selection. Language parameter "en" was ignored.',
          ),
        ],
      );
    });

    test('generateSpeech falls back to mp3 for unsupported output format',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: [1, 2, 3],
            );
          },
        ),
      ).speechModel('gpt-4o-mini-tts');

      final result = await generateSpeech(
        model: model,
        text: 'Hello world.',
        callOptions: const CallOptions(
          providerOptions: OpenAISpeechOptions(
            outputFormat: 'webm',
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.body,
        containsPair('response_format', 'mp3'),
      );
      expect(result.mediaType, 'audio/mpeg');
      expect(
        result.warnings,
        [
          const ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'providerOptions.outputFormat',
            message:
                'Unsupported OpenAI speech output format: webm. Using mp3 instead.',
          ),
        ],
      );
    });

    test('generateSpeech rejects speed outside OpenAI range', () async {
      final model = OpenAI(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).speechModel('gpt-4o-mini-tts');

      await expectLater(
        () => generateSpeech(
          model: model,
          text: 'Hello world.',
          callOptions: const CallOptions(
            providerOptions: OpenAISpeechOptions(
              speed: 4.1,
            ),
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'providerOptions.speed',
          ),
        ),
      );
    });

    test('speech model rejects incompatible provider options', () async {
      final model = OpenAI(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).speechModel('gpt-4o-mini-tts');

      await expectLater(
        () => generateSpeech(
          model: model,
          text: 'Hello',
          callOptions: const CallOptions(
            providerOptions: OpenAIEmbedOptions(),
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('Expected OpenAISpeechOptions'),
          ),
        ),
      );
    });
  });
}

typedef _FakeTransportClient = FakeTransportClient;
