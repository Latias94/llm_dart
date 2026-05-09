part of 'shell_support.dart';

LLMConfig _toCompatConfig(OllamaConfig config) {
  return LLMConfig(
    apiKey: config.apiKey,
    baseUrl: config.baseUrl,
    model: config.model,
    maxTokens: config.maxTokens,
    temperature: config.temperature,
    systemPrompt: config.systemPrompt,
    timeout: config.timeout,
    topP: config.topP,
    topK: config.topK,
    tools: config.tools,
    extensions: {
      if (config.jsonSchema != null)
        LegacyExtensionKeys.jsonSchema: config.jsonSchema!,
      if (config.numCtx != null) LegacyExtensionKeys.numCtx: config.numCtx!,
      if (config.numGpu != null) LegacyExtensionKeys.numGpu: config.numGpu!,
      if (config.numThread != null)
        LegacyExtensionKeys.numThread: config.numThread!,
      if (config.numa != null) LegacyExtensionKeys.numa: config.numa!,
      if (config.numBatch != null)
        LegacyExtensionKeys.numBatch: config.numBatch!,
      if (config.keepAlive != null)
        LegacyExtensionKeys.keepAlive: config.keepAlive!,
      if (config.raw != null) LegacyExtensionKeys.raw: config.raw!,
      if (config.reasoning != null)
        LegacyExtensionKeys.reasoning: config.reasoning!,
    },
  );
}

modern_ollama.OllamaGenerateTextOptions _buildCompatProviderOptions(
  OllamaConfig config,
) {
  return modern_ollama.OllamaGenerateTextOptions(
    numCtx: config.numCtx,
    numGpu: config.numGpu,
    numThread: config.numThread,
    numBatch: config.numBatch,
    numa: config.numa,
    keepAlive: config.keepAlive ?? '5m',
    raw: config.raw == true ? true : null,
    reasoning: config.reasoning,
  );
}
