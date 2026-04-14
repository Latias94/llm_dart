import 'package:llm_dart/models/chat_models.dart';
import 'package:llm_dart/providers/anthropic/models.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic prompt cache models extraction', () {
    test('keeps cache helpers available from the legacy models export path',
        () {
      expect(
        AnthropicCacheTtl.fromString('5m'),
        AnthropicCacheTtl.fiveMinutes,
      );
      expect(
        const AnthropicCacheControl.ephemeral(ttl: '1h').toJson(),
        {
          'type': 'ephemeral',
          'ttl': '1h',
        },
      );
    });

    test('keeps anthropicConfig builder extension behavior unchanged', () {
      final message = MessageBuilder.system()
          .text('System instructions')
          .anthropicConfig(
            (anthropic) => anthropic.cache(ttl: AnthropicCacheTtl.oneHour),
          )
          .build();

      expect(message.content, 'System instructions');

      final anthropicExtension =
          message.extensions['anthropic'] as Map<String, dynamic>;
      final blocks = anthropicExtension['contentBlocks'] as List<dynamic>;

      expect(blocks, [
        {
          'type': 'text',
          'text': '',
          'cache_control': {
            'type': 'ephemeral',
            'ttl': '1h',
          },
        },
      ]);
    });
  });
}
