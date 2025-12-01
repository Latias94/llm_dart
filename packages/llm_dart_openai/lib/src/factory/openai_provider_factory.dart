import 'package:llm_dart_core/llm_dart_core.dart';

import '../config/openai_config.dart';
import '../provider/openai_provider.dart';
import '../tools/openai_builtin_tools.dart';

/// Factory for creating OpenAI provider instances.
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
        LLMCapability.assistants,
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
  LLMConfig getDefaultConfig() => const LLMConfig(
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
      );

  /// Transform unified config to OpenAI-specific config.
  OpenAIConfig _transformConfig(LLMConfig config) {
    // Handle web search configuration.
    String? model = config.model;

    // Check for webSearchEnabled flag.
    final webSearchEnabled =
        getExtension<bool>(config, LLMConfigKeys.webSearchEnabled);
    if (webSearchEnabled == true && !_isSearchModel(model)) {
      // Switch to search-enabled model if not already using one.
      model = _getSearchModel(model);
    }

    // Check for webSearchConfig.
    final webSearchConfig =
        getExtension<WebSearchConfig>(config, LLMConfigKeys.webSearchConfig);
    if (webSearchConfig != null && !_isSearchModel(model)) {
      model = _getSearchModel(model);
    }

    // Derive built-in web search tool from unified WebSearchConfig when using
    // the Responses API, mirroring Vercel's openai.tools.webSearch helper.
    //
    // This keeps the builder API provider-agnostic: calling
    // `advancedWebSearch(...)` will automatically configure OpenAI's
    // `web_search` built-in tool unless the user has explicitly added one
    // via OpenAI-specific helpers.
    List<OpenAIBuiltInTool>? builtInTools =
        getExtension<List<OpenAIBuiltInTool>>(
      config,
      LLMConfigKeys.builtInTools,
    );

    final useResponsesAPI =
        getExtension<bool>(config, LLMConfigKeys.useResponsesAPI) ?? false;

    if (useResponsesAPI && webSearchConfig != null) {
      final hasWebSearchTool =
          (builtInTools ?? const <OpenAIBuiltInTool>[]).any(
        (t) => t is OpenAIWebSearchTool,
      );

      if (!hasWebSearchTool) {
        final webTool = OpenAIBuiltInTools.webSearch(
          allowedDomains: webSearchConfig.allowedDomains,
          contextSize: webSearchConfig.contextSize,
          location: webSearchConfig.location,
        );

        builtInTools = [
          ...?builtInTools,
          webTool,
        ];
      }
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
      // Common parameters.
      stopSequences: config.stopSequences,
      user: config.user,
      serviceTier: config.serviceTier,
      // OpenAI-specific extensions using helper method.
      reasoningEffort: ReasoningEffort.fromString(
        getExtension<String>(config, LLMConfigKeys.reasoningEffort),
      ),
      jsonSchema: getExtension<StructuredOutputFormat>(
        config,
        LLMConfigKeys.jsonSchema,
      ),
      voice: getExtension<String>(config, LLMConfigKeys.voice),
      embeddingEncodingFormat: getExtension<String>(
        config,
        LLMConfigKeys.embeddingEncodingFormat,
      ),
      embeddingDimensions: getExtension<int>(
        config,
        LLMConfigKeys.embeddingDimensions,
      ),
      // Responses API configuration.
      useResponsesAPI:
          getExtension<bool>(config, LLMConfigKeys.useResponsesAPI) ?? false,
      previousResponseId:
          getExtension<String>(config, LLMConfigKeys.previousResponseId),
      builtInTools: getExtension<List<OpenAIBuiltInTool>>(
            config,
            LLMConfigKeys.builtInTools,
          ) ??
          builtInTools,
      originalConfig: config,
    );
  }

  /// Check if the model supports web search.
  bool _isSearchModel(String? model) {
    if (model == null) return false;
    return model.contains('search-preview') || model.contains('search');
  }

  /// Get the search-enabled version of a model.
  String _getSearchModel(String? model) {
    if (model == null) return 'gpt-4o-search-preview';

    // Map common models to their search variants.
    if (model.startsWith('gpt-4o')) {
      return 'gpt-4o-search-preview';
    } else if (model.startsWith('gpt-4o-mini')) {
      return 'gpt-4o-mini-search-preview';
    } else {
      // Default to gpt-4o-search-preview for other models.
      return 'gpt-4o-search-preview';
    }
  }
}

/// Helper to register the OpenAI provider factory with the global registry.
void registerOpenAIProvider() {
  LLMProviderRegistry.registerOrReplace(OpenAIProviderFactory());
}
