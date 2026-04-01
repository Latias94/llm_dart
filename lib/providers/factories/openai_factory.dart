import '../../core/capability.dart';
import '../../core/config.dart';
import '../../src/provider_defaults.dart';
import '../../models/chat_models.dart';
import '../../src/config/legacy_config_extensions.dart';
import '../openai/openai.dart';
import 'base_factory.dart';

/// Factory for creating OpenAI provider instances
class OpenAIProviderFactory
    extends OpenAICompatibleBaseFactory<ChatCapability> {
  @override
  String get providerId => 'openai';

  @override
  String get displayName => 'OpenAI';

  @override
  String get description =>
      'OpenAI GPT models including GPT-4, GPT-3.5, and reasoning models';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.embedding,
        LLMCapability.modelListing,
        LLMCapability.toolCalling,
        LLMCapability.reasoning,
        LLMCapability.vision,
        LLMCapability.textToSpeech,
        LLMCapability.speechToText,
        LLMCapability.imageGeneration,
      };

  @override
  ChatCapability create(LLMConfig config) {
    return createProviderSafely<OpenAIConfig>(
      config,
      () => _transformConfig(config),
      (openaiConfig) => OpenAIProvider(openaiConfig),
    );
  }

  @override
  Map<String, dynamic> getProviderDefaults() {
    return ProviderDefaults.getDefaults('openai');
  }

  /// Transform unified config to OpenAI-specific config
  OpenAIConfig _transformConfig(LLMConfig config) {
    // Handle web search configuration
    String? model = config.model;

    // Check for webSearchEnabled flag
    final webSearchEnabled = config.legacyWebSearchEnabled;
    if (webSearchEnabled == true && !_isSearchModel(model)) {
      // Switch to search-enabled model if not already using one
      model = _getSearchModel(model);
    }

    // Check for webSearchConfig
    final webSearchConfig = config.legacyWebSearchConfig;
    if (webSearchConfig != null && !_isSearchModel(model)) {
      model = _getSearchModel(model);
    }

    return OpenAIConfig(
      apiKey: config.apiKey!,
      baseUrl: config.baseUrl,
      model: model,
      maxTokens: config.maxTokens,
      temperature: config.temperature,
      systemPrompt: config.systemPrompt,
      timeout: config.timeout,
      topP: config.topP,
      topK: config.topK,
      tools: config.tools,
      toolChoice: config.toolChoice,
      // Common parameters
      stopSequences: config.stopSequences,
      user: config.user,
      serviceTier: config.serviceTier,
      // OpenAI-specific extensions using helper method
      reasoningEffort:
          ReasoningEffort.fromString(config.legacyReasoningEffortValue),
      jsonSchema: config.legacyJsonSchema,
      voice: config.legacyVoice,
      embeddingEncodingFormat: config.legacyEmbeddingEncodingFormat,
      embeddingDimensions: config.legacyEmbeddingDimensions,
      // Responses API configuration
      useResponsesAPI:
          getExtension<bool>(config, LegacyExtensionKeys.useResponsesApi) ??
              false,
      previousResponseId:
          getExtension<String>(config, LegacyExtensionKeys.previousResponseId),
      builtInTools: getExtension<List<OpenAIBuiltInTool>>(
        config,
        LegacyExtensionKeys.builtInTools,
      ),
      originalConfig: config,
    );
  }

  /// Check if the model supports web search
  bool _isSearchModel(String? model) {
    if (model == null) return false;
    return model.contains('search-preview') || model.contains('search');
  }

  /// Get the search-enabled version of a model
  String _getSearchModel(String? model) {
    if (model == null) return 'gpt-4o-search-preview';

    // Map common models to their search variants
    if (model.startsWith('gpt-4o')) {
      return 'gpt-4o-search-preview';
    } else if (model.startsWith('gpt-4o-mini')) {
      return 'gpt-4o-mini-search-preview';
    } else {
      // Default to gpt-4o-search-preview for other models
      return 'gpt-4o-search-preview';
    }
  }
}
