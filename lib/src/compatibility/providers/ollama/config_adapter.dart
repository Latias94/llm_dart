import '../../../../core/config.dart';
import '../../../../models/tool_models.dart';
import '../../../../providers/ollama/config.dart';
import '../../config/legacy_config_keys.dart';
import '../../config/legacy_provider_options.dart';
import '../community_provider_config_adapters.dart';

/// Adapts a legacy root `LLMConfig` into an Ollama provider config.
OllamaConfig createLegacyOllamaConfig(LLMConfig config) {
  final options = legacyProviderOptionView(
    config,
    LegacyProviderOptionNamespaces.ollama,
  );

  return OllamaConfig(
    baseUrl: config.baseUrl,
    apiKey: config.apiKey,
    model: config.model,
    maxTokens: config.maxTokens,
    temperature: config.temperature,
    systemPrompt: config.systemPrompt,
    timeout: config.timeout,
    dioOverrides: createLegacyDioClientOverrides(config),
    topP: config.topP,
    topK: config.topK,
    tools: config.tools,
    jsonSchema: options.getWithFlatFallback<StructuredOutputFormat>(
      LegacyExtensionKeys.jsonSchema,
    ),
    numCtx: options.getWithFlatFallback<int>(LegacyExtensionKeys.numCtx),
    numGpu: options.getWithFlatFallback<int>(LegacyExtensionKeys.numGpu),
    numThread: options.getWithFlatFallback<int>(LegacyExtensionKeys.numThread),
    numa: options.getWithFlatFallback<bool>(LegacyExtensionKeys.numa),
    numBatch: options.getWithFlatFallback<int>(LegacyExtensionKeys.numBatch),
    keepAlive:
        options.getWithFlatFallback<String>(LegacyExtensionKeys.keepAlive),
    raw: options.getWithFlatFallback<bool>(LegacyExtensionKeys.raw),
    reasoning: options.getWithFlatFallback<bool>(LegacyExtensionKeys.reasoning),
  );
}
