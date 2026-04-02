import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIEmbeddingModel', () {
    test('OpenAI factory exposes an OpenAI-family embedding model', () {
      final model = OpenAI(
        apiKey: 'test-key',
        profile: const OpenRouterProfile(),
        transport: const _FakeTransportClient(),
      ).embeddingModel('openai/text-embedding-3-small');

      expect(model.providerId, 'openrouter');
      expect(model.baseUrl, 'https://openrouter.ai/api/v1');
      expect(
        model.defaultHeaders,
        {'authorization': 'Bearer test-key'},
      );
    });

    test('embedMany sends an embeddings request and decodes the response',
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
                'data': [
                  {
                    'index': 1,
                    'embedding': [0.3, 0.4],
                  },
                  {
                    'index': 0,
                    'embedding': [0.1, 0.2],
                  },
                ],
                'usage': {
                  'prompt_tokens': 5,
                  'total_tokens': 5,
                },
              },
            );
          },
        ),
      ).embeddingModel(
        'text-embedding-3-small',
        settings: const OpenAIEmbeddingModelSettings(
          organization: 'org_123',
          project: 'proj_456',
          headers: {
            'x-profile': 'embedding',
          },
        ),
      );

      final result = await embedMany(
        model: model,
        values: const ['hello', 'world'],
        dimensions: 256,
        callOptions: CallOptions(
          timeout: const Duration(seconds: 5),
          headers: const {
            'x-request': 'request-header',
          },
          cancellation: cancelToken,
          providerOptions: const OpenAIEmbedOptions(
            encodingFormat: 'float',
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.uri.toString(),
          'https://api.openai.com/v1/embeddings');
      expect(capturedRequest!.method, TransportMethod.post);
      expect(capturedRequest!.timeout, const Duration(seconds: 5));
      expect(identical(capturedRequest!.cancellation, cancelToken), isTrue);
      expect(
        capturedRequest!.headers,
        {
          'authorization': 'Bearer test-key',
          'openai-organization': 'org_123',
          'openai-project': 'proj_456',
          'x-profile': 'embedding',
          'content-type': 'application/json',
          'accept': 'application/json',
          'x-request': 'request-header',
        },
      );
      expect(
        capturedRequest!.body,
        {
          'model': 'text-embedding-3-small',
          'input': ['hello', 'world'],
          'dimensions': 256,
          'encoding_format': 'float',
        },
      );

      expect(
        result.embeddings,
        [
          [0.1, 0.2],
          [0.3, 0.4],
        ],
      );
      expect(result.usage, const UsageStats(inputTokens: 5, totalTokens: 5));
    });

    test('embedding model rejects incompatible provider options', () async {
      final model = OpenAI(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).embeddingModel('text-embedding-3-small');

      await expectLater(
        () => embedMany(
          model: model,
          values: const ['hello'],
          callOptions: const CallOptions(
            providerOptions: OpenAIGenerateTextOptions(),
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('Expected OpenAIEmbedOptions'),
          ),
        ),
      );
    });
  });
}

typedef _FakeTransportClient = FakeTransportClient;
