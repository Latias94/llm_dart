import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_model_capabilities.dart';
import 'resolved_openai_chat_settings.dart';

abstract class OpenAIFamilyCapabilityPolicy {
  const OpenAIFamilyCapabilityPolicy();

  CapabilityConfidence get sharedFeatureConfidence;

  Iterable<CapabilityDescriptor> sharedLanguageFeatures(
    OpenAIFamilyCapabilityInput input,
  ) sync* {
    if (input.modelCapabilities.isReasoningModel) {
      yield const CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.languageReasoningOutput,
      );
    }
  }

  Iterable<ProviderFeatureDescriptor> providerLanguageFeatures({
    required String providerId,
    required OpenAIFamilyCapabilityInput input,
  }) sync* {}
}

final class OpenAIFamilyCapabilityInput {
  final String modelId;
  final OpenAIModelCapabilities modelCapabilities;
  final bool usesResponsesApi;
  final ResolvedOpenAIChatModelSettings resolvedSettings;

  const OpenAIFamilyCapabilityInput({
    required this.modelId,
    required this.modelCapabilities,
    required this.usesResponsesApi,
    required this.resolvedSettings,
  });
}

class OpenAICapabilityPolicy extends OpenAIFamilyCapabilityPolicy {
  const OpenAICapabilityPolicy();

  @override
  CapabilityConfidence get sharedFeatureConfidence =>
      CapabilityConfidence.known;
}

class CompatibleOpenAICapabilityPolicy extends OpenAIFamilyCapabilityPolicy {
  const CompatibleOpenAICapabilityPolicy();

  @override
  CapabilityConfidence get sharedFeatureConfidence =>
      CapabilityConfidence.inferred;
}
