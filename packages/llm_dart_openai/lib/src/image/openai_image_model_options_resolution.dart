import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_image_options.dart';
import '../provider/openai_model_settings.dart';
import '../common/openai_non_text_model_support.dart';
import '../provider/openai_family_invocation_options.dart';

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
  return resolveOpenAIImageInvocationOptions(callOptions.providerOptions);
}
