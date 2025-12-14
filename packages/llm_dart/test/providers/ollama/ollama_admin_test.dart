import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('OllamaAdmin', () {
    test('should create admin from local factory', () {
      final admin = OllamaAdmin.local(
        baseUrl: 'http://localhost:11434',
        model: 'llama3.2',
      );

      expect(admin.provider, isA<OllamaProvider>());
      expect(admin.provider.config.baseUrl, equals('http://localhost:11434/'));
      expect(admin.provider.config.model, equals('llama3.2'));
    });

    test('should expose listLocalModels API surface', () {
      final admin = OllamaAdmin.local();

      // We only verify that the method exists and returns a Future;
      // actual HTTP interactions are covered by provider-level tests.
      final future = admin.listLocalModels();
      expect(future, isA<Future<List<AIModel>>>());
    });
  });
}
