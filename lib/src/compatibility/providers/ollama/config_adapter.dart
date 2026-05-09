import '../../../../core/config.dart';
import '../../../../providers/ollama/config.dart';
import '../../config/legacy_ollama_options.dart';
import '../../config/legacy_provider_options.dart';
import '../legacy_dio_client_overrides.dart';

/// Adapts a legacy root `LLMConfig` into an Ollama provider config.
OllamaConfig createLegacyOllamaConfig(LLMConfig config) {
  final options = legacyProviderOptionView(
    config,
    LegacyProviderOptionNamespaces.ollama,
  );
  final ollamaOptions = legacyOllamaOptions(options);

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
    jsonSchema: ollamaOptions.jsonSchema,
    numCtx: ollamaOptions.numCtx,
    numGpu: ollamaOptions.numGpu,
    numThread: ollamaOptions.numThread,
    numa: ollamaOptions.numa,
    numBatch: ollamaOptions.numBatch,
    keepAlive: ollamaOptions.keepAlive,
    raw: ollamaOptions.raw,
    reasoning: ollamaOptions.reasoning,
  );
}
