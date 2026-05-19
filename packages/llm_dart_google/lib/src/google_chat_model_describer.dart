import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_language_model_policy.dart';
import 'google_model_settings.dart';

ModelCapabilityProfile describeGoogleChatModel(
  String modelId, {
  GoogleChatModelSettings settings = const GoogleChatModelSettings(),
}) {
  final policy = GoogleLanguageModelPolicy(modelId);
  final familyConfidence = policy.familyConfidence;

  final sharedFeatures = <CapabilityDescriptor>{
    const CapabilityDescriptor(
      id: ModelCapabilityFeatureIds.languageStreaming,
    ),
    const CapabilityDescriptor(
      id: ModelCapabilityFeatureIds.languageTextInput,
    ),
    const CapabilityDescriptor(
      id: ModelCapabilityFeatureIds.languageImageInput,
    ),
    const CapabilityDescriptor(
      id: ModelCapabilityFeatureIds.languageFileInput,
    ),
    const CapabilityDescriptor(
      id: ModelCapabilityFeatureIds.languageFunctionTools,
    ),
    const CapabilityDescriptor(
      id: ModelCapabilityFeatureIds.languageToolChoice,
    ),
  };

  if (policy.isGeminiModel) {
    sharedFeatures.addAll([
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.languageStructuredOutput,
        confidence: familyConfidence,
      ),
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.languageJsonResponseFormat,
        confidence: familyConfidence,
      ),
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.languageReasoningOutput,
        confidence: familyConfidence,
      ),
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.languageSourceOutput,
        confidence: familyConfidence,
      ),
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.languageFileOutput,
        confidence: familyConfidence,
      ),
    ]);
  }

  return ModelCapabilityProfile(
    providerId: 'google',
    modelId: modelId,
    kind: ModelCapabilityKind.language,
    sharedFeatures: sharedFeatures,
    providerFeatures: [
      const ProviderFeatureDescriptor(
        providerId: 'google',
        featureId: 'api.route',
        detail: 'generateContent',
      ),
      ProviderFeatureDescriptor(
        providerId: 'google',
        featureId: 'google.nativeTools',
        detail: {
          'builtInTools': googleNativeToolFamilies,
          'configuredTools': [
            for (final tool in settings.tools) tool.name,
          ],
        },
      ),
      ProviderFeatureDescriptor(
        providerId: 'google',
        featureId: 'google.reasoning',
        detail: {
          'includeThoughts': true,
          'thinkingLevels': googleThinkingLevels,
          'thoughtSignatures': true,
        },
        confidence: familyConfidence,
      ),
      const ProviderFeatureDescriptor(
        providerId: 'google',
        featureId: 'google.cachedContent',
        detail: {
          'requestReference': true,
        },
      ),
      ProviderFeatureDescriptor(
        providerId: 'google',
        featureId: 'google.safetySettings',
        detail: {
          'modelDefaults': settings.safetySettings.length,
        },
      ),
      if (policy.supportsServerSideToolInvocations)
        ProviderFeatureDescriptor(
          providerId: 'google',
          featureId: 'google.serverSideToolInvocations',
          detail: {
            'supported': true,
            'mixedFunctionTools': true,
            'defaultEnabled': settings.includeServerSideToolInvocations,
          },
          confidence: CapabilityConfidence.inferred,
        ),
    ],
  );
}
