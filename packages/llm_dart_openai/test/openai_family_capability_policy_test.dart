import 'package:llm_dart_openai/src/provider/openai_family_capability_core.dart';
import 'package:llm_dart_openai/src/provider/openai_family_profile.dart';
import 'package:llm_dart_openai/src/provider/openai_model_capabilities.dart';
import 'package:llm_dart_openai/src/provider/openai_model_settings.dart';
import 'package:llm_dart_openai/src/provider/openrouter_options.dart';
import 'package:llm_dart_openai/src/provider/resolved_openai_chat_settings.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI-family capability policy', () {
    test('describes DeepSeek reasoner provider-native reasoning', () {
      final policy = const DeepSeekProfile().capabilityPolicy;
      final input = _input(
        modelId: 'deepseek-reasoner',
        usesResponsesApi: false,
      );

      expect(
        policy.sharedLanguageFeatures(input).map((feature) => feature.id),
        contains(ModelCapabilityFeatureIds.languageReasoningOutput),
      );
      expect(
        policy
            .providerLanguageFeatures(providerId: 'deepseek', input: input)
            .map((feature) => feature.featureId),
        ['deepseek.thinkTagReasoning'],
      );
    });

    test('describes OpenRouter online routing from resolved settings', () {
      final policy = const OpenRouterProfile().capabilityPolicy;
      final features = policy.providerLanguageFeatures(
        providerId: 'openrouter',
        input: _input(
          modelId: 'openai/gpt-4o-mini',
          settings: const ResolvedOpenAIChatModelSettings(
            common: OpenAIChatModelSettings(),
            openRouterSearch: OpenRouterSearchOptions.onlineModel(),
          ),
        ),
      );

      expect(features.single.featureId, 'openrouter.onlineModelRouting');
      expect(features.single.detail, {'mode': 'onlineModel'});
    });

    test('describes xAI live search and shared source output', () {
      final policy = const XAIProfile().capabilityPolicy;
      final input = _input(modelId: 'grok-3');

      expect(
        policy.sharedLanguageFeatures(input).map((feature) => feature.id),
        contains(ModelCapabilityFeatureIds.languageSourceOutput),
      );
      expect(
        policy
            .providerLanguageFeatures(providerId: 'xai', input: input)
            .single
            .detail,
        {'resultSurface': 'sources'},
      );
    });
  });
}

OpenAIFamilyCapabilityInput _input({
  required String modelId,
  bool usesResponsesApi = true,
  ResolvedOpenAIChatModelSettings settings =
      const ResolvedOpenAIChatModelSettings(
    common: OpenAIChatModelSettings(),
  ),
}) {
  return OpenAIFamilyCapabilityInput(
    modelId: modelId,
    modelCapabilities: getOpenAIModelCapabilities(modelId),
    usesResponsesApi: usesResponsesApi,
    resolvedSettings: settings,
  );
}
