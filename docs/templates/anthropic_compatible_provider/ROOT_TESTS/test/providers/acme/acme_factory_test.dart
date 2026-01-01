import 'package:test/test.dart';
import 'package:llm_dart_acme/llm_dart_acme.dart';
import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

void main() {
  group('AcmeProviderFactory', () {
    test('default config uses anthropic/v1 baseUrl', () {
      final factory = AcmeProviderFactory();
      final config = factory.getDefaultConfig();
      expect(config.baseUrl, equals(acmeAnthropicBaseUrl));
      expect(config.model, equals(acmeDefaultModel));
    });

    test('normalizes baseUrl ending with /anthropic', () {
      final factory = AcmeProviderFactory();

      final provider = factory.create(
        const LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.acme.com/anthropic',
          model: acmeDefaultModel,
        ),
      );

      expect(provider, isA<AcmeChat>());
      final anthropicChat = provider as AnthropicChat;
      expect(anthropicChat.config.baseUrl, equals(acmeAnthropicBaseUrl));
    });

    test('reads providerOptions from provider namespace first', () {
      final factory = AcmeProviderFactory();

      final provider = factory.create(
        const LLMConfig(
          apiKey: 'test-key',
          baseUrl: acmeAnthropicBaseUrl,
          model: acmeDefaultModel,
          providerOptions: {
            'acme': {
              'cacheControl': {'type': 'ephemeral', 'ttl': '1h'},
              'extraBody': {'foo': 'bar'},
              'extraHeaders': {'x-test': '1'},
            },
          },
        ),
      );

      final anthropicChat = provider as AnthropicChat;
      expect(
        anthropicChat.config.cacheControl,
        equals({'type': 'ephemeral', 'ttl': '1h'}),
      );
      expect(anthropicChat.config.extraBody, equals({'foo': 'bar'}));
      expect(anthropicChat.config.extraHeaders, equals({'x-test': '1'}));
    });
  });
}
