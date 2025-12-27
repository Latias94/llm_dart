import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('AnthropicProviderTools', () {
    test('webSearch creates ProviderTool with stable id', () {
      final tool = AnthropicProviderTools.webSearch(
        toolType: 'web_search_20250305',
        options: const AnthropicWebSearchToolOptions(maxUses: 2),
      );

      expect(tool.id, equals('anthropic.web_search_20250305'));
      expect(tool.options['max_uses'], equals(2));
      expect(tool.options['enabled'], isTrue);
    });

    test('webFetch creates ProviderTool with stable id', () {
      final tool = AnthropicProviderTools.webFetch(
        toolType: 'web_fetch_20250910',
        options: const AnthropicWebFetchToolOptions(maxContentTokens: 64),
      );

      expect(tool.id, equals('anthropic.web_fetch_20250910'));
      expect(tool.options['max_content_tokens'], equals(64));
      expect(tool.options['enabled'], isTrue);
    });
  });
}
