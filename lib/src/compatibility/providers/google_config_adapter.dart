import '../../../core/config.dart';
import '../../../core/web_search.dart';
import '../../../models/chat_models.dart';
import '../../../models/tool_models.dart';
import '../../../providers/google/config.dart';
import '../config/legacy_config_keys.dart';
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
    jsonSchema: config.getExtension<StructuredOutputFormat>(
      LegacyExtensionKeys.jsonSchema,
    ),
    reasoningEffort: ReasoningEffort.fromString(
      config.getExtension<String>(LegacyExtensionKeys.reasoningEffort),
    ),
    thinkingBudgetTokens:
        config.getExtension<int>(LegacyExtensionKeys.thinkingBudgetTokens),
    includeThoughts:
        config.getExtension<bool>(LegacyExtensionKeys.includeThoughts),
    enableImageGeneration:
        config.getExtension<bool>(LegacyExtensionKeys.enableImageGeneration),
    webSearchConfig: _createLegacyGoogleWebSearchConfig(config),
    responseModalities: config.getExtension<List<String>>(
      LegacyExtensionKeys.responseModalities,
    ),
    safetySettings: config.getExtension<List<SafetySetting>>(
      LegacyExtensionKeys.safetySettings,
    ),
    maxInlineDataSize:
        config.getExtension<int>(LegacyExtensionKeys.maxInlineDataSize) ??
            20 * 1024 * 1024,
    candidateCount: config.getExtension<int>(
      LegacyExtensionKeys.candidateCount,
    ),
    stopSequences: config.stopSequences,
    embeddingTaskType: config.getExtension<String>(
      LegacyExtensionKeys.embeddingTaskType,
    ),
    embeddingTitle: config.getExtension<String>(
      LegacyExtensionKeys.embeddingTitle,
    ),
    embeddingDimensions: config.getExtension<int>(
      LegacyExtensionKeys.embeddingDimensions,
    ),
  );
}

WebSearchConfig? _createLegacyGoogleWebSearchConfig(LLMConfig config) {
  final webSearchConfig = config.getExtension<WebSearchConfig>(
    LegacyExtensionKeys.webSearchConfig,
  );
  if (webSearchConfig != null) {
    return webSearchConfig;
  }

  if (config.getExtension<bool>(LegacyExtensionKeys.webSearchEnabled) == true) {
    return const WebSearchConfig();
  }

  return null;
}
