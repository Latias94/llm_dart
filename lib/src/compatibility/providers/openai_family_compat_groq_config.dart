import '../../../core/config.dart';
import '../../../providers/groq/config.dart';
import 'community_provider_config_adapters.dart';

/// Adapts a legacy root `LLMConfig` into a Groq provider config.
GroqConfig createLegacyGroqConfig(LLMConfig config) {
  return GroqConfig(
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
