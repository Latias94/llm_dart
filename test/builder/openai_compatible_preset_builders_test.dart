import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI-compatible preset builders', () {
    test('deepinfraOpenAI registers preset and writes providerOptions', () {
      final builder = ai().deepinfraOpenAI(
        (openaiCompatible) => openaiCompatible
            .endpointPrefix('openai')
            .queryParams(const {'foo': 'bar'})
            .headers(const {'X-Test': '1'})
            .includeUsage(true)
            .supportsStructuredOutputs(false),
      );

      expect(builder.providerId, equals('deepinfra-openai'));
      expect(builder.currentConfig.baseUrl,
          equals('https://api.deepinfra.com/v1/'));
      expect(
        builder.currentConfig.model,
        equals('meta-llama/Meta-Llama-3.1-8B-Instruct'),
      );

      expect(
        builder.currentConfig.getProviderOption<String>(
          'deepinfra-openai',
          'endpointPrefix',
        ),
        equals('openai'),
      );
      expect(
        builder.currentConfig.getProviderOption<Map<String, dynamic>>(
          'deepinfra-openai',
          'queryParams',
        ),
        equals(const {'foo': 'bar'}),
      );
      expect(
        builder.currentConfig.getProviderOption<Map<String, dynamic>>(
          'deepinfra-openai',
          'headers',
        ),
        equals(const {'X-Test': '1'}),
      );
      expect(
        builder.currentConfig.getProviderOption<bool>(
          'deepinfra-openai',
          'includeUsage',
        ),
        isTrue,
      );
      expect(
        builder.currentConfig.getProviderOption<bool>(
          'deepinfra-openai',
          'supportsStructuredOutputs',
        ),
        isFalse,
      );
    });

    test('vercelV0 selects preset', () {
      final builder = ai().vercelV0();
      expect(builder.providerId, equals('vercel-v0'));
      expect(builder.currentConfig.baseUrl, equals('https://api.v0.dev/v1/'));
      expect(builder.currentConfig.model, equals('v0-1.5-md'));
    });
  });
}
