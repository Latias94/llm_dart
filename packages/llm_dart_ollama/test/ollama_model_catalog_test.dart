import 'package:llm_dart_ollama/llm_dart_ollama.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('OllamaModelCatalogClient', () {
    test('Ollama factory exposes a model catalog client', () {
      final catalog = Ollama(
        transport: const _FakeTransportClient(),
      ).catalog();

      expect(catalog.baseUrl, Ollama.defaultBaseUrl);
    });

    test('listModels fetches installed tags with typed details', () async {
      TransportRequest? capturedRequest;
      final cancelToken = TransportCancellation();

      final catalog = Ollama(
        apiKey: 'test-key',
        baseUrl: 'http://localhost:11434/',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return const TransportResponse(
              statusCode: 200,
              body: {
                'models': [
                  {
                    'name': 'llama3.2:latest',
                    'modified_at': '2026-04-23T10:00:00Z',
                    'size': 123456789,
                    'digest': 'sha256:abc',
                    'details': {
                      'format': 'gguf',
                      'family': 'llama',
                      'families': ['llama'],
                      'parameter_size': '8B',
                      'quantization_level': 'Q4_K_M',
                    },
                  },
                ],
              },
            );
          },
        ),
      ).catalog(
        settings: const OllamaCatalogSettings(
          headers: {
            'x-settings': '1',
          },
        ),
      );

      final models = await catalog.listModels(
        timeout: const Duration(seconds: 5),
        cancellation: cancelToken,
        headers: const {
          'x-call': '2',
        },
      );

      expect(capturedRequest, isNotNull);
      expect(
          capturedRequest!.uri.toString(), 'http://localhost:11434/api/tags');
      expect(capturedRequest!.method, TransportMethod.get);
      expect(capturedRequest!.responseType, TransportResponseType.json);
      expect(capturedRequest!.timeout, const Duration(seconds: 5));
      expect(identical(capturedRequest!.cancellation, cancelToken), isTrue);
      expect(capturedRequest!.headers, {
        'accept': 'application/json',
        'authorization': 'Bearer test-key',
        'x-settings': '1',
        'x-call': '2',
      });

      expect(models, hasLength(1));
      expect(models.single.name, 'llama3.2:latest');
      expect(models.single.sizeBytes, 123456789);
      expect(models.single.digest, 'sha256:abc');
      expect(
        models.single.modifiedAt,
        DateTime.parse('2026-04-23T10:00:00Z'),
      );
      expect(models.single.details?.family, 'llama');
      expect(models.single.details?.families, ['llama']);
      expect(models.single.details?.parameterSize, '8B');
      expect(models.single.details?.quantizationLevel, 'Q4_K_M');
    });
  });
}

typedef _FakeTransportClient = FakeTransportClient;
