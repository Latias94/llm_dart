import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as anthropic_pkg;
import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart' as elevenlabs_pkg;
import 'package:llm_dart_google/llm_dart_google.dart' as google_pkg;
import 'package:llm_dart_ollama/llm_dart_ollama.dart' as ollama_pkg;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_pkg;
import 'package:test/test.dart';

void main() {
  group('ProviderRegistry concrete facades', () {
    test('registers root provider facades for dynamic model lookup', () {
      final registry = ProviderRegistry(
        providers: {
          'anthropic': anthropic_pkg.anthropic(apiKey: 'test-key'),
          'elevenlabs': elevenlabs_pkg.elevenLabs(apiKey: 'test-key'),
          'google': google_pkg.google(apiKey: 'test-key'),
          'ollama': ollama_pkg.ollama(),
          'openai': openai_pkg.openai(apiKey: 'test-key'),
          'openrouter': openai_pkg.openRouter(apiKey: 'test-key'),
        },
      );

      expect(registry.providerIds, [
        'anthropic',
        'elevenlabs',
        'google',
        'ollama',
        'openai',
        'openrouter',
      ]);
      expect(registry.languageProviderIds, [
        'anthropic',
        'google',
        'ollama',
        'openai',
        'openrouter',
      ]);
      expect(
        registry.embeddingProviderIds,
        ['google', 'ollama', 'openai'],
      );
      expect(registry.imageProviderIds, ['google', 'openai']);
      expect(
        registry.speechProviderIds,
        ['elevenlabs', 'google', 'openai'],
      );
      expect(
        registry.transcriptionProviderIds,
        ['elevenlabs', 'openai'],
      );

      expect(
        registry.languageModel('anthropic:claude-sonnet-4-5').providerId,
        'anthropic',
      );
      expect(
        registry.languageModel('openrouter:openai/gpt-4o-mini').providerId,
        'openrouter',
      );
      expect(
        registry.embeddingModel('google:text-embedding-004').providerId,
        'google',
      );
      expect(
        () => registry.embeddingModel('openrouter:text-embedding-3-small'),
        throwsUnsupportedError,
      );
      expect(registry.imageModel('openai:gpt-image-1').providerId, 'openai');
      expect(
        registry.speechModel('elevenlabs:eleven_multilingual_v2').providerId,
        'elevenlabs',
      );
      expect(
        registry.transcriptionModel('elevenlabs:scribe_v1').providerId,
        'elevenlabs',
      );
    });

    test('preserves typed provider settings on direct provider facades', () {
      final provider = google_pkg.google(apiKey: 'test-key');
      final model = provider.chatModel(
        'gemini-2.5-flash',
        settings: const google_pkg.GoogleChatModelSettings(),
      );

      expect(model.providerId, 'google');
      expect(model.modelId, 'gemini-2.5-flash');
    });
  });
}
