import 'package:llm_dart/core/provider_defaults.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderDefaults compatibility exports', () {
    test(
        'should expose legacy OpenAI-compatible defaults through the stable path',
        () {
      final config = OpenAICompatibleDefaults.getConfig('openrouter');

      expect(config, isNotNull);
      expect(config!['providerId'], equals('openrouter'));
      expect(config['baseUrl'], equals(ProviderDefaults.openRouterBaseUrl));
    });
  });
}
