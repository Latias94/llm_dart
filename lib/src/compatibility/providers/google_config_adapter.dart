import '../../../core/config.dart';
import '../../../core/web_search.dart';
import '../../../models/chat_models.dart';
import '../../../models/tool_models.dart';
import '../../../providers/google/config.dart';
import '../config/legacy_config_keys.dart';
import '../config/legacy_provider_options.dart';
import 'community_provider_config_adapters.dart';

/// Adapts a legacy root `LLMConfig` into a Google provider config.
GoogleConfig createLegacyGoogleConfig(LLMConfig config) {
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
    jsonSchema: getLegacyProviderOption<StructuredOutputFormat>(
      config,
      LegacyProviderOptionNamespaces.google,
      LegacyExtensionKeys.jsonSchema,
    ),
    reasoningEffort: ReasoningEffort.fromString(
      getLegacyProviderOption<String>(
        config,
        LegacyProviderOptionNamespaces.google,
        LegacyExtensionKeys.reasoningEffort,
      ),
    ),
    thinkingBudgetTokens: getLegacyProviderOption<int>(
      config,
      LegacyProviderOptionNamespaces.google,
      LegacyExtensionKeys.thinkingBudgetTokens,
    ),
    includeThoughts: getLegacyProviderOption<bool>(
      config,
      LegacyProviderOptionNamespaces.google,
      LegacyExtensionKeys.includeThoughts,
    ),
    enableImageGeneration: getLegacyProviderOption<bool>(
      config,
      LegacyProviderOptionNamespaces.google,
      LegacyExtensionKeys.enableImageGeneration,
    ),
    webSearchConfig: _createLegacyGoogleWebSearchConfig(config),
    responseModalities: getLegacyProviderOption<List<String>>(
      config,
      LegacyProviderOptionNamespaces.google,
      LegacyExtensionKeys.responseModalities,
    ),
    safetySettings: getLegacyProviderOption<List<SafetySetting>>(
      config,
      LegacyProviderOptionNamespaces.google,
      LegacyExtensionKeys.safetySettings,
    ),
    maxInlineDataSize: getLegacyProviderOption<int>(
          config,
          LegacyProviderOptionNamespaces.google,
          LegacyExtensionKeys.maxInlineDataSize,
        ) ??
        20 * 1024 * 1024,
    candidateCount: getLegacyProviderOption<int>(
      config,
      LegacyProviderOptionNamespaces.google,
      LegacyExtensionKeys.candidateCount,
    ),
    stopSequences: config.stopSequences,
    embeddingTaskType: getLegacyProviderOption<String>(
      config,
      LegacyProviderOptionNamespaces.google,
      LegacyExtensionKeys.embeddingTaskType,
    ),
    embeddingTitle: getLegacyProviderOption<String>(
      config,
      LegacyProviderOptionNamespaces.google,
      LegacyExtensionKeys.embeddingTitle,
    ),
    embeddingDimensions: getLegacyProviderOption<int>(
      config,
      LegacyProviderOptionNamespaces.google,
      LegacyExtensionKeys.embeddingDimensions,
    ),
  );
}

WebSearchConfig? _createLegacyGoogleWebSearchConfig(LLMConfig config) {
  final webSearchConfig = getLegacyProviderOption<WebSearchConfig>(
    config,
    LegacyProviderOptionNamespaces.google,
    LegacyExtensionKeys.webSearchConfig,
  );
  if (webSearchConfig != null) {
    return webSearchConfig;
  }

  if (getLegacyProviderOption<bool>(
        config,
        LegacyProviderOptionNamespaces.google,
        LegacyExtensionKeys.webSearchEnabled,
      ) ==
      true) {
    return const WebSearchConfig();
  }

  return null;
}
