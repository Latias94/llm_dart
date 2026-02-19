import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic providerTools web search', () {
    test(
        'enables provider-native web search when providerTools includes anthropic.web_search_*',
        () {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
        providerTools: const [
          ProviderTool(id: 'anthropic.web_search_20250305', name: 'web_search'),
        ],
      );

      final config = AnthropicConfig.fromLLMConfig(llmConfig);

      expect(config.webSearchToolType, isNotNull);
      expect(config.tools, isNull);
    });

    test(
        'does not enable provider-native web search when providerTools.enabled=false',
        () {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
        providerTools: const [
          ProviderTool(
            id: 'anthropic.web_search_20250305',
            name: 'web_search',
            args: {'enabled': false},
          ),
        ],
      );

      final config = AnthropicConfig.fromLLMConfig(llmConfig);

      expect(config.webSearchToolType, isNull);
      expect(config.tools, isNull);
    });
  });
}
