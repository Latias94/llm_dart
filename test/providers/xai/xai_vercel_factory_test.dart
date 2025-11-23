import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('XAI Vercel-style factory', () {
    test('chat() creates LanguageModel with correct metadata', () {
      final xaiFactory = createXAI(
        apiKey: 'test-key',
        baseUrl: 'https://api.xai.test/v1',
        headers: const {'X-Custom': 'value'},
        timeout: const Duration(seconds: 10),
      );

      final model = xaiFactory.chat('grok-3');

      expect(model, isA<LanguageModel>());
      expect(model.providerId, equals('xai.chat'));
      expect(model.modelId, equals('grok-3'));

      final config = model.config;
      expect(config.apiKey, equals('test-key'));
      expect(config.baseUrl, equals('https://api.xai.test/v1/'));
      expect(config.model, equals('grok-3'));
      expect(config.timeout, equals(const Duration(seconds: 10)));

      final headers = config.extensions[LLMConfigKeys.customHeaders];
      expect(headers, isA<Map<String, String>>());
      expect(headers['X-Custom'], equals('value'));
    });

    test('embedding() creates EmbeddingCapability', () {
      final xaiFactory = createXAI(apiKey: 'test-key');

      final embedding = xaiFactory.embedding('grok-embedding-beta');

      expect(embedding, isA<EmbeddingCapability>());
    });

    test('xai() alias forwards to createXAI', () {
      final instance = xai(apiKey: 'test-key');

      final model = instance.chat('grok-3-mini');

      expect(model.providerId, equals('xai.chat'));
      expect(model.modelId, equals('grok-3-mini'));
    });
  });
}
