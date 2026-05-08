import '../../../../core/config.dart';
import '../../../../providers/ollama/config.dart';
import '../../config/legacy_config_extensions.dart';
import '../../config/legacy_provider_options.dart';
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
    numCtx: getLegacyProviderOption<int>(
      config,
      LegacyProviderOptionNamespaces.ollama,
      LegacyExtensionKeys.numCtx,
    ),
    numGpu: getLegacyProviderOption<int>(
      config,
      LegacyProviderOptionNamespaces.ollama,
      LegacyExtensionKeys.numGpu,
    ),
    numThread: getLegacyProviderOption<int>(
      config,
      LegacyProviderOptionNamespaces.ollama,
      LegacyExtensionKeys.numThread,
    ),
    numa: getLegacyProviderOption<bool>(
      config,
      LegacyProviderOptionNamespaces.ollama,
      LegacyExtensionKeys.numa,
    ),
    numBatch: getLegacyProviderOption<int>(
      config,
      LegacyProviderOptionNamespaces.ollama,
      LegacyExtensionKeys.numBatch,
    ),
    keepAlive: getLegacyProviderOption<String>(
      config,
      LegacyProviderOptionNamespaces.ollama,
      LegacyExtensionKeys.keepAlive,
    ),
    raw: getLegacyProviderOption<bool>(
      config,
      LegacyProviderOptionNamespaces.ollama,
      LegacyExtensionKeys.raw,
    ),
    reasoning: getLegacyProviderOption<bool>(
      config,
      LegacyProviderOptionNamespaces.ollama,
      LegacyExtensionKeys.reasoning,
    ),
  );
}
