import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'ollama_model_settings.dart';

OllamaEmbeddingModelSettings resolveOllamaEmbeddingModelSettings(
  ProviderModelOptions settings,
) {
  return resolveProviderModelOptions<OllamaEmbeddingModelSettings>(
    settings,
    parameterName: 'settings',
    expectedTypeName: 'OllamaEmbeddingModelSettings',
    usageContext: 'Ollama embedding models',
  );
}

void validateOllamaEmbeddingRequest(EmbedRequest request) {
  if (request.values.isEmpty) {
    throw ArgumentError.value(
      request.values,
      'request.values',
      'Ollama embedding requests require at least one value.',
    );
  }

  if (request.dimensions != null) {
    throw ArgumentError.value(
      request.dimensions,
      'request.dimensions',
      'Ollama embeddings do not support overriding output dimensions.',
    );
  }

  if (request.callOptions.providerOptions != null) {
    throw ArgumentError.value(
      request.callOptions.providerOptions,
      'request.callOptions.providerOptions',
      'Ollama embedding models do not define provider invocation options yet.',
    );
  }
}

Map<String, Object?> buildOllamaEmbeddingRequestBody({
  required String modelId,
  required EmbedRequest request,
}) {
  return {
    'model': modelId,
    'input': request.values,
  };
}
