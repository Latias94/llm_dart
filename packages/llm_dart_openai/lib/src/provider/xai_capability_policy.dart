import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_family_capability_core.dart';

final class XAICapabilityPolicy extends CompatibleOpenAICapabilityPolicy {
  const XAICapabilityPolicy();

  @override
  Iterable<CapabilityDescriptor> sharedLanguageFeatures(
    OpenAIFamilyCapabilityInput input,
  ) sync* {
    yield* super.sharedLanguageFeatures(input);
    yield const CapabilityDescriptor(
      id: ModelCapabilityFeatureIds.languageSourceOutput,
    );
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

    yield ProviderFeatureDescriptor(
      providerId: providerId,
      featureId: 'xai.liveSearch',
      detail: {
        'resultSurface': 'sources',
      },
    );
  }
}
