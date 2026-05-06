import '../../../core/config.dart';
import '../../../providers/deepseek/config.dart';
import 'community_provider_config_adapters.dart';

/// Adapts a legacy root `LLMConfig` into a DeepSeek provider config.
DeepSeekConfig createLegacyDeepSeekConfig(LLMConfig config) {
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
    logprobs: config.getExtension<bool>('logprobs'),
    topLogprobs: config.getExtension<int>('top_logprobs'),
    frequencyPenalty: config.getExtension<double>('frequency_penalty'),
    presencePenalty: config.getExtension<double>('presence_penalty'),
    responseFormat: config.getExtension<Map<String, dynamic>>(
      'response_format',
    ),
  );
}
