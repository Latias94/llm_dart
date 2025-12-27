import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('LLMBuilder providerTools', () {
    test('providerTools() sets provider-native tools on config', () {
      final builder = LLMBuilder().providerTools(
        const [
          ProviderTool(
            id: 'openai.web_search_preview',
            options: {'search_context_size': 'high'},
          ),
        ],
      );

      expect(builder.currentConfig.providerTools, isNotNull);
      expect(builder.currentConfig.providerTools, hasLength(1));
      expect(
        builder.currentConfig.providerTools!.single.id,
        equals('openai.web_search_preview'),
      );
    });

    test('providerTool() appends provider-native tools', () {
      final builder = LLMBuilder()
          .providerTool(
            const ProviderTool(id: 'openai.web_search_preview'),
          )
          .providerTool(
            const ProviderTool(id: 'openai.file_search'),
          );

      expect(builder.currentConfig.providerTools, hasLength(2));
      expect(
        builder.currentConfig.providerTools!.map((t) => t.id).toList(),
        equals(['openai.web_search_preview', 'openai.file_search']),
      );
    });

    test('providerTools persist when selecting provider via ai()', () {
      final builder = ai()
          .providerTools(
            const [ProviderTool(id: 'openai.web_search_preview')],
          )
          .provider('openai')
          .apiKey('test-key')
          .model('gpt-4o');

      expect(builder.currentConfig.providerTools, hasLength(1));
      expect(builder.currentConfig.providerTools!.single.id,
          equals('openai.web_search_preview'));
    });
  });
}
