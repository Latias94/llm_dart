import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_model_settings.dart';

ModelCapabilityProfile describeGoogleImageModel(
  String modelId, {
  GoogleImageModelSettings settings = const GoogleImageModelSettings(),
}) {
  final isGeminiImageModel = _isGeminiImageModel(modelId);
  final familyConfidence = isGeminiImageModel
      ? CapabilityConfidence.known
      : CapabilityConfidence.inferred;
  final maxImagesPerCall =
      settings.maxImagesPerCall ?? (isGeminiImageModel ? 1 : 4);

  final sharedFeatures = <CapabilityDescriptor>{};
  if (maxImagesPerCall > 1) {
    sharedFeatures.add(
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.imageMultipleOutput,
        confidence: familyConfidence,
      ),
    );
  }
  if (isGeminiImageModel) {
    sharedFeatures.add(
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.imageEditing,
        confidence: familyConfidence,
      ),
    );
  }

  return ModelCapabilityProfile(
    providerId: 'google',
    modelId: modelId,
    kind: ModelCapabilityKind.image,
    sharedFeatures: sharedFeatures,
    providerFeatures: [
      ProviderFeatureDescriptor(
        providerId: 'google',
        featureId: 'api.route',
        detail: isGeminiImageModel ? 'generateContent' : 'predict',
        confidence: familyConfidence,
      ),
      ProviderFeatureDescriptor(
        providerId: 'google',
        featureId: 'google.image.providerOptions',
        detail: {
          'supportedOptions': [
            'aspectRatio',
            if (isGeminiImageModel) 'safetySettings',
            if (!isGeminiImageModel) 'personGeneration',
          ],
        },
        confidence: familyConfidence,
      ),
      ProviderFeatureDescriptor(
        providerId: 'google',
        featureId: 'google.image.maxImagesPerCall',
        detail: maxImagesPerCall,
        confidence: familyConfidence,
      ),
      if (isGeminiImageModel)
        const ProviderFeatureDescriptor(
          providerId: 'google',
          featureId: 'google.image.inlineEditing',
          detail: {
            'inputMediaFamilies': ['image/*'],
          },
        ),
    ],
  );
}

bool _isGeminiImageModel(String modelId) {
  return modelId.toLowerCase().contains('gemini');
}
