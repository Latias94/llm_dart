import 'package:llm_dart_google/google.dart' show GoogleProvider;
import 'package:llm_dart_google_vertex/llm_dart_google_vertex.dart';
import 'package:test/test.dart';

void main() {
  group('Vertex ProviderV3 factory', () {
    test('creates a v3 provider and language models are per-model', () {
      final v = createVertex(
        apiKey: 'test-key',
        baseUrl: 'https://example.com/v1/publishers/google/',
      );

      expect(v.specificationVersion, equals('v3'));

      final model = v('gemini-2.5-flash');
      expect(model, isA<GoogleProvider>());

      final provider = model as GoogleProvider;
      expect(provider.config.providerId, equals('vertex'));
      expect(provider.config.providerOptionsName, equals('vertex'));
      expect(provider.config.model, equals('gemini-2.5-flash'));
      expect(provider.config.baseUrl, equals('https://example.com/v1/publishers/google'));
    });

    test('vertex(...) is an alias for createVertex(...)', () {
      final v = vertex(apiKey: 'test-key');
      expect(v.specificationVersion, equals('v3'));
    });
  });
}

