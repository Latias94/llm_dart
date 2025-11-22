import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic Vercel-style factory', () {
    test('chat() creates LanguageModel with correct metadata', () {
      final anthropic = createAnthropic(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.test/v1',
        headers: const {'X-Custom': 'value'},
        name: 'my-anthropic',
        timeout: const Duration(seconds: 20),
      );

      final model = anthropic.chat('claude-sonnet-4-20250514');

      expect(model, isA<LanguageModel>());
      expect(model.providerId, equals('my-anthropic'));
      expect(
        model.modelId,
        equals('claude-sonnet-4-20250514'),
      );

      final config = model.config;
      expect(config.apiKey, equals('test-key'));
      expect(config.baseUrl, equals('https://api.anthropic.test/v1/'));
      expect(
        config.model,
        equals('claude-sonnet-4-20250514'),
      );
      expect(config.timeout, equals(const Duration(seconds: 20)));

      final headers = config.extensions?[LLMConfigKeys.customHeaders];
      expect(headers, isA<Map<String, String>>());
      expect(headers['X-Custom'], equals('value'));
    });

    test('anthropic() alias forwards to createAnthropic', () {
      final instance = anthropic(
        apiKey: 'test-key',
        name: 'alias-anthropic',
      );

      final model = instance.chat('claude-3-5-sonnet-20241022');

      expect(model.providerId, equals('alias-anthropic'));
      expect(
        model.modelId,
        equals('claude-3-5-sonnet-20241022'),
      );
    });
  });
}
