import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_deepseek/deepseek.dart';
import 'package:llm_dart_deepseek/provider.dart';
import 'package:test/test.dart';

void main() {
  group('DeepSeek ProviderV3 factory', () {
    test('creates a v3 provider and language models are per-model', () {
      final provider = createDeepSeek(
        apiKey: 'test-key',
        headers: const {'X-Test': '1'},
      );

      expect(provider.specificationVersion, equals('v3'));

      final model = provider('deepseek-chat');
      expect(model, isA<ChatCapability>());
      expect(model, isA<DeepSeekProvider>());

      final cfg = (model as DeepSeekProvider).config;
      expect(cfg.model, equals('deepseek-chat'));
      expect(cfg.baseUrl, equals('https://api.deepseek.com'));

      final options = cfg.originalConfig?.providerOptions['deepseek'];
      expect(options, isNotNull);
      expect(options!['headers'], equals(const {'X-Test': '1'}));
    });

    test('baseUrl is normalized (no trailing slash)', () {
      final provider = createDeepSeek(
        apiKey: 'test-key',
        baseUrl: 'https://example.com/api/',
      );

      final model = provider('deepseek-reasoner') as DeepSeekProvider;
      expect(model.config.baseUrl, equals('https://example.com/api'));
    });
  });
}

