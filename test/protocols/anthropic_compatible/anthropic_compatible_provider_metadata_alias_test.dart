import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:test/test.dart';

import '../../utils/fakes/anthropic_fake_client.dart';

void main() {
  group('Anthropic-compatible providerMetadata alias', () {
    test('emits providerId.messages alias key (AI SDK parity)', () async {
      final config = AnthropicConfig(
        apiKey: 'test-key',
        model: 'claude-3-5-sonnet-latest',
        providerId: 'anthropic',
      );

      final client = FakeAnthropicClient(config);
      client.response = const {
        'id': 'msg_123',
        'model': 'claude-3-5-sonnet-latest',
        'stop_reason': 'end_turn',
        'usage': {
          'input_tokens': 1,
          'output_tokens': 2,
        },
        'content': [
          {'type': 'text', 'text': 'hello'}
        ],
      };

      final chat = AnthropicChat(client, config);
      final response = await chat.chatWithTools(
        [ChatMessage.user('hi')],
        const [],
      );

      final meta = response.providerMetadata;
      expect(meta, isNotNull);
      expect(meta!.containsKey('anthropic'), isTrue);
      expect(meta.containsKey('anthropic.messages'), isTrue);
      expect(meta['anthropic.messages'], equals(meta['anthropic']));
    });
  });
}
