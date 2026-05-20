import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_embedding_options.dart';
import '../provider/openai_model_settings.dart';
import '../common/openai_non_text_model_support.dart';
import '../provider/openai_provider_options_bag.dart';

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
  return resolveOpenAIEmbedOptionsFromInvocation(callOptions.providerOptions);
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
