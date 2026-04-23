import 'package:llm_dart_core/llm_dart_core.dart';

import 'ollama_options.dart';

const List<String> _ollamaInvocationOptions = [
  'numCtx',
  'numGpu',
  'numThread',
  'numBatch',
  'numa',
  'keepAlive',
  'raw',
  'reasoning',
];

ModelCapabilityProfile describeOllamaChatModel(
  String modelId, {
  OllamaChatModelSettings settings = const OllamaChatModelSettings(),
}) {
  final sharedFeatures = <CapabilityDescriptor>{
    const CapabilityDescriptor(
      id: ModelCapabilityFeatureIds.languageStreaming,
    ),
    const CapabilityDescriptor(
      id: ModelCapabilityFeatureIds.languageTextInput,
    ),
    const CapabilityDescriptor(
      id: ModelCapabilityFeatureIds.languageStructuredOutput,
    ),
    const CapabilityDescriptor(
      id: ModelCapabilityFeatureIds.languageFunctionTools,
      confidence: CapabilityConfidence.inferred,
    ),
  };

  if (_looksLikeVisionModel(modelId)) {
    sharedFeatures.add(
      const CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.languageImageInput,
        confidence: CapabilityConfidence.inferred,
      ),
    );
  }

  if (_looksLikeReasoningModel(modelId)) {
    sharedFeatures.add(
      const CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.languageReasoningOutput,
        confidence: CapabilityConfidence.inferred,
      ),
    );
  }

  return ModelCapabilityProfile(
    providerId: 'ollama',
    modelId: modelId,
    kind: ModelCapabilityKind.language,
    sharedFeatures: sharedFeatures,
    providerFeatures: [
      const ProviderFeatureDescriptor(
        providerId: 'ollama',
        featureId: 'api.route',
        detail: 'chat',
      ),
      ProviderFeatureDescriptor(
        providerId: 'ollama',
        featureId: 'ollama.invocationOptions',
        detail: {
          'supportedOptions': _ollamaInvocationOptions,
          'binaryResolverConfigured': settings.binaryResolver != null,
        },
      ),
      const ProviderFeatureDescriptor(
        providerId: 'ollama',
        featureId: 'ollama.toolSelection',
        detail: {
          'automaticOnly': true,
          'explicitChoice': false,
        },
      ),
      if (_looksLikeVisionModel(modelId))
        const ProviderFeatureDescriptor(
          providerId: 'ollama',
          featureId: 'ollama.imageInputs',
          detail: {
            'inputMediaFamilies': ['image/*'],
            'sharedFileInput': false,
          },
          confidence: CapabilityConfidence.inferred,
        ),
      if (_looksLikeReasoningModel(modelId))
        const ProviderFeatureDescriptor(
          providerId: 'ollama',
          featureId: 'ollama.thinking',
          detail: {
            'toggle': 'providerOptions.reasoning',
            'resultSurface': 'reasoning',
          },
          confidence: CapabilityConfidence.inferred,
        ),
    ],
  );
}

ModelCapabilityProfile describeOllamaEmbeddingModel(String modelId) {
  return ModelCapabilityProfile(
    providerId: 'ollama',
    modelId: modelId,
    kind: ModelCapabilityKind.embedding,
    sharedFeatures: const [
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.embeddingBatch,
      ),
    ],
    providerFeatures: const [
      ProviderFeatureDescriptor(
        providerId: 'ollama',
        featureId: 'api.route',
        detail: 'embed',
      ),
      ProviderFeatureDescriptor(
        providerId: 'ollama',
        featureId: 'ollama.embedding.providerOptions',
        detail: {
          'supportedOptions': <String>[],
        },
      ),
    ],
  );
}

bool _looksLikeVisionModel(String modelId) {
  final normalized = modelId.toLowerCase();
  return normalized.contains('vision') ||
      normalized.contains('llava') ||
      normalized.contains('bakllava') ||
      normalized.contains('moondream') ||
      normalized.contains('minicpm-v') ||
      normalized.contains('minicpmv') ||
      normalized.contains('internvl') ||
      normalized.contains('qwen-vl') ||
      normalized.contains('qwen2-vl') ||
      normalized.contains('qwen2.5-vl') ||
      normalized.contains('qwen2.5vl') ||
      normalized.contains('gemma3');
}

bool _looksLikeReasoningModel(String modelId) {
  final normalized = modelId.toLowerCase();
  return normalized.contains('thinking') ||
      normalized.contains('reason') ||
      normalized.contains('qwq') ||
      RegExp(r'(^|[-_:.\/])r1($|[-_:.\/])').hasMatch(normalized);
}
