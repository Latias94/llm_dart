import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderRegistry concrete facades', () {
    test('registers root provider facades for dynamic model lookup', () {
      final registry = ProviderRegistry(
        providers: {
          'anthropic': anthropic(apiKey: 'test-key'),
          'elevenlabs': elevenLabs(apiKey: 'test-key'),
          'google': google(apiKey: 'test-key'),
          'ollama': ollama(),
          'openai': openai(apiKey: 'test-key'),
          'openrouter': openRouter(apiKey: 'test-key'),
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
        ['google', 'ollama', 'openai', 'openrouter'],
      );
      expect(registry.imageProviderIds, ['google', 'openai', 'openrouter']);
      expect(
        registry.speechProviderIds,
        ['elevenlabs', 'google', 'openai', 'openrouter'],
      );
      expect(
        registry.transcriptionProviderIds,
        ['elevenlabs', 'openai', 'openrouter'],
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
      final provider = google(apiKey: 'test-key');
      final model = provider.chatModel(
        'gemini-2.5-flash',
        settings: const GoogleChatModelSettings(),
      );

      expect(model.providerId, 'google');
      expect(model.modelId, 'gemini-2.5-flash');
    });
  });
}
