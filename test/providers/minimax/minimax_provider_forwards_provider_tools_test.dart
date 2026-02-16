import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_minimax/llm_dart_minimax.dart';
import 'package:test/test.dart';

import '../../utils/fakes/anthropic_fake_client.dart';

void main() {
  group('MinimaxProvider forwards providerTools', () {
    test('passes providerTools to Anthropic-compatible request builder',
        () async {
      final config = AnthropicConfig.fromLLMConfig(
        const LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.minimax.io/anthropic/v1/',
          model: 'minimax-test-model',
        ),
        providerOptionsNamespace: 'minimax',
      );

      final client = FakeAnthropicClient(config)
        ..response = {
          'id': 'msg_1',
          'model': config.model,
          'content': [
            {'type': 'text', 'text': 'ok'}
          ],
          'stop_reason': 'end_turn',
          'usage': const {'input_tokens': 1, 'output_tokens': 1},
        };

      final provider = MinimaxProvider(config, client: client);

      await provider.chatPrompt(
        Prompt(
          messages: [
            PromptMessage(
              role: PromptRole.user,
              parts: [const TextPart('hi')],
            ),
          ],
        ),
        providerTools: [
          AnthropicProviderTools.webSearch(),
        ],
      );

      final tools = client.lastBody?['tools'] as List?;
      expect(tools, isNotNull);
      expect(
        tools!.any((t) => t is Map && t['name'] == 'web_search'),
        isTrue,
      );
    });
  });
}
