import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../provider/openai_family_profile.dart';

ModelCapabilityProfile describeOpenAIImageModel(
  String modelId, {
  OpenAIFamilyProfile profile = const OpenAIProfile(),
}) {
  final confidence = _familyFeatureConfidence(profile);
  final sharedFeatures = <CapabilityDescriptor>{};
  if (modelId.startsWith('gpt-image')) {
    sharedFeatures.add(
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.imageEditing,
        confidence: confidence,
      ),
    );
  }

  return ModelCapabilityProfile(
    providerId: profile.providerId,
    modelId: modelId,
    kind: ModelCapabilityKind.image,
    sharedFeatures: sharedFeatures,
    providerFeatures: [
      ProviderFeatureDescriptor(
        providerId: profile.providerId,
        featureId: 'image.providerOptions',
        detail: {
          'requestOptions': [
            'count',
            'size',
            'style',
            'quality',
            'background',
            'moderation',
            'outputFormat',
            'outputCompression',
            'responseFormat',
            'user',
          ],
        },
        confidence: confidence,
      ),
      if (modelId.startsWith('gpt-image'))
        ProviderFeatureDescriptor(
          providerId: profile.providerId,
          featureId: 'image.editOptions',
          detail: {
            'requestOptions': [
              'mask',
              'inputFidelity',
              'partialImages',
              'outputCompression',
            ],
          },
          confidence: confidence,
        ),
    ],
  );
}

CapabilityConfidence _familyFeatureConfidence(OpenAIFamilyProfile profile) =>
    profile.capabilityPolicy.sharedFeatureConfidence;
