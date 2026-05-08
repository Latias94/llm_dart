import 'package:llm_dart/ai.dart' as modern;
import 'package:llm_dart/anthropic.dart' as anthropic_entry;
import 'package:llm_dart/google.dart' as google_entry;
import 'package:llm_dart/openai.dart' as openai_entry;
import 'package:test/test.dart';

void main() {
  group('Modern Root Facade', () {
    test('AI facade creates refactored OpenAI, Google, and Anthropic models',
        () {
      final openaiModel =
          modern.AI.openai(apiKey: 'test-key').chatModel('gpt-5-mini');
      final googleModel =
          modern.AI.google(apiKey: 'test-key').chatModel('gemini-2.5-flash');
      final anthropicModel = modern.AI
          .anthropic(apiKey: 'test-key')
          .chatModel('claude-sonnet-4-5');
      final shortcutModel =
          modern.openai(apiKey: 'test-key').chatModel('gpt-5-mini');

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

    test('AI facade exposes OpenAI-family profile convenience constructors',
        () {
      final openRouterProvider = modern.AI.openRouter(apiKey: 'test-key');
      final deepSeekProvider = modern.AI.deepSeek(apiKey: 'test-key');
      final groqProvider = modern.AI.groq(apiKey: 'test-key');
      final xaiProvider = modern.AI.xai(apiKey: 'test-key');
      final phindProvider = modern.AI.phind(apiKey: 'test-key');
      final openRouterShortcut = modern.openRouter(apiKey: 'test-key');
      final deepSeekShortcut = modern.deepSeek(apiKey: 'test-key');
      final groqShortcut = modern.groq(apiKey: 'test-key');
      final xaiShortcut = modern.xai(apiKey: 'test-key');
      final phindShortcut = modern.phind(apiKey: 'test-key');

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
