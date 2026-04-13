import 'package:llm_dart/providers/anthropic/anthropic.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic provider barrel', () {
    test('exports the focused Anthropic compatibility surface', () {
      const builderType = AnthropicBuilder;

      final provider = AnthropicProvider(
        const AnthropicConfig(
          apiKey: 'test-key',
          model: 'claude-sonnet-4-20250514',
        ),
      );

      expect(builderType, equals(AnthropicBuilder));
      expect(provider, isA<AnthropicProvider>());
      expect(provider.config.model, 'claude-sonnet-4-20250514');
    });
  });
}
