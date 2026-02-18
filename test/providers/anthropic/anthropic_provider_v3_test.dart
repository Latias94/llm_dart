import 'package:llm_dart_anthropic/anthropic.dart';
import 'package:llm_dart_anthropic_compatible/config.dart';
import 'package:test/test.dart';

import '../../utils/fakes/anthropic_fake_client.dart';

void main() {
  group('Anthropic ProviderV3 factory', () {
    test('creates a v3 provider and language models are per-model', () {
      final claude = createAnthropic(
        apiKey: 'test-key',
        baseUrl: 'https://example.com/v1/',
      );

      expect(claude.specificationVersion, equals('v3'));

      final model = claude('claude-sonnet-4-20250514');
      expect(model, isA<AnthropicProvider>());
      expect(model.config.model, equals('claude-sonnet-4-20250514'));
      expect(model.config.baseUrl, equals('https://example.com/v1'));
    });

    test('supports providerFactory override for tests', () {
      FakeAnthropicClient? lastClient;

      final claude = createAnthropic(
        apiKey: 'test-key',
        baseUrl: 'https://example.com/v1/',
        providerFactory: (AnthropicConfig config) {
          final client = FakeAnthropicClient(config);
          lastClient = client;
          return AnthropicProvider(config, client: client);
        },
      );

      final model = claude('claude-3-haiku-20240307');
      expect(model, isA<AnthropicProvider>());
      expect(lastClient, isNotNull);
    });
  });
}
