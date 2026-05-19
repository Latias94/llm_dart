import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_family_capability_policy.dart';
import 'openai_family_profile.dart';

ModelCapabilityProfile describeOpenAITranscriptionModel(
  String modelId, {
  OpenAIFamilyProfile profile = const OpenAIProfile(),
}) {
  final confidence = _familyFeatureConfidence(profile);

  return ModelCapabilityProfile(
    providerId: profile.providerId,
    modelId: modelId,
    kind: ModelCapabilityKind.transcription,
    sharedFeatures: [
      const CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.transcriptionLanguageHints,
      ),
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.transcriptionTimestamps,
        confidence: confidence,
      ),
    ],
    providerFeatures: [
      ProviderFeatureDescriptor(
        providerId: profile.providerId,
        featureId: 'transcription.providerOptions',
        detail: {
          'supportedOptions': [
            'include',
            'language',
            'prompt',
            'temperature',
            'responseFormat',
            'timestampGranularities',
          ],
        },
        confidence: confidence,
      ),
    ],
  );
}

CapabilityConfidence _familyFeatureConfidence(OpenAIFamilyProfile profile) =>
    openAIFamilyCapabilityPolicyFor(profile).sharedFeatureConfidence;
