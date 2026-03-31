import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAISpeechModel', () {
    test('OpenAI factory exposes an OpenAI-family speech model', () {
      final model = OpenAI(
        apiKey: 'test-key',
        profile: const OpenRouterProfile(),
        transport: const _FakeTransportClient(),
      ).speechModel('gpt-4o-mini-tts');

      expect(model.providerId, 'openrouter');
      expect(model.baseUrl, 'https://openrouter.ai/api/v1');
      expect(
        model.defaultHeaders,
        {'authorization': 'Bearer test-key'},
      );
    });

    test('generateSpeech sends a bytes request and decodes audio output',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              headers: {
                'content-type': 'audio/wav',
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
        callOptions: const CallOptions(
          timeout: Duration(seconds: 5),
          headers: {
            'x-request': 'request-header',
          },
          providerOptions: OpenAISpeechOptions(
            outputFormat: 'wav',
            instructions: 'Speak calmly.',
            speed: 1.1,
            language: 'en',
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.uri.toString(),
          'https://api.openai.com/v1/audio/speech');
      expect(capturedRequest!.method, TransportMethod.post);
      expect(capturedRequest!.responseType, TransportResponseType.bytes);
      expect(capturedRequest!.timeout, const Duration(seconds: 5));
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
          'language': 'en',
        },
      );
      expect(result.audioBytes, [1, 2, 3, 4]);
      expect(result.mediaType, 'audio/wav');
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
