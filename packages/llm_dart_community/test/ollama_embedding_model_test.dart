import 'package:llm_dart_community/llm_dart_community.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('OllamaEmbeddingModel', () {
    test('Ollama factory exposes an Ollama embedding model', () {
      final model = Ollama(
        transport: const _FakeTransportClient(),
      ).embeddingModel('nomic-embed-text');

      expect(model.providerId, 'ollama');
      expect(model.baseUrl, Ollama.defaultBaseUrl);
    });

    test('embed sends the Ollama embedding request shape', () async {
      TransportRequest? capturedRequest;
      final cancelToken = TransportCancellation();

      final model = Ollama(
        apiKey: 'test-key',
        baseUrl: 'http://localhost:11434/',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'embeddings': [
                  [0.1, 0.2, 0.3],
                ],
                'total_duration': 123,
                'prompt_eval_count': 4,
              },
            );
          },
        ),
      ).embeddingModel(
        'nomic-embed-text',
        settings: const OllamaEmbeddingModelSettings(
          headers: {
            'x-settings': '1',
          },
        ),
      );

      final result = await embed(
        model: model,
        value: 'hello',
        callOptions: CallOptions(
          timeout: const Duration(seconds: 5),
          headers: const {
            'x-call': '2',
          },
          cancellation: cancelToken,
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.uri.toString(),
        'http://localhost:11434/api/embed',
      );
      expect(identical(capturedRequest!.cancellation, cancelToken), isTrue);
      expect(capturedRequest!.headers, {
        'content-type': 'application/json',
        'accept': 'application/json',
        'authorization': 'Bearer test-key',
        'x-settings': '1',
        'x-call': '2',
      });
      expect(
        capturedRequest!.body,
        {
          'model': 'nomic-embed-text',
          'input': ['hello'],
        },
      );
      expect(result.embedding, [0.1, 0.2, 0.3]);
      expect(
        result.providerMetadata?.values['ollama'],
        {
          'totalDurationNanos': 123,
          'promptEvalCount': 4,
        },
      );
    });

    test('embedMany sends multiple inputs in one request', () async {
      TransportRequest? capturedRequest;

      final model = Ollama(
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'embeddings': [
                  [0.1, 0.2],
                  [0.3, 0.4],
                ],
              },
            );
          },
        ),
      ).embeddingModel('nomic-embed-text');

      final result = await embedMany(
        model: model,
        values: const ['hello', 'world'],
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.body,
        {
          'model': 'nomic-embed-text',
          'input': ['hello', 'world'],
        },
      );
      expect(
        result.embeddings,
        [
          [0.1, 0.2],
          [0.3, 0.4],
        ],
      );
    });

    test('embedding model rejects unsupported dimensions', () async {
      final model = Ollama(
        transport: const _FakeTransportClient(),
      ).embeddingModel('nomic-embed-text');

      await expectLater(
        () => embed(
          model: model,
          value: 'hello',
          dimensions: 128,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('do not support overriding output dimensions'),
          ),
        ),
      );
    });
  });
}

typedef _FakeTransportClient = FakeTransportClient;
