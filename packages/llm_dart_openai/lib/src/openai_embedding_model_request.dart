import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_embedding_options.dart';
import 'openai_model_settings.dart';
import 'openai_non_text_model_support.dart';

const int openAIMaxEmbeddingsPerCall = 2048;

OpenAIEmbeddingModelSettings resolveOpenAIEmbeddingModelSettings(
  ProviderModelOptions settings,
) {
  return resolveOpenAIModelSettings<OpenAIEmbeddingModelSettings>(
    settings,
    parameterName: 'settings',
    expectedTypeName:
        'OpenAIEmbeddingModelSettings for OpenAI-family embedding models',
  );
}

OpenAIEmbedOptions? resolveOpenAIEmbeddingProviderOptions(
  CallOptions callOptions,
) {
  return resolveOpenAIProviderOptions<OpenAIEmbedOptions>(
    callOptions,
    parameterName: 'request.callOptions.providerOptions',
    expectedTypeName: 'OpenAIEmbedOptions for OpenAI-family embedding models',
  );
}

void validateOpenAIEmbeddingValueCount(
  List<String> values, {
  required int maxEmbeddingsPerCall,
}) {
  if (values.length <= maxEmbeddingsPerCall) {
    return;
  }

  throw ArgumentError.value(
    values.length,
    'request.values.length',
    'OpenAI embedding models support at most $maxEmbeddingsPerCall values per call.',
  );
}

Map<String, Object?> buildOpenAIEmbeddingRequestBody({
  required String modelId,
  required EmbedRequest request,
  required OpenAIEmbedOptions? options,
}) {
  return {
    'model': modelId,
    'input': request.values,
    if (request.dimensions != null) 'dimensions': request.dimensions,
    'encoding_format': options?.encodingFormat ?? 'float',
    if (options?.user case final user?) 'user': user,
  };
}
