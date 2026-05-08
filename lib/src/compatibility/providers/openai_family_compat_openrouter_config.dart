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
      options.get<bool>(LegacyExtensionKeys.webSearchEnabled) == true;
  final webSearchConfig =
      options.get<WebSearchConfig>(LegacyExtensionKeys.webSearchConfig);
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
    jsonSchema: options.get<StructuredOutputFormat>(
      LegacyExtensionKeys.jsonSchema,
    ),
    stopSequences: config.stopSequences,
    user: config.user,
    serviceTier: config.serviceTier,
    useResponsesAPI:
        options.get<bool>(LegacyExtensionKeys.useResponsesApi) ?? false,
    previousResponseId: options.get<String>(
      LegacyExtensionKeys.previousResponseId,
    ),
    builtInTools: options.get<List<OpenAIBuiltInTool>>(
      LegacyExtensionKeys.builtInTools,
    ),
    frequencyPenalty: options.get<double>(
      LegacyExtensionKeys.frequencyPenalty,
    ),
    presencePenalty: options.get<double>(
      LegacyExtensionKeys.presencePenalty,
    ),
    logitBias: options.get<Map<String, double>>(
      LegacyExtensionKeys.logitBias,
    ),
    seed: options.get<int>(LegacyExtensionKeys.seed),
    parallelToolCalls: options.get<bool>(
      LegacyExtensionKeys.parallelToolCalls,
    ),
    logprobs: options.get<bool>(LegacyExtensionKeys.logprobs),
    topLogprobs: options.get<int>(LegacyExtensionKeys.topLogprobs),
    verbosity: options.get<String>(LegacyExtensionKeys.verbosity),
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
      options.get<bool>(LegacyExtensionKeys.webSearchEnabled) == true;
  final webSearchConfig =
      options.get<WebSearchConfig>(LegacyExtensionKeys.webSearchConfig);
  if ((webSearchEnabled || webSearchConfig != null) &&
      !config.model.endsWith(':online')) {
    return const modern_openai.OpenRouterChatModelSettings(
      search: modern_openai.OpenRouterSearchOptions.onlineModel(),
    );
  }

  return const modern_openai.OpenAIChatModelSettings();
}
