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
  var model = config.model;
  final webSearchEnabled = getLegacyProviderOption<bool>(
        config,
        LegacyProviderOptionNamespaces.openrouter,
        LegacyExtensionKeys.webSearchEnabled,
      ) ==
      true;
  final webSearchConfig = getLegacyProviderOption<WebSearchConfig>(
    config,
    LegacyProviderOptionNamespaces.openrouter,
    LegacyExtensionKeys.webSearchConfig,
  );
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
    jsonSchema: getLegacyProviderOption<StructuredOutputFormat>(
      config,
      LegacyProviderOptionNamespaces.openrouter,
      LegacyExtensionKeys.jsonSchema,
    ),
    stopSequences: config.stopSequences,
    user: config.user,
    serviceTier: config.serviceTier,
    useResponsesAPI: getLegacyProviderOption<bool>(
          config,
          LegacyProviderOptionNamespaces.openrouter,
          LegacyExtensionKeys.useResponsesApi,
        ) ??
        false,
    previousResponseId: getLegacyProviderOption<String>(
      config,
      LegacyProviderOptionNamespaces.openrouter,
      LegacyExtensionKeys.previousResponseId,
    ),
    builtInTools: getLegacyProviderOption<List<OpenAIBuiltInTool>>(
      config,
      LegacyProviderOptionNamespaces.openrouter,
      LegacyExtensionKeys.builtInTools,
    ),
    frequencyPenalty: getLegacyProviderOption<double>(
      config,
      LegacyProviderOptionNamespaces.openrouter,
      LegacyExtensionKeys.frequencyPenalty,
    ),
    presencePenalty: getLegacyProviderOption<double>(
      config,
      LegacyProviderOptionNamespaces.openrouter,
      LegacyExtensionKeys.presencePenalty,
    ),
    logitBias: getLegacyProviderOption<Map<String, double>>(
      config,
      LegacyProviderOptionNamespaces.openrouter,
      LegacyExtensionKeys.logitBias,
    ),
    seed: getLegacyProviderOption<int>(
      config,
      LegacyProviderOptionNamespaces.openrouter,
      LegacyExtensionKeys.seed,
    ),
    parallelToolCalls: getLegacyProviderOption<bool>(
      config,
      LegacyProviderOptionNamespaces.openrouter,
      LegacyExtensionKeys.parallelToolCalls,
    ),
    logprobs: getLegacyProviderOption<bool>(
      config,
      LegacyProviderOptionNamespaces.openrouter,
      LegacyExtensionKeys.logprobs,
    ),
    topLogprobs: getLegacyProviderOption<int>(
      config,
      LegacyProviderOptionNamespaces.openrouter,
      LegacyExtensionKeys.topLogprobs,
    ),
    verbosity: getLegacyProviderOption<String>(
      config,
      LegacyProviderOptionNamespaces.openrouter,
      LegacyExtensionKeys.verbosity,
    ),
  );
}

core.ProviderModelOptions buildCompatOpenRouterModelSettings(
  LLMConfig config,
) {
  final webSearchEnabled = getLegacyProviderOption<bool>(
        config,
        LegacyProviderOptionNamespaces.openrouter,
        LegacyExtensionKeys.webSearchEnabled,
      ) ==
      true;
  final webSearchConfig = getLegacyProviderOption<WebSearchConfig>(
    config,
    LegacyProviderOptionNamespaces.openrouter,
    LegacyExtensionKeys.webSearchConfig,
  );
  if ((webSearchEnabled || webSearchConfig != null) &&
      !config.model.endsWith(':online')) {
    return const modern_openai.OpenRouterChatModelSettings(
      search: modern_openai.OpenRouterSearchOptions.onlineModel(),
    );
  }

  return const modern_openai.OpenAIChatModelSettings();
}
