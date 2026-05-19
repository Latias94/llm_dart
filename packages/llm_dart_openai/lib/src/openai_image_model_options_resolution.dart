import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_non_text_model_support.dart';
import 'openai_options.dart';

OpenAIImageModelSettings resolveOpenAIImageModelSettings(
  ProviderModelOptions settings,
) {
  return resolveOpenAIModelSettings<OpenAIImageModelSettings>(
    settings,
    parameterName: 'settings',
    expectedTypeName: 'OpenAIImageModelSettings for OpenAI-family image models',
  );
}

OpenAIImageOptions? resolveOpenAIImageProviderOptions(
  CallOptions callOptions,
) {
  return resolveOpenAIProviderOptions<OpenAIImageOptions>(
    callOptions,
    parameterName: 'request.callOptions.providerOptions',
    expectedTypeName: 'OpenAIImageOptions for OpenAI-family image models',
  );
}
