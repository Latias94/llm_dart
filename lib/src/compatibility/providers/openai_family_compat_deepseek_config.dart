import '../../../core/config.dart';
import '../../../providers/deepseek/config.dart';
import '../config/legacy_config_keys.dart';
import '../config/legacy_provider_options.dart';
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
    logprobs: getLegacyProviderOption<bool>(
      config,
      LegacyProviderOptionNamespaces.deepseek,
      LegacyExtensionKeys.logprobs,
    ),
    topLogprobs: getLegacyProviderOption<int>(
      config,
      LegacyProviderOptionNamespaces.deepseek,
      LegacyExtensionKeys.deepSeekTopLogprobs,
    ),
    frequencyPenalty: getLegacyProviderOption<double>(
      config,
      LegacyProviderOptionNamespaces.deepseek,
      LegacyExtensionKeys.deepSeekFrequencyPenalty,
    ),
    presencePenalty: getLegacyProviderOption<double>(
      config,
      LegacyProviderOptionNamespaces.deepseek,
      LegacyExtensionKeys.deepSeekPresencePenalty,
    ),
    responseFormat: getLegacyProviderOption<Map<String, dynamic>>(
      config,
      LegacyProviderOptionNamespaces.deepseek,
      LegacyExtensionKeys.deepSeekResponseFormat,
    ),
  );
}
