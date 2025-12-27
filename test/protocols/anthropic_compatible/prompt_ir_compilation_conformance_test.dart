import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_core/prompt/prompt.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic-compatible Prompt IR compilation conformance', () {
    test('applies message cacheControl to last part only', () {
      const config = AnthropicConfig(
        apiKey: 'k',
        model: 'test-model',
        providerId: 'anthropic',
      );
      final builder = AnthropicRequestBuilder(config);

      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: ChatRole.user,
            parts: const [
              TextPart('part1'),
              TextPart('part2'),
            ],
            providerOptions: const {
              'anthropic': {
                'cacheControl': {'type': 'ephemeral', 'ttl': '1h'},
              },
            },
          ),
        ],
      );

      final built = builder.buildRequestFromPrompt(prompt, const [], false);
      final messages = built.body['messages'] as List<dynamic>;
      expect(messages, hasLength(1));

      final message = messages.single as Map<String, dynamic>;
      final content = message['content'] as List<dynamic>;
      expect(content, hasLength(2));

      expect((content.first as Map).containsKey('cache_control'), isFalse);
      expect(
        (content.last as Map)['cache_control'],
        equals({'type': 'ephemeral', 'ttl': '1h'}),
      );
    });
  });
}
