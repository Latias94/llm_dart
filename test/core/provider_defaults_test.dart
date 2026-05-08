import 'package:llm_dart/core/provider_defaults.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderDefaults', () {
    test('keeps coarse endpoint and model defaults for generic endpoints', () {
      expect(
        ProviderDefaults.getDefaults('openrouter'),
        containsPair('baseUrl', ProviderDefaults.openRouterBaseUrl),
      );
      expect(
        ProviderDefaults.getDefaults('github-copilot'),
        containsPair('model', ProviderDefaults.githubCopilotDefaultModel),
      );
      expect(
        ProviderDefaults.getDefaults('together-ai'),
        containsPair('baseUrl', ProviderDefaults.togetherAIBaseUrl),
      );
    });
  });
}
