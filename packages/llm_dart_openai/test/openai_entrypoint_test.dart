import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;
import 'package:test/test.dart';

void main() {
  group('OpenAI package entrypoint', () {
    test('exposes short provider factories without the root package', () {
      final openAIProvider = openai.openai(apiKey: 'test-key');
      final openRouterProvider = openai.openRouter(
        apiKey: 'test-key',
        appReferer: 'https://example.com',
        appTitle: 'Example App',
      );
      final deepSeekProvider = openai.deepSeek(apiKey: 'test-key');
      final groqProvider = openai.groq(apiKey: 'test-key');
      final xaiProvider = openai.xai(apiKey: 'test-key');
      final phindProvider = openai.phind(apiKey: 'test-key');

      expect(openAIProvider.profile, isA<openai.OpenAIProfile>());
      expect(openAIProvider.chatModel('gpt-4.1-mini').providerId, 'openai');

      expect(openRouterProvider.profile, isA<openai.OpenRouterProfile>());
      expect(openRouterProvider.chatModel('openai/gpt-4o-mini').providerId,
          'openrouter');

      expect(deepSeekProvider.profile, isA<openai.DeepSeekProfile>());
      expect(
        deepSeekProvider.chatModel('deepseek-chat').providerId,
        'deepseek',
      );

      expect(groqProvider.profile, isA<openai.GroqProfile>());
      expect(
        groqProvider.chatModel('llama-3.3-70b-versatile').providerId,
        'groq',
      );

      expect(xaiProvider.profile, isA<openai.XAIProfile>());
      expect(xaiProvider.chatModel('grok-3').providerId, 'xai');

      expect(phindProvider.profile, isA<openai.PhindProfile>());
      expect(phindProvider.chatModel('Phind-70B').providerId, 'phind');
    });
  });
}
