import 'package:llm_dart/core/openai_compatible_configs.dart';
import 'package:llm_dart/core/provider_defaults.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderDefaults', () {
    test('keeps coarse endpoint and model defaults for dedicated providers',
        () {
      expect(
        ProviderDefaults.getDefaults('openai'),
        containsPair('baseUrl', ProviderDefaults.openaiBaseUrl),
      );
      expect(
        ProviderDefaults.getDefaults('deepseek'),
        containsPair('model', ProviderDefaults.deepseekDefaultModel),
      );
    });

    test('does not own generic OpenAI-compatible endpoint profiles', () {
      expect(
        () => ProviderDefaults.getDefaults('openrouter'),
        throwsArgumentError,
      );

      final togetherAI = OpenAICompatibleConfigs.getConfig('together-ai');
      expect(
          togetherAI?.defaultBaseUrl, equals('https://api.together.xyz/v1/'));
    });
  });
}
