import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_family_profile.dart';
import 'openai_model_capabilities.dart';
import 'openrouter_options.dart';
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

OpenAIFamilyCapabilityPolicy openAIFamilyCapabilityPolicyFor(
  OpenAIFamilyProfile profile,
) {
  return switch (profile) {
    OpenAIProfile() => const _OpenAICapabilityPolicy(),
    DeepSeekProfile() => const _DeepSeekCapabilityPolicy(),
    OpenRouterProfile() => const _OpenRouterCapabilityPolicy(),
    XAIProfile() => const _XAICapabilityPolicy(),
    _ => const _CompatibleCapabilityPolicy(),
  };
}

class _OpenAICapabilityPolicy extends OpenAIFamilyCapabilityPolicy {
  const _OpenAICapabilityPolicy();

  @override
  CapabilityConfidence get sharedFeatureConfidence =>
      CapabilityConfidence.known;
}

class _CompatibleCapabilityPolicy extends OpenAIFamilyCapabilityPolicy {
  const _CompatibleCapabilityPolicy();

  @override
  CapabilityConfidence get sharedFeatureConfidence =>
      CapabilityConfidence.inferred;
}

final class _DeepSeekCapabilityPolicy extends _CompatibleCapabilityPolicy {
  const _DeepSeekCapabilityPolicy();

  @override
  Iterable<CapabilityDescriptor> sharedLanguageFeatures(
    OpenAIFamilyCapabilityInput input,
  ) sync* {
    yield* super.sharedLanguageFeatures(input);

    if (_looksLikeDeepSeekReasoningModel(input.modelId) &&
        !input.usesResponsesApi) {
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

    if (_looksLikeDeepSeekReasoningModel(input.modelId) &&
        !input.usesResponsesApi) {
      yield ProviderFeatureDescriptor(
        providerId: providerId,
        featureId: 'deepseek.thinkTagReasoning',
        confidence: CapabilityConfidence.inferred,
      );
    }
  }

  bool _looksLikeDeepSeekReasoningModel(String modelId) {
    return modelId.contains('reasoner');
  }
}

final class _OpenRouterCapabilityPolicy extends _CompatibleCapabilityPolicy {
  const _OpenRouterCapabilityPolicy();

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

final class _XAICapabilityPolicy extends _CompatibleCapabilityPolicy {
  const _XAICapabilityPolicy();

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
