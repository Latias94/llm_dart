import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_family_capability_policy.dart';
import 'openai_family_profile.dart';
import 'openai_model_capabilities.dart';
import 'openai_model_settings.dart';
import 'openai_provider_support.dart';

const List<String> _openAIBuiltInToolFamilies = [
  'webSearch',
  'fileSearch',
  'computerUse',
  'imageGeneration',
  'mcp',
  'codeInterpreter',
  'localShell',
  'shell',
  'applyPatch',
  'toolSearch',
  'custom',
];

ModelCapabilityProfile describeOpenAIChatModel(
  String modelId, {
  OpenAIFamilyProfile profile = const OpenAIProfile(),
  ProviderModelOptions settings = const OpenAIChatModelSettings(),
}) {
  final resolvedSettings = resolveOpenAIModelSettingsForProfile(
    profile,
    settings,
  );
  final capabilities = getOpenAIModelCapabilities(modelId);
  final usesResponsesApi =
      resolvedSettings.common.useResponsesApi && profile.supportsResponsesApi;
  final capabilityPolicy = openAIFamilyCapabilityPolicyFor(profile);
  final confidence = capabilityPolicy.sharedFeatureConfidence;
  final capabilityInput = OpenAIFamilyCapabilityInput(
    modelId: modelId,
    modelCapabilities: capabilities,
    usesResponsesApi: usesResponsesApi,
    resolvedSettings: resolvedSettings,
  );
  final sharedFeatures = <CapabilityDescriptor>{
    const CapabilityDescriptor(
      id: ModelCapabilityFeatureIds.languageStreaming,
    ),
    const CapabilityDescriptor(
      id: ModelCapabilityFeatureIds.languageTextInput,
    ),
    CapabilityDescriptor(
      id: ModelCapabilityFeatureIds.languageFunctionTools,
      confidence: confidence,
    ),
    CapabilityDescriptor(
      id: ModelCapabilityFeatureIds.languageToolChoice,
      confidence: confidence,
    ),
    CapabilityDescriptor(
      id: ModelCapabilityFeatureIds.languageStructuredOutput,
      confidence: confidence,
    ),
    CapabilityDescriptor(
      id: ModelCapabilityFeatureIds.languageImageInput,
      confidence: confidence,
    ),
    CapabilityDescriptor(
      id: ModelCapabilityFeatureIds.languageFileInput,
      confidence: confidence,
    ),
  };
  sharedFeatures.addAll(capabilityPolicy.sharedLanguageFeatures(
    capabilityInput,
  ));

  final providerFeatures = <ProviderFeatureDescriptor>[
    ProviderFeatureDescriptor(
      providerId: profile.providerId,
      featureId: 'api.route',
      detail: usesResponsesApi ? 'responses' : 'chat_completions',
    ),
    ProviderFeatureDescriptor(
      providerId: profile.providerId,
      featureId: 'modelCapabilities',
      detail: {
        'isReasoningModel': capabilities.isReasoningModel,
        'systemMessageMode': capabilities.systemMessageMode.value,
        'supportsFlexProcessing': capabilities.supportsFlexProcessing,
        'supportsPriorityProcessing': capabilities.supportsPriorityProcessing,
        'supportsNonReasoningParameters':
            capabilities.supportsNonReasoningParameters,
      },
      confidence: confidence,
    ),
  ];

  if (usesResponsesApi) {
    providerFeatures.add(
      ProviderFeatureDescriptor(
        providerId: profile.providerId,
        featureId: 'responses.nativeFeatures',
        detail: {
          'persistence': ['previousResponseId', 'conversation', 'store'],
          'builtInTools': _openAIBuiltInToolFamilies,
        },
        confidence: confidence,
      ),
    );
  } else {
    providerFeatures.add(
      ProviderFeatureDescriptor(
        providerId: profile.providerId,
        featureId: 'chatCompletions.audioInput',
        detail: {
          'supportedMediaTypes': ['audio/wav', 'audio/mpeg', 'audio/mp3'],
        },
        confidence: CapabilityConfidence.inferred,
      ),
    );
  }

  providerFeatures.addAll(capabilityPolicy.providerLanguageFeatures(
    providerId: profile.providerId,
    input: capabilityInput,
  ));

  return ModelCapabilityProfile(
    providerId: profile.providerId,
    modelId: modelId,
    kind: ModelCapabilityKind.language,
    sharedFeatures: sharedFeatures,
    providerFeatures: providerFeatures,
  );
}

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
