import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_family_capability_policy.dart';
import 'openai_family_profile.dart';
import 'openai_model_capabilities.dart';
import 'openai_model_settings.dart';
import 'openai_provider_support.dart';

const List<String> _openAIBuiltInToolFamilies = [
  'webSearchPreview',
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
