import '../../../core/config.dart';
import '../../../providers/deepseek/config.dart';
import '../config/legacy_config_keys.dart';
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
    logprobs: config.getExtension<bool>(LegacyExtensionKeys.logprobs),
    topLogprobs:
        config.getExtension<int>(LegacyExtensionKeys.deepSeekTopLogprobs),
    frequencyPenalty: config.getExtension<double>(
      LegacyExtensionKeys.deepSeekFrequencyPenalty,
    ),
    presencePenalty: config.getExtension<double>(
      LegacyExtensionKeys.deepSeekPresencePenalty,
    ),
    responseFormat: config.getExtension<Map<String, dynamic>>(
      LegacyExtensionKeys.deepSeekResponseFormat,
    ),
  );
}
