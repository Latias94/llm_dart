import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('DeepSeek Vercel-style factory', () {
    test('chat() creates LanguageModel with correct metadata', () {
      final deepseek = createDeepSeek(
        apiKey: 'test-key',
        baseUrl: 'https://api.deepseek.test/v1',
        headers: const {'X-Custom': 'value'},
        name: 'my-deepseek',
        timeout: const Duration(seconds: 25),
      );

      final model = deepseek.chat('deepseek-chat');

      expect(model, isA<LanguageModel>());
      expect(model.providerId, equals('my-deepseek'));
      expect(model.modelId, equals('deepseek-chat'));

      final config = model.config;
      expect(config.apiKey, equals('test-key'));
      expect(config.baseUrl, equals('https://api.deepseek.test/v1/'));
      expect(config.model, equals('deepseek-chat'));
      expect(config.timeout, equals(const Duration(seconds: 25)));

      final headers = config.extensions?[LLMConfigKeys.customHeaders];
      expect(headers, isA<Map<String, String>>());
      expect(headers['X-Custom'], equals('value'));
    });

    test('deepseek() alias forwards to createDeepSeek', () {
      final instance = deepseek(
        apiKey: 'test-key',
        name: 'alias-deepseek',
      );

      final model = instance.chat('deepseek-reasoner');

      expect(model.providerId, equals('alias-deepseek'));
      expect(model.modelId, equals('deepseek-reasoner'));
    });
  });
}
