import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Phind Vercel-style factory', () {
    test('chat() creates LanguageModel with correct metadata', () {
      final phind = createPhind(
        apiKey: 'test-key',
        baseUrl: 'https://api.phind.test/v1',
        headers: const {'X-Custom': 'value'},
        name: 'my-phind',
        timeout: const Duration(seconds: 15),
      );

      final model = phind.chat('Phind-70B');

      expect(model, isA<LanguageModel>());
      expect(model.providerId, equals('my-phind'));
      expect(model.modelId, equals('Phind-70B'));

      final config = model.config;
      expect(config.apiKey, equals('test-key'));
      expect(config.baseUrl, equals('https://api.phind.test/v1/'));
      expect(config.model, equals('Phind-70B'));
      expect(config.timeout, equals(const Duration(seconds: 15)));

      final headers = config.extensions[LLMConfigKeys.customHeaders];
      expect(headers, isA<Map<String, String>>());
      expect(headers['X-Custom'], equals('value'));
    });

    test('phind() alias forwards to createPhind', () {
      final instance = phind(
        apiKey: 'test-key',
        name: 'alias-phind',
      );

      final model = instance.chat('Phind-70B');

      expect(model.providerId, equals('alias-phind'));
      expect(model.modelId, equals('Phind-70B'));
    });
  });
}
