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
    jsonSchema: options.get<StructuredOutputFormat>(
      LegacyExtensionKeys.jsonSchema,
    ),
    reasoningEffort: ReasoningEffort.fromString(
      options.get<String>(
        LegacyExtensionKeys.reasoningEffort,
      ),
    ),
    thinkingBudgetTokens: options.get<int>(
      LegacyExtensionKeys.thinkingBudgetTokens,
    ),
    includeThoughts: options.get<bool>(
      LegacyExtensionKeys.includeThoughts,
    ),
    enableImageGeneration: options.get<bool>(
      LegacyExtensionKeys.enableImageGeneration,
    ),
    webSearchConfig: _createLegacyGoogleWebSearchConfig(options),
    responseModalities: options.get<List<String>>(
      LegacyExtensionKeys.responseModalities,
    ),
    safetySettings: options.get<List<SafetySetting>>(
      LegacyExtensionKeys.safetySettings,
    ),
    maxInlineDataSize:
        options.get<int>(LegacyExtensionKeys.maxInlineDataSize) ??
            20 * 1024 * 1024,
    candidateCount: options.get<int>(
      LegacyExtensionKeys.candidateCount,
    ),
    stopSequences: config.stopSequences,
    embeddingTaskType: options.get<String>(
      LegacyExtensionKeys.embeddingTaskType,
    ),
    embeddingTitle: options.get<String>(
      LegacyExtensionKeys.embeddingTitle,
    ),
    embeddingDimensions: options.get<int>(
      LegacyExtensionKeys.embeddingDimensions,
    ),
  );
}

WebSearchConfig? _createLegacyGoogleWebSearchConfig(
  LegacyProviderOptionView options,
) {
  final webSearchConfig = options.get<WebSearchConfig>(
    LegacyExtensionKeys.webSearchConfig,
  );
  if (webSearchConfig != null) {
    return webSearchConfig;
  }

  if (options.get<bool>(LegacyExtensionKeys.webSearchEnabled) == true) {
    return const WebSearchConfig();
  }

  return null;
}
