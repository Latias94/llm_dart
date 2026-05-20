import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_family_capability_core.dart';

final class DeepSeekCapabilityPolicy extends CompatibleOpenAICapabilityPolicy {
  const DeepSeekCapabilityPolicy();

  @override
  Iterable<CapabilityDescriptor> sharedLanguageFeatures(
    OpenAIFamilyCapabilityInput input,
  ) sync* {
    yield* super.sharedLanguageFeatures(input);

    if (_looksLikeReasoningModel(input.modelId) && !input.usesResponsesApi) {
      yield const CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.languageReasoningOutput,
        confidence: CapabilityConfidence.inferred,
      );
    }
  }

  @override
  Iterable<ProviderFeatureDescriptor> providerLanguageFeatures({
    required String providerId,
    required OpenAIFamilyCapabilityInput input,
  }) sync* {
    yield* super.providerLanguageFeatures(
      providerId: providerId,
      input: input,
    );

    if (_looksLikeReasoningModel(input.modelId) && !input.usesResponsesApi) {
      yield ProviderFeatureDescriptor(
        providerId: providerId,
        featureId: 'deepseek.thinkTagReasoning',
        confidence: CapabilityConfidence.inferred,
      );
    }
  }

  bool _looksLikeReasoningModel(String modelId) {
    return modelId.contains('reasoner');
  }
}
