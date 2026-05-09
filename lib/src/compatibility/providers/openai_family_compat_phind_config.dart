import '../../../core/config.dart';
import '../../../providers/phind/config.dart';
import 'legacy_dio_client_overrides.dart';

/// Adapts a legacy root `LLMConfig` into a Phind provider config.
PhindConfig createLegacyPhindConfig(LLMConfig config) {
  return PhindConfig(
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
  );
}
