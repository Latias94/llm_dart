import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;
import 'package:test/test.dart';

void main() {
  group('OpenAI-family package entrypoints', () {
    test('xAI entrypoint exposes xAI facade and typed options', () {
      final provider = openai.xai(apiKey: 'test-key');
      final model = provider.chatModel(
        'grok-3',
        settings: const openai.OpenAIChatModelSettings(
          headers: {'X-Test': 'xai'},
        ),
      );
      const options = openai.XAIGenerateTextOptions(
        search: openai.XAILiveSearchOptions.autoWeb(maxSearchResults: 4),
      );

      expect(provider.profile, isA<openai.XAIProfile>());
      expect(model.providerId, 'xai');
      expect(options.search?.maxSearchResults, 4);
    });

    test('DeepSeek entrypoint exposes DeepSeek facade and typed options', () {
      final provider = openai.deepSeek(apiKey: 'test-key');
      final model = provider.chatModel(
        'deepseek-reasoner',
        settings: const openai.OpenAIChatModelSettings(
          headers: {'X-Test': 'deepseek'},
        ),
      );
      const options = openai.DeepSeekGenerateTextOptions(
        logprobs: true,
        topLogprobs: 3,
      );

      expect(provider.profile, isA<openai.DeepSeekProfile>());
      expect(model.providerId, 'deepseek');
      expect(options.topLogprobs, 3);
    });

    test('OpenRouter entrypoint exposes OpenRouter facade and typed settings',
        () {
      final provider = openai.openRouter(
        apiKey: 'test-key',
        appReferer: 'https://example.com',
        appTitle: 'Example App',
      );
      final model = provider.chatModel(
        'openai/gpt-4o-mini',
        settings: const openai.OpenRouterChatModelSettings(
          search: openai.OpenRouterSearchOptions.onlineModel(),
        ),
      );
      const options = openai.OpenRouterGenerateTextOptions(
        search: openai.OpenRouterSearchOptions.onlineModel(),
      );

      expect(provider.profile, isA<openai.OpenRouterProfile>());
      expect(model.providerId, 'openrouter');
      expect(
        model.defaultHeaders,
        containsPair('HTTP-Referer', 'https://example.com'),
      );
      expect(
        model.defaultHeaders,
        containsPair('X-OpenRouter-Title', 'Example App'),
      );
      expect(options.search, isA<openai.OpenRouterSearchOptions>());
    });

    test('Groq entrypoint exposes Groq facade and common settings', () {
      final provider = openai.groq(apiKey: 'test-key');
      final model = provider.chatModel(
        'llama-3.3-70b-versatile',
        settings: const openai.OpenAIChatModelSettings(
          headers: {'X-Test': 'groq'},
        ),
      );

      expect(provider.profile, isA<openai.GroqProfile>());
      expect(model.providerId, 'groq');
    });

    test('Phind entrypoint exposes Phind facade and common settings', () {
      final provider = openai.phind(apiKey: 'test-key');
      final model = provider.chatModel(
        'Phind-70B',
        settings: const openai.OpenAIChatModelSettings(
          headers: {'X-Test': 'phind'},
        ),
      );

      expect(provider.profile, isA<openai.PhindProfile>());
      expect(model.providerId, 'phind');
    });
  });
}
