import 'package:llm_dart_provider/llm_dart_provider.dart';

ModelCapabilityProfile describeGoogleEmbeddingModel(String modelId) {
  return ModelCapabilityProfile(
    providerId: 'google',
    modelId: modelId,
    kind: ModelCapabilityKind.embedding,
    sharedFeatures: const [
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.embeddingBatch,
      ),
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.embeddingDimensions,
      ),
    ],
    providerFeatures: [
      ProviderFeatureDescriptor(
        providerId: 'google',
        featureId: 'google.embedding.providerOptions',
        detail: {
          'supportedOptions': ['taskType', 'title'],
        },
      ),
    ],
  );
}
