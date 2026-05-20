import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'resolved_openai_chat_settings.dart';
import 'resolved_openai_options.dart';

abstract class OpenAIFamilyOptionResolver {
  const OpenAIFamilyOptionResolver();

  ResolvedOpenAIChatModelSettings resolveModelSettings(
    ProviderModelOptions settings,
  );

  ResolvedOpenAIGenerateTextOptions resolveInvocationOptions({
    required ProviderInvocationOptions? options,
    required ResponseFormat? sharedResponseFormat,
    required ResolvedOpenAIChatModelSettings modelSettings,
  });

  String resolveRequestModelId({
    required String modelId,
    required ResolvedOpenAIChatModelSettings modelSettings,
    required ResolvedOpenAIGenerateTextOptions invocationOptions,
  });
}
