import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_image_options.dart';
import '../provider/openai_model_settings.dart';
import '../common/openai_non_text_model_support.dart';
import '../provider/openai_provider_options_bag.dart';

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
  return resolveOpenAIImageOptionsFromInvocation(callOptions.providerOptions);
}
