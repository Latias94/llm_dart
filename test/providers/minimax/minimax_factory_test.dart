import 'package:test/test.dart';
import 'package:llm_dart_minimax/llm_dart_minimax.dart';
import 'package:llm_dart_anthropic_compatible/client.dart';
import 'package:llm_dart_anthropic_compatible/dio_strategy.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

void main() {
  group('MinimaxProviderFactory', () {
    test('default config uses Vercel-style baseUrl', () {
      final factory = MinimaxProviderFactory();
      final config = factory.getDefaultConfig();
      expect(config.baseUrl, equals(minimaxAnthropicV1BaseUrl));
      expect(config.model, equals(minimaxDefaultModel));
    });

    test('normalizes baseUrl ending with /anthropic', () {
      final factory = MinimaxProviderFactory();

      final provider = factory.create(
        const LLMConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.minimax.io/anthropic',
          model: minimaxDefaultModel,
        ),
      );

      expect(provider, isA<MinimaxProvider>());
      final minimax = provider as MinimaxProvider;
      expect(
        minimax.config.baseUrl,
        equals('https://api.minimax.io/anthropic/v1/'),
      );
    });

    test('reads providerOptions from minimax namespace first', () {
      final factory = MinimaxProviderFactory();

      final provider = factory.create(
        const LLMConfig(
          apiKey: 'test-key',
          baseUrl: minimaxAnthropicBaseUrl,
          model: minimaxDefaultModel,
          providerOptions: {
            'minimax': {
              'cacheControl': {'type': 'ephemeral', 'ttl': '1h'},
              'extraBody': {'foo': 'bar'},
              'extraHeaders': {'x-test': '1'},
            },
          },
        ),
      );

      final minimax = provider as MinimaxProvider;
      final client = AnthropicClient(
        minimax.config,
        strategy: AnthropicDioStrategy(providerName: 'MiniMax'),
      );
      expect(
        minimax.config.baseUrl,
        equals('https://api.minimax.io/anthropic/v1/'),
      );
      expect(
        client.dio.options.headers['x-api-key'],
        equals('test-key'),
      );
      expect(
        client.dio.options.headers['anthropic-version'],
        equals('2023-06-01'),
      );
      expect(
        minimax.config.cacheControl,
        equals({'type': 'ephemeral', 'ttl': '1h'}),
      );
      expect(minimax.config.extraBody, equals({'foo': 'bar'}));
      expect(minimax.config.extraHeaders, equals({'x-test': '1'}));
      expect(client.dio.options.headers['x-test'], equals('1'));
    });
  });
}
