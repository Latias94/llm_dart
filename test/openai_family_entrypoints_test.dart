import 'package:llm_dart/deepseek.dart' as deepseek;
import 'package:llm_dart/groq.dart' as groq;
import 'package:llm_dart/openrouter.dart' as openrouter;
import 'package:llm_dart/phind.dart' as phind;
import 'package:llm_dart/xai.dart' as xai;
import 'package:test/test.dart';

void main() {
  group('OpenAI-family focused entrypoints', () {
    test('xAI entrypoint exposes xAI facade and typed options', () {
      final provider = xai.xai(apiKey: 'test-key');
      final model = provider.chatModel(
        'grok-3',
        settings: const xai.OpenAIChatModelSettings(
          headers: {'X-Test': 'xai'},
        ),
      );
      const options = xai.XAIGenerateTextOptions(
        search: xai.XAILiveSearchOptions.autoWeb(maxSearchResults: 4),
      );

      expect(provider.profile, isA<xai.XAIProfile>());
      expect(model.providerId, 'xai');
      expect(options.search?.maxSearchResults, 4);
    });

    test('DeepSeek entrypoint exposes DeepSeek facade and typed options', () {
      final provider = deepseek.deepSeek(apiKey: 'test-key');
      final model = provider.chatModel(
        'deepseek-reasoner',
        settings: const deepseek.OpenAIChatModelSettings(
          headers: {'X-Test': 'deepseek'},
        ),
      );
      const options = deepseek.DeepSeekGenerateTextOptions(
        logprobs: true,
        topLogprobs: 3,
      );

      expect(provider.profile, isA<deepseek.DeepSeekProfile>());
      expect(model.providerId, 'deepseek');
      expect(options.topLogprobs, 3);
    });

    test('OpenRouter entrypoint exposes OpenRouter facade and typed settings',
        () {
      final provider = openrouter.openRouter(
        apiKey: 'test-key',
        appReferer: 'https://example.com',
        appTitle: 'Example App',
      );
      final model = provider.chatModel(
        'openai/gpt-4o-mini',
        settings: const openrouter.OpenRouterChatModelSettings(
          search: openrouter.OpenRouterSearchOptions.onlineModel(),
        ),
      );
      const options = openrouter.OpenRouterGenerateTextOptions(
        search: openrouter.OpenRouterSearchOptions.onlineModel(),
      );

      expect(provider.profile, isA<openrouter.OpenRouterProfile>());
      expect(model.providerId, 'openrouter');
      expect(
        model.defaultHeaders,
        containsPair('HTTP-Referer', 'https://example.com'),
      );
      expect(
        model.defaultHeaders,
        containsPair('X-OpenRouter-Title', 'Example App'),
      );
      expect(options.search, isA<openrouter.OpenRouterSearchOptions>());
    });

    test('Groq entrypoint exposes Groq facade and common settings', () {
      final provider = groq.groq(apiKey: 'test-key');
      final model = provider.chatModel(
        'llama-3.3-70b-versatile',
        settings: const groq.OpenAIChatModelSettings(
          headers: {'X-Test': 'groq'},
        ),
      );

      expect(provider.profile, isA<groq.GroqProfile>());
      expect(model.providerId, 'groq');
    });

    test('Phind entrypoint exposes Phind facade and common settings', () {
      final provider = phind.phind(apiKey: 'test-key');
      final model = provider.chatModel(
        'Phind-70B',
        settings: const phind.OpenAIChatModelSettings(
          headers: {'X-Test': 'phind'},
        ),
      );

      expect(provider.profile, isA<phind.PhindProfile>());
      expect(model.providerId, 'phind');
    });
  });
}
