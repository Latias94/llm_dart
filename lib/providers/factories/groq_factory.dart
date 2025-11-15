import '../../core/capability.dart';
import '../../core/config.dart';
import '../../core/provider_defaults.dart';
import 'base_factory.dart';
import 'package:llm_dart_groq/llm_dart_groq.dart';

/// Factory for creating Groq provider instances
class GroqProviderFactory extends BaseProviderFactory<ChatCapability> {
  @override
  String get providerId => 'groq';

  @override
  String get displayName => 'Groq';

  @override
  String get description => 'Groq AI models for ultra-fast inference';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
      };

  @override
  ChatCapability create(LLMConfig config) {
    return createProviderSafely<GroqConfig>(
      config,
      () => _transformConfig(config),
      (groqConfig) => GroqProvider(groqConfig),
    );
  }

  @override
  Map<String, dynamic> getProviderDefaults() {
    return ProviderDefaults.getDefaults('groq');
  }

  /// Transform unified config to Groq-specific config
  GroqConfig _transformConfig(LLMConfig config) {
    return GroqConfig(
      apiKey: config.apiKey!,
      baseUrl: config.baseUrl.isNotEmpty
          ? config.baseUrl
          : ProviderDefaults.groqBaseUrl,
      model: config.model.isNotEmpty
          ? config.model
          : ProviderDefaults.groqDefaultModel,
      maxTokens: config.maxTokens,
      temperature: config.temperature,
      systemPrompt: config.systemPrompt,
      timeout: config.timeout,
      topP: config.topP,
      topK: config.topK,
      tools: config.tools,
      toolChoice: config.toolChoice,
      reasoningEffort: ReasoningEffort.fromString(
        config.getExtension<String>(LLMConfigKeys.reasoningEffort),
      ),
      jsonSchema: config.getExtension<StructuredOutputFormat>(
        LLMConfigKeys.jsonSchema,
      ),
      stopSequences: config.stopSequences,
      user: config.user,
      serviceTier: config.serviceTier,
      originalConfig: config,
    );
  }
}
