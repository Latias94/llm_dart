import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('GoogleEmbeddingModel', () {
    test('Google factory exposes a Google embedding model', () {
      final model = Google(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).embeddingModel('text-embedding-004');

      expect(model.providerId, 'google');
      expect(model.baseUrl, Google.defaultBaseUrl);
    });

    test('embed sends the single embedding request shape', () async {
      TransportRequest? capturedRequest;
      final cancelToken = TransportCancellation();

      final model = Google(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'embedding': {
                  'values': [0.1, 0.2, 0.3],
                },
                'usageMetadata': {
                  'promptTokenCount': 4,
                  'totalTokenCount': 4,
                },
              },
            );
          },
        ),
      ).embeddingModel(
        'text-embedding-004',
        settings: const GoogleEmbeddingModelSettings(
          headers: {
            'x-settings': '1',
          },
        ),
      );

      final result = await embed(
        model: model,
        value: 'hello',
        dimensions: 128,
        callOptions: CallOptions(
          timeout: const Duration(seconds: 5),
          headers: const {
            'x-call': '2',
          },
          cancellation: cancelToken,
          providerOptions: const GoogleEmbedOptions(
            taskType: 'SEMANTIC_SIMILARITY',
            title: 'Ignored for single queries but still provider-owned',
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.uri.toString(),
        'https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent',
      );
      expect(identical(capturedRequest!.cancellation, cancelToken), isTrue);
      expect(capturedRequest!.headers, {
        'x-goog-api-key': 'test-key',
        'content-type': 'application/json',
        'accept': 'application/json',
        'x-settings': '1',
        'x-call': '2',
      });
      expect(
        capturedRequest!.body,
        {
          'content': {
            'parts': [
              {'text': 'hello'},
            ],
          },
          'taskType': 'SEMANTIC_SIMILARITY',
          'title': 'Ignored for single queries but still provider-owned',
          'outputDimensionality': 128,
        },
      );
      expect(result.embedding, [0.1, 0.2, 0.3]);
      expect(result.usage, const UsageStats(inputTokens: 4, totalTokens: 4));
    });

    test('embedMany sends the batch embedding request shape', () async {
      TransportRequest? capturedRequest;

      final model = Google(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'embeddings': [
                  {
                    'embedding': {
                      'values': [0.1, 0.2],
                    },
                  },
                  {
                    'embedding': {
                      'values': [0.3, 0.4],
                    },
                  },
                ],
              },
            );
          },
        ),
      ).embeddingModel('text-embedding-004');

      final result = await embedMany(
        model: model,
        values: const ['hello', 'world'],
        callOptions: const CallOptions(
          providerOptions: GoogleEmbedOptions(
            taskType: 'RETRIEVAL_DOCUMENT',
            title: 'Docs',
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.uri.toString(),
        'https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:batchEmbedContents',
      );
      expect(
        capturedRequest!.body,
        {
          'requests': [
            {
              'model': 'models/text-embedding-004',
              'content': {
                'parts': [
                  {'text': 'hello'},
                ],
              },
              'taskType': 'RETRIEVAL_DOCUMENT',
              'title': 'Docs',
            },
            {
              'model': 'models/text-embedding-004',
              'content': {
                'parts': [
                  {'text': 'world'},
                ],
              },
              'taskType': 'RETRIEVAL_DOCUMENT',
              'title': 'Docs',
            },
          ],
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

    test('embedding model rejects incompatible provider options', () async {
      final model = Google(
        apiKey: 'test-key',
        transport: const _FakeTransportClient(),
      ).embeddingModel('text-embedding-004');

      await expectLater(
        () => embedMany(
          model: model,
          values: const ['hello'],
          callOptions: const CallOptions(
            providerOptions: GoogleGenerateTextOptions(),
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('Expected GoogleEmbedOptions'),
          ),
        ),
      );
    });
  });
}

typedef _FakeTransportClient = FakeTransportClient;
