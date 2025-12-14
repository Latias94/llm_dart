import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Ollama registry integration', () {
    test('languageModel resolves via createProviderRegistry', () {
      final ollama = createOllama(
        baseUrl: 'http://localhost:11434',
        name: 'ollama-test',
      );

      final registry = createProviderRegistry({
        'ollama': ollama,
      });

      final model = registry.languageModel('ollama:llama3.2');

      expect(model.providerId, 'ollama-test');
      expect(model.modelId, 'llama3.2');
    });

    test('textEmbeddingModel resolves via createProviderRegistry', () {
      final ollama = createOllama(
        baseUrl: 'http://localhost:11434',
      );

      final registry = createProviderRegistry({
        'ollama': ollama,
      });

      final embedding = registry.textEmbeddingModel('ollama:nomic-embed-text');

      expect(embedding, isA<EmbeddingCapability>());
    });
  });
}
