import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('OpenRouter providerOptions web search', () {
    test(
        'does not rewrite model when configured via OpenRouterBuilder.webSearch()',
        () async {
      final provider = await ai()
          .openRouter((openrouter) => openrouter.webSearch())
          .apiKey('test-key')
          .model('anthropic/claude-3.5-sonnet')
          .build();

      final openrouter = provider as OpenAICompatibleChatProvider;
      expect(openrouter.config.model, equals('anthropic/claude-3.5-sonnet'));
      expect(openrouter.config.getProviderOption<bool>('webSearchEnabled'),
          isTrue);
    });

    test('does not rewrite model when providerOptions.webSearchEnabled=true',
        () async {
      final provider = await ai()
          .provider('openrouter')
          .apiKey('test-key')
          .model('anthropic/claude-3.5-sonnet')
          .providerOptions('openrouter', {'webSearchEnabled': true}).build();

      final openrouter = provider as OpenAICompatibleChatProvider;
      expect(openrouter.config.model, equals('anthropic/claude-3.5-sonnet'));
      expect(openrouter.config.getProviderOption<bool>('webSearchEnabled'),
          isTrue);
    });

    test('does not rewrite model when providerOptions.webSearch.enabled=true',
        () async {
      final provider = await ai()
          .provider('openrouter')
          .apiKey('test-key')
          .model('anthropic/claude-3.5-sonnet')
          .providerOptions('openrouter', {
        'webSearch': {'enabled': true},
      }).build();

      final openrouter = provider as OpenAICompatibleChatProvider;
      expect(openrouter.config.model, equals('anthropic/claude-3.5-sonnet'));
      expect(openrouter.config.getProviderOption<dynamic>('webSearch'),
          isA<Map>());
    });

    test('useOnlineShortcut no longer affects model rewriting', () async {
      final provider = await ai()
          .provider('openrouter')
          .apiKey('test-key')
          .model('anthropic/claude-3.5-sonnet')
          .providerOptions('openrouter', {
        'useOnlineShortcut': false,
        'webSearchEnabled': true,
      }).build();

      final openrouter = provider as OpenAICompatibleChatProvider;
      expect(openrouter.config.model, equals('anthropic/claude-3.5-sonnet'));
    });
  });
}
