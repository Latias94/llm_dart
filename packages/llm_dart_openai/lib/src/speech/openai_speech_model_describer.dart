import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../provider/openai_family_profile.dart';

ModelCapabilityProfile describeOpenAISpeechModel(
  String modelId, {
  OpenAIFamilyProfile profile = const OpenAIProfile(),
}) {
  final confidence = _familyFeatureConfidence(profile);

  return ModelCapabilityProfile(
    providerId: profile.providerId,
    modelId: modelId,
    kind: ModelCapabilityKind.speech,
    sharedFeatures: [
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.speechOutputFormat,
        confidence: confidence,
      ),
      const CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.speechVoiceSelection,
      ),
    ],
    providerFeatures: [
      ProviderFeatureDescriptor(
        providerId: profile.providerId,
        featureId: 'speech.providerOptions',
        detail: {
          'supportedOptions': [
            'outputFormat',
            'instructions',
            'speed',
          ],
        },
        confidence: confidence,
      ),
    ],
  );
}

CapabilityConfidence _familyFeatureConfidence(OpenAIFamilyProfile profile) =>
    profile.capabilityPolicy.sharedFeatureConfidence;
