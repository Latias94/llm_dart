import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as anthropic_entry;
import 'package:llm_dart_google/llm_dart_google.dart' as google_entry;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_entry;
import 'package:test/test.dart';

void main() {
  group('Provider-neutral root with direct provider packages', () {
    test('direct provider packages create OpenAI, Google, and Anthropic models',
        () {
      final openaiModel =
          openai_entry.openai(apiKey: 'test-key').chatModel('gpt-5-mini');
      final googleModel =
          google_entry.google(apiKey: 'test-key').chatModel('gemini-2.5-flash');
      final anthropicModel = anthropic_entry
          .anthropic(apiKey: 'test-key')
          .chatModel('claude-sonnet-4-5');
      final shortcutModel =
          openai_entry.openai(apiKey: 'test-key').chatModel('gpt-5-mini');

      expect(openaiModel, isA<openai_entry.OpenAILanguageModel>());
      expect(openaiModel.providerId, 'openai');
      expect(shortcutModel.providerId, openaiModel.providerId);
      expect(googleModel, isA<google_entry.GoogleLanguageModel>());
      expect(googleModel.providerId, 'google');
      expect(
        anthropicModel,
        isA<anthropic_entry.AnthropicLanguageModel>(),
      );
      expect(anthropicModel.providerId, 'anthropic');
    });

    test('provider sub-entrypoints expose refactored package barrels', () {
      final profile = const openai_entry.OpenAIProfile();
      final openaiProvider = openai_entry.OpenAI(
        apiKey: 'test-key',
        profile: const openai_entry.OpenAIProfile(),
      );
      final openaiShortcut = openai_entry.openai(apiKey: 'test-key');
      final googleProvider = google_entry.Google(apiKey: 'test-key');
      final googleShortcut = google_entry.google(apiKey: 'test-key');
      final anthropicProvider = anthropic_entry.Anthropic(apiKey: 'test-key');
      final anthropicShortcut = anthropic_entry.anthropic(apiKey: 'test-key');

      expect(profile.providerId, 'openai');
      expect(openaiProvider, isA<openai_entry.OpenAI>());
      expect(openaiShortcut.profile, isA<openai_entry.OpenAIProfile>());
      expect(googleProvider, isA<google_entry.Google>());
      expect(googleShortcut, isA<google_entry.Google>());
      expect(anthropicProvider, isA<anthropic_entry.Anthropic>());
      expect(anthropicShortcut, isA<anthropic_entry.Anthropic>());
    });

    test(
        'OpenAI package exposes OpenAI-family profile convenience constructors',
        () {
      final openRouterProvider = openai_entry.openRouter(apiKey: 'test-key');
      final deepSeekProvider = openai_entry.deepSeek(apiKey: 'test-key');
      final groqProvider = openai_entry.groq(apiKey: 'test-key');
      final xaiProvider = openai_entry.xai(apiKey: 'test-key');
      final phindProvider = openai_entry.phind(apiKey: 'test-key');
      final openRouterShortcut = openai_entry.openRouter(apiKey: 'test-key');
      final deepSeekShortcut = openai_entry.deepSeek(apiKey: 'test-key');
      final groqShortcut = openai_entry.groq(apiKey: 'test-key');
      final xaiShortcut = openai_entry.xai(apiKey: 'test-key');
      final phindShortcut = openai_entry.phind(apiKey: 'test-key');

      expect(openRouterProvider.profile, isA<openai_entry.OpenRouterProfile>());
      expect(openRouterShortcut.profile, isA<openai_entry.OpenRouterProfile>());
      expect(
        openRouterProvider.baseUrl,
        const openai_entry.OpenRouterProfile().defaultBaseUrl,
      );
      expect(
        openRouterProvider.chatModel('openai/gpt-4o-mini').providerId,
        'openrouter',
      );

      expect(deepSeekProvider.profile, isA<openai_entry.DeepSeekProfile>());
      expect(deepSeekShortcut.profile, isA<openai_entry.DeepSeekProfile>());
      expect(
        deepSeekProvider.baseUrl,
        const openai_entry.DeepSeekProfile().defaultBaseUrl,
      );
      expect(
          deepSeekProvider.chatModel('deepseek-chat').providerId, 'deepseek');

      expect(groqProvider.profile, isA<openai_entry.GroqProfile>());
      expect(groqShortcut.profile, isA<openai_entry.GroqProfile>());
      expect(
        groqProvider.baseUrl,
        const openai_entry.GroqProfile().defaultBaseUrl,
      );
      expect(
          groqProvider.chatModel('llama-3.3-70b-versatile').providerId, 'groq');

      expect(xaiProvider.profile, isA<openai_entry.XAIProfile>());
      expect(xaiShortcut.profile, isA<openai_entry.XAIProfile>());
      expect(
        xaiProvider.baseUrl,
        const openai_entry.XAIProfile().defaultBaseUrl,
      );
      expect(xaiProvider.chatModel('grok-3').providerId, 'xai');

      expect(phindProvider.profile, isA<openai_entry.PhindProfile>());
      expect(phindShortcut.profile, isA<openai_entry.PhindProfile>());
      expect(
        phindProvider.baseUrl,
        const openai_entry.PhindProfile().defaultBaseUrl,
      );
      expect(phindProvider.chatModel('Phind-70B').providerId, 'phind');
    });
  });
}
