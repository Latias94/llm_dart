import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Groq Vercel-style factory', () {
    test('chat() creates LanguageModel with correct metadata', () {
      final groq = createGroq(
        apiKey: 'test-key',
        baseUrl: 'https://api.groq.test/openai/v1',
        headers: const {'X-Custom': 'value'},
        name: 'my-groq',
        timeout: const Duration(seconds: 20),
      );

      final model = groq.chat('llama-3.3-70b-versatile');

      expect(model, isA<LanguageModel>());
      expect(model.providerId, equals('my-groq'));
      expect(model.modelId, equals('llama-3.3-70b-versatile'));

      final config = model.config;
      expect(config.apiKey, equals('test-key'));
      expect(
        config.baseUrl,
        equals('https://api.groq.test/openai/v1/'),
      );
      expect(config.model, equals('llama-3.3-70b-versatile'));
      expect(config.timeout, equals(const Duration(seconds: 20)));

      final headers = config.extensions[LLMConfigKeys.customHeaders];
      expect(headers, isA<Map<String, String>>());
      expect(headers['X-Custom'], equals('value'));
    });

    test('groq() alias forwards to createGroq', () {
      final instance = groq(
        apiKey: 'test-key',
        name: 'alias-groq',
      );

      final model = instance.chat('llama-3.1-8b-instant');

      expect(model.providerId, equals('alias-groq'));
      expect(model.modelId, equals('llama-3.1-8b-instant'));
    });
  });
}
