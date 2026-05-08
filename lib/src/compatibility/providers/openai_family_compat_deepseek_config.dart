import 'package:llm_dart_openai/llm_dart_openai.dart' as modern_openai;

import '../../../core/config.dart';
import '../../../providers/deepseek/config.dart';
import '../config/legacy_deepseek_options.dart';
import '../config/legacy_provider_options.dart';
import 'community_provider_config_adapters.dart';

/// Adapts a legacy root `LLMConfig` into a DeepSeek provider config.
DeepSeekConfig createLegacyDeepSeekConfig(LLMConfig config) {
  final options = legacyProviderOptionView(
    config,
    LegacyProviderOptionNamespaces.deepseek,
  );
  final deepSeekOptions = legacyDeepSeekOptions(options);

  return DeepSeekConfig(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    model: config.model,
    maxTokens: config.maxTokens,
    temperature: config.temperature,
    systemPrompt: config.systemPrompt,
    timeout: config.timeout,
    dioOverrides: createLegacyDioClientOverrides(config),
    topP: config.topP,
    topK: config.topK,
    tools: config.tools,
    toolChoice: config.toolChoice,
    logprobs: deepSeekOptions.logprobs,
    topLogprobs: deepSeekOptions.topLogprobs,
    frequencyPenalty: deepSeekOptions.frequencyPenalty,
    presencePenalty: deepSeekOptions.presencePenalty,
    responseFormat: deepSeekOptions.responseFormat,
  );
}

modern_openai.DeepSeekGenerateTextOptions buildCompatDeepSeekInvocationOptions(
  DeepSeekConfig config,
) {
  return modern_openai.DeepSeekGenerateTextOptions(
    logprobs: config.logprobs,
    topLogprobs: config.topLogprobs,
    frequencyPenalty: config.frequencyPenalty,
    presencePenalty: config.presencePenalty,
    responseFormat: config.responseFormat == null
        ? null
        : Map<String, Object?>.from(config.responseFormat!),
  );
}
