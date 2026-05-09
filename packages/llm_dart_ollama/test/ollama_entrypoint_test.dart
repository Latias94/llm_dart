import 'package:llm_dart_ollama/llm_dart_ollama.dart' as ollama_pkg;
import 'package:test/test.dart';

void main() {
  group('Ollama package entrypoint', () {
    test('exposes short factory and model constructors', () {
      final provider = ollama_pkg.ollama();
      final chatModel = provider.chatModel('llama3.2');
      final embeddingModel = provider.embeddingModel('nomic-embed-text');

      expect(provider, isA<ollama_pkg.Ollama>());
      expect(chatModel.providerId, 'ollama');
      expect(embeddingModel.providerId, 'ollama');
    });
  });
}
