import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_family_capability_core.dart';
import 'openrouter_options.dart';

final class OpenRouterCapabilityPolicy
    extends CompatibleOpenAICapabilityPolicy {
  const OpenRouterCapabilityPolicy();

  @override
  Iterable<ProviderFeatureDescriptor> providerLanguageFeatures({
    required String providerId,
    required OpenAIFamilyCapabilityInput input,
  }) sync* {
    yield* super.providerLanguageFeatures(
      providerId: providerId,
      input: input,
    );

    final search = input.resolvedSettings.openRouterSearch;
    if (search != null) {
      yield ProviderFeatureDescriptor(
        providerId: providerId,
        featureId: 'openrouter.onlineModelRouting',
        detail: {
          'mode': switch (search.mode) {
            OpenRouterSearchMode.onlineModel => 'onlineModel',
          },
        },
      );
    }
  }
}
