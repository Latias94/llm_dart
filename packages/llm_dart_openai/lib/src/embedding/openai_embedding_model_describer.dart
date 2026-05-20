import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../provider/openai_family_capability_policy.dart';
import '../provider/openai_family_profile.dart';

ModelCapabilityProfile describeOpenAIEmbeddingModel(
  String modelId, {
  OpenAIFamilyProfile profile = const OpenAIProfile(),
}) {
  final confidence = _familyFeatureConfidence(profile);
  final sharedFeatures = <CapabilityDescriptor>{
    const CapabilityDescriptor(
      id: ModelCapabilityFeatureIds.embeddingBatch,
    ),
  };

  if (modelId.startsWith('text-embedding-3')) {
    sharedFeatures.add(
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.embeddingDimensions,
        confidence: confidence,
      ),
    );
  }

  return ModelCapabilityProfile(
    providerId: profile.providerId,
    modelId: modelId,
    kind: ModelCapabilityKind.embedding,
    sharedFeatures: sharedFeatures,
    providerFeatures: [
      ProviderFeatureDescriptor(
        providerId: profile.providerId,
        featureId: 'embedding.providerOptions',
        detail: {
          'supportedOptions': ['encodingFormat', 'user'],
        },
        confidence: confidence,
      ),
    ],
  );
}

CapabilityConfidence _familyFeatureConfidence(OpenAIFamilyProfile profile) =>
    openAIFamilyCapabilityPolicyFor(profile).sharedFeatureConfidence;
