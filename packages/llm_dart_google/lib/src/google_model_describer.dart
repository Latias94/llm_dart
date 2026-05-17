import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_language_model_policy.dart';
import 'google_options.dart';

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

ModelCapabilityProfile describeGoogleSpeechModel(
  String modelId, {
  GoogleSpeechModelSettings settings = const GoogleSpeechModelSettings(),
}) {
  return ModelCapabilityProfile(
    providerId: 'google',
    modelId: modelId,
    kind: ModelCapabilityKind.speech,
    sharedFeatures: const [
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.speechOutputFormat,
      ),
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.speechVoiceSelection,
      ),
    ],
    providerFeatures: [
      const ProviderFeatureDescriptor(
        providerId: 'google',
        featureId: 'api.route',
        detail: 'generateContent',
      ),
      ProviderFeatureDescriptor(
        providerId: 'google',
        featureId: 'google.speech.providerOptions',
        detail: {
          'supportedOptions': [
            'speakers',
            'temperature',
            'topP',
            'topK',
            'maxOutputTokens',
            'stopSequences',
          ],
          'defaultVoice': settings.defaultVoice,
        },
      ),
      const ProviderFeatureDescriptor(
        providerId: 'google',
        featureId: 'google.speech.multiSpeaker',
        detail: {
          'supported': true,
        },
      ),
    ],
  );
}

bool _isGeminiImageModel(String modelId) {
  return modelId.toLowerCase().contains('gemini');
}
