import '../../../../core/config.dart';
import '../../../../providers/ollama/config.dart';
import '../../../config/legacy_config_extensions.dart';
import '../community_provider_config_adapters.dart';

/// Adapts a legacy root `LLMConfig` into an Ollama provider config.
OllamaConfig createLegacyOllamaConfig(LLMConfig config) {
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
    jsonSchema: config.legacyJsonSchema,
    numCtx: config.getExtension<int>(LegacyExtensionKeys.numCtx),
    numGpu: config.getExtension<int>(LegacyExtensionKeys.numGpu),
    numThread: config.getExtension<int>(LegacyExtensionKeys.numThread),
    numa: config.getExtension<bool>(LegacyExtensionKeys.numa),
    numBatch: config.getExtension<int>(LegacyExtensionKeys.numBatch),
    keepAlive: config.getExtension<String>(LegacyExtensionKeys.keepAlive),
    raw: config.getExtension<bool>(LegacyExtensionKeys.raw),
    reasoning: config.getExtension<bool>(LegacyExtensionKeys.reasoning),
  );
}
