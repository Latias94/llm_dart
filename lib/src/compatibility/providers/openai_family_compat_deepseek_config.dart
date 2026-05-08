import '../../../core/config.dart';
import '../../../providers/deepseek/config.dart';
import '../config/legacy_config_keys.dart';
import '../config/legacy_provider_options.dart';
import 'community_provider_config_adapters.dart';

/// Adapts a legacy root `LLMConfig` into a DeepSeek provider config.
DeepSeekConfig createLegacyDeepSeekConfig(LLMConfig config) {
  final options = legacyProviderOptionView(
    config,
    LegacyProviderOptionNamespaces.deepseek,
  );

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
    logprobs: options.getWithFlatFallback<bool>(LegacyExtensionKeys.logprobs),
    topLogprobs: options.getWithFlatFallback<int>(
      LegacyExtensionKeys.deepSeekTopLogprobs,
    ),
    frequencyPenalty: options.getWithFlatFallback<double>(
      LegacyExtensionKeys.deepSeekFrequencyPenalty,
    ),
    presencePenalty: options.getWithFlatFallback<double>(
      LegacyExtensionKeys.deepSeekPresencePenalty,
    ),
    responseFormat: options.getWithFlatFallback<Map<String, dynamic>>(
      LegacyExtensionKeys.deepSeekResponseFormat,
    ),
  );
}
