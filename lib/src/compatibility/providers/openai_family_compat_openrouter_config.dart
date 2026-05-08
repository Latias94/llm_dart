import 'package:llm_dart_openai/llm_dart_openai.dart' as modern_openai;
import 'package:llm_dart_provider/llm_dart_provider.dart' as core;

import '../../../core/config.dart';
import '../../../core/web_search.dart';
import '../../../models/tool_models.dart';
import '../../../providers/openai/builtin_tools.dart';
import '../../../providers/openai/config.dart';
import '../config/legacy_config_extensions.dart';
import '../config/legacy_provider_options.dart';
import 'community_provider_config_adapters.dart';

OpenAIConfig toCompatLegacyOpenRouterConfig(LLMConfig config) {
  final options = legacyProviderOptionView(
    config,
    LegacyProviderOptionNamespaces.openrouter,
  );
  var model = config.model;
  final webSearchEnabled =
      options.getWithFlatFallback<bool>(LegacyExtensionKeys.webSearchEnabled) ==
          true;
  final webSearchConfig = options.getWithFlatFallback<WebSearchConfig>(
      LegacyExtensionKeys.webSearchConfig);
  if ((webSearchEnabled || webSearchConfig != null) &&
      !model.endsWith(':online')) {
    model = '$model:online';
  }

  return OpenAIConfig(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    model: model,
    maxTokens: config.maxTokens,
    temperature: config.temperature,
    systemPrompt: config.systemPrompt,
    timeout: config.timeout,
    dioOverrides: createLegacyDioClientOverrides(config),
    transportClient: config.legacyTransportClient,
    topP: config.topP,
    topK: config.topK,
    tools: config.tools,
    toolChoice: config.toolChoice,
    jsonSchema: options.getWithFlatFallback<StructuredOutputFormat>(
      LegacyExtensionKeys.jsonSchema,
    ),
    stopSequences: config.stopSequences,
    user: config.user,
    serviceTier: config.serviceTier,
    useResponsesAPI: options
            .getWithFlatFallback<bool>(LegacyExtensionKeys.useResponsesApi) ??
        false,
    previousResponseId: options.getWithFlatFallback<String>(
      LegacyExtensionKeys.previousResponseId,
    ),
    builtInTools: options.getWithFlatFallback<List<OpenAIBuiltInTool>>(
      LegacyExtensionKeys.builtInTools,
    ),
    frequencyPenalty: options.getWithFlatFallback<double>(
      LegacyExtensionKeys.frequencyPenalty,
    ),
    presencePenalty: options.getWithFlatFallback<double>(
      LegacyExtensionKeys.presencePenalty,
    ),
    logitBias: options.getWithFlatFallback<Map<String, double>>(
      LegacyExtensionKeys.logitBias,
    ),
    seed: options.getWithFlatFallback<int>(LegacyExtensionKeys.seed),
    parallelToolCalls: options.getWithFlatFallback<bool>(
      LegacyExtensionKeys.parallelToolCalls,
    ),
    logprobs: options.getWithFlatFallback<bool>(LegacyExtensionKeys.logprobs),
    topLogprobs:
        options.getWithFlatFallback<int>(LegacyExtensionKeys.topLogprobs),
    verbosity:
        options.getWithFlatFallback<String>(LegacyExtensionKeys.verbosity),
  );
}

core.ProviderModelOptions buildCompatOpenRouterModelSettings(
  LLMConfig config,
) {
  final options = legacyProviderOptionView(
    config,
    LegacyProviderOptionNamespaces.openrouter,
  );
  final webSearchEnabled =
      options.getWithFlatFallback<bool>(LegacyExtensionKeys.webSearchEnabled) ==
          true;
  final webSearchConfig = options.getWithFlatFallback<WebSearchConfig>(
      LegacyExtensionKeys.webSearchConfig);
  if ((webSearchEnabled || webSearchConfig != null) &&
      !config.model.endsWith(':online')) {
    return const modern_openai.OpenRouterChatModelSettings(
      search: modern_openai.OpenRouterSearchOptions.onlineModel(),
    );
  }

  return const modern_openai.OpenAIChatModelSettings();
}
