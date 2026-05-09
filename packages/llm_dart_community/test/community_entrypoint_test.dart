import 'package:llm_dart_community/llm_dart_community.dart' as community;
import 'package:test/test.dart';

void main() {
  group('Community package entrypoint', () {
    test('exposes short Ollama and ElevenLabs factories', () {
      final ollamaProvider = community.ollama();
      final ollamaModel = ollamaProvider.chatModel('llama3.2');
      final embeddingModel = ollamaProvider.embeddingModel('nomic-embed-text');

      final elevenLabsProvider = community.elevenLabs(apiKey: 'test-key');
      final speechModel =
          elevenLabsProvider.speechModel('eleven_multilingual_v2');
      final transcriptionModel =
          elevenLabsProvider.transcriptionModel('scribe_v1');

      expect(ollamaProvider, isA<community.Ollama>());
      expect(ollamaModel.providerId, 'ollama');
      expect(embeddingModel.providerId, 'ollama');
      expect(elevenLabsProvider, isA<community.ElevenLabs>());
      expect(speechModel.providerId, 'elevenlabs');
      expect(transcriptionModel.providerId, 'elevenlabs');
    });
  });
}
