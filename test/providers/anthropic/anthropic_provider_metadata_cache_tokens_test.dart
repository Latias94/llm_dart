import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('Anthropic providerMetadata prompt caching usage', () {
    test('surfaces cache_creation_input_tokens and cache_read_input_tokens', () {
      final response = AnthropicChatResponse(
        const {
          'id': 'msg_123',
          'model': 'claude-sonnet-4-20250514',
          'stop_reason': 'end_turn',
          'usage': {
            'input_tokens': 10,
            'output_tokens': 5,
            'cache_creation_input_tokens': 7,
            'cache_read_input_tokens': 3,
          },
        },
        'anthropic',
      );

      final providerMetadata = response.providerMetadata;
      expect(providerMetadata, isNotNull);

      final anthropic = providerMetadata!['anthropic'] as Map<String, dynamic>?;
      expect(anthropic, isNotNull);

      final usage = anthropic!['usage'] as Map<String, dynamic>?;
      expect(usage, isNotNull);

      expect(usage!['cacheCreationInputTokens'], equals(7));
      expect(usage['cacheReadInputTokens'], equals(3));
    });
  });
}

