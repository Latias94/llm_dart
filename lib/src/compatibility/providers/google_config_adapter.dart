import '../../../core/config.dart';
import '../../../core/web_search.dart';
import '../../../models/chat_models.dart';
import '../../../models/tool_models.dart';
import '../../../providers/google/config.dart';
import '../config/legacy_config_keys.dart';
import '../config/legacy_provider_options.dart';
import '../config/legacy_web_search_options.dart';
import 'community_provider_config_adapters.dart';

/// Adapts a legacy root `LLMConfig` into a Google provider config.
GoogleConfig createLegacyGoogleConfig(LLMConfig config) {
  final options = legacyProviderOptionView(
    config,
    LegacyProviderOptionNamespaces.google,
  );

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
    jsonSchema: options.getWithFlatFallback<StructuredOutputFormat>(
      LegacyExtensionKeys.jsonSchema,
    ),
    reasoningEffort: ReasoningEffort.fromString(
      options.getWithFlatFallback<String>(
        LegacyExtensionKeys.reasoningEffort,
      ),
    ),
    thinkingBudgetTokens: options.getWithFlatFallback<int>(
      LegacyExtensionKeys.thinkingBudgetTokens,
    ),
    includeThoughts: options.getWithFlatFallback<bool>(
      LegacyExtensionKeys.includeThoughts,
    ),
    enableImageGeneration: options.getWithFlatFallback<bool>(
      LegacyExtensionKeys.enableImageGeneration,
    ),
    webSearchConfig: _createLegacyGoogleWebSearchConfig(options),
    responseModalities: options.getWithFlatFallback<List<String>>(
      LegacyExtensionKeys.responseModalities,
    ),
    safetySettings: options.getWithFlatFallback<List<SafetySetting>>(
      LegacyExtensionKeys.safetySettings,
    ),
    maxInlineDataSize: options
            .getWithFlatFallback<int>(LegacyExtensionKeys.maxInlineDataSize) ??
        20 * 1024 * 1024,
    candidateCount: options.getWithFlatFallback<int>(
      LegacyExtensionKeys.candidateCount,
    ),
    stopSequences: config.stopSequences,
    embeddingTaskType: options.getWithFlatFallback<String>(
      LegacyExtensionKeys.embeddingTaskType,
    ),
    embeddingTitle: options.getWithFlatFallback<String>(
      LegacyExtensionKeys.embeddingTitle,
    ),
    embeddingDimensions: options.getWithFlatFallback<int>(
      LegacyExtensionKeys.embeddingDimensions,
    ),
  );
}

WebSearchConfig? _createLegacyGoogleWebSearchConfig(
  LegacyProviderOptionView options,
) =>
    legacyWebSearchOptions(options).configOrEnabledDefault;
