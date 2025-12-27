import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic providerOptions web search', () {
    test(
        'enables provider-native web search when providerOptions.webSearchEnabled=true',
        () {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
        providerOptions: const {
          'anthropic': {
            'webSearchEnabled': true,
          },
        },
      );

      final config = AnthropicConfig.fromLLMConfig(llmConfig);

      expect(config.webSearchToolType, isNotNull);
      expect(config.tools, isNull);
    });

    test(
        'does not add web_search tool when providerOptions.webSearch.enabled=false',
        () {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
        providerOptions: const {
          'anthropic': {
            'webSearch': {
              'enabled': false,
            },
          },
        },
      );

      final config = AnthropicConfig.fromLLMConfig(llmConfig);

      expect(config.webSearchToolType, isNull);
      expect(config.tools, isNull);
    });
  });
}
