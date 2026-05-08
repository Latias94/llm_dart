import '../../../core/config.dart';
import '../../../core/web_search.dart';
import '../../../providers/google/config.dart';
import '../config/legacy_google_options.dart';
import '../config/legacy_google_thinking_options.dart';
import '../config/legacy_provider_options.dart';
import '../config/legacy_web_search_options.dart';
import 'community_provider_config_adapters.dart';

/// Adapts a legacy root `LLMConfig` into a Google provider config.
GoogleConfig createLegacyGoogleConfig(LLMConfig config) {
  final options = legacyProviderOptionView(
    config,
    LegacyProviderOptionNamespaces.google,
  );
  final googleOptions = legacyGoogleOptions(options);
  final thinkingOptions = legacyGoogleThinkingOptions(options);

  return GoogleConfig(
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
    jsonSchema: googleOptions.jsonSchema,
    reasoningEffort: thinkingOptions.reasoningEffort,
    thinkingBudgetTokens: thinkingOptions.thinkingBudgetTokens,
    includeThoughts: thinkingOptions.includeThoughts,
    enableImageGeneration: googleOptions.enableImageGeneration,
    webSearchConfig: _createLegacyGoogleWebSearchConfig(options),
    responseModalities: googleOptions.responseModalities,
    safetySettings: googleOptions.safetySettings,
    maxInlineDataSize: googleOptions.maxInlineDataSize,
    candidateCount: googleOptions.candidateCount,
    stopSequences: config.stopSequences,
    embeddingTaskType: googleOptions.embeddingTaskType,
    embeddingTitle: googleOptions.embeddingTitle,
    embeddingDimensions: googleOptions.embeddingDimensions,
  );
}

WebSearchConfig? _createLegacyGoogleWebSearchConfig(
  LegacyProviderOptionView options,
) =>
    legacyWebSearchOptions(options).configOrEnabledDefault;
