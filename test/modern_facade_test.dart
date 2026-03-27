import 'package:llm_dart/ai.dart' as modern;
import 'package:llm_dart/anthropic.dart' as anthropic_entry;
import 'package:llm_dart/flutter.dart' as flutter_entry;
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

      expect(openaiModel, isA<openai_entry.OpenAILanguageModel>());
      expect(openaiModel.providerId, 'openai');
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
      final openaiProvider = openai_entry.AI.openai(
        apiKey: 'test-key',
        profile: profile,
      );
      final googleProvider = google_entry.AI.google(apiKey: 'test-key');
      final anthropicProvider =
          anthropic_entry.AI.anthropic(apiKey: 'test-key');

      expect(profile.providerId, 'openai');
      expect(openaiProvider, isA<openai_entry.OpenAI>());
      expect(googleProvider, isA<google_entry.Google>());
      expect(anthropicProvider, isA<anthropic_entry.Anthropic>());
    });

    test('flutter entrypoint can compose with the new root facade', () {
      final transport = flutter_entry.DirectChatTransport(
        model: modern.AI.openai(apiKey: 'test-key').chatModel('gpt-5-mini'),
      );

      expect(transport, isA<flutter_entry.DirectChatTransport>());
    });
  });
}
