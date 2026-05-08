import 'package:llm_dart_openai/llm_dart_openai.dart' as modern_openai;

import '../../../../core/config.dart';
import '../../../../models/chat_models.dart';
import '../../../../providers/openai/builtin_tools.dart';
import '../../../../providers/openai/config.dart';
import '../../config/legacy_config_keys.dart';
import '../../config/legacy_openai_options.dart';
import '../../config/legacy_provider_options.dart';
import '../../compat_value_utils.dart';
import '../../compat_transport.dart';
import '../../legacy_chat_adapter.dart';

LLMConfig buildRootOpenAIChatBridgeConfig(OpenAIConfig config) {
  final extensions = <String, dynamic>{};
  if (config.jsonSchema case final jsonSchema?) {
    extensions[LegacyExtensionKeys.jsonSchema] = jsonSchema;
  }
  if (config.transportClient case final transportClient?) {
    extensions[LegacyExtensionKeys.customTransportClient] = transportClient;
  }

  final providerOptions = <String, dynamic>{
    if (config.reasoningEffort case final reasoningEffort?)
      LegacyExtensionKeys.reasoningEffort: reasoningEffort.value,
    LegacyExtensionKeys.useResponsesApi: config.useResponsesAPI,
    if (config.previousResponseId case final previousResponseId?)
      LegacyExtensionKeys.previousResponseId: previousResponseId,
    if (config.builtInTools case final builtInTools?)
      LegacyExtensionKeys.builtInTools: builtInTools,
    if (config.parallelToolCalls case final parallelToolCalls?)
      LegacyExtensionKeys.parallelToolCalls: parallelToolCalls,
    if (config.verbosity case final verbosity?)
      LegacyExtensionKeys.verbosity: verbosity,
  };
  extensions[legacyProviderOptionsBagKey] = {
    LegacyProviderOptionNamespaces.openai: providerOptions,
  };

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
    toolChoice: config.toolChoice,
    stopSequences: config.stopSequences,
    user: config.user,
    serviceTier: config.serviceTier,
    extensions: extensions,
  );
}

LegacyChatCapabilityAdapter buildCompatOpenAIChatBridge({
  required OpenAIConfig legacyConfig,
  required LLMConfig bridgeConfig,
  bool preferResponsesApi = true,
}) {
  final model = modern_openai.OpenAI(
    apiKey: bridgeConfig.apiKey!,
    baseUrl: bridgeConfig.baseUrl,
    transport: createCompatTransport(bridgeConfig),
  ).chatModel(
    bridgeConfig.model,
    settings: modern_openai.OpenAIChatModelSettings(
      useResponsesApi: preferResponsesApi,
    ),
  );

  return LegacyChatCapabilityAdapter(
    model: model,
    config: bridgeConfig,
    providerOptionsNamespace: LegacyProviderOptionNamespaces.openai,
    providerOptions: buildCompatOpenAIInvocationOptions(
      legacyConfig: legacyConfig,
      bridgeConfig: bridgeConfig,
    ),
  );
}

modern_openai.OpenAIGenerateTextOptions buildCompatOpenAIInvocationOptions({
  required OpenAIConfig legacyConfig,
  required LLMConfig bridgeConfig,
}) {
  final options = legacyProviderOptionView(
    bridgeConfig,
    LegacyProviderOptionNamespaces.openai,
  );
  final familyOptions = legacyOpenAIFamilyOptions(options);
  final hostedOptions = legacyOpenAIHostedOptions(options);
  final reasoningEffort =
      legacyConfig.reasoningEffort ?? hostedOptions.reasoningEffort;

  return modern_openai.OpenAIGenerateTextOptions(
    previousResponseId:
        legacyConfig.previousResponseId ?? familyOptions.previousResponseId,
    parallelToolCalls:
        legacyConfig.parallelToolCalls ?? familyOptions.parallelToolCalls,
    serviceTier:
        legacyConfig.serviceTier?.value ?? bridgeConfig.serviceTier?.value,
    user: legacyConfig.user ?? bridgeConfig.user,
    verbosity: legacyConfig.verbosity ?? familyOptions.verbosity,
    reasoningEffort: mapCompatOpenAIReasoningEffort(reasoningEffort),
    builtInTools: mapCompatOpenAIBuiltInTools(
      legacyConfig.builtInTools ?? familyOptions.builtInTools,
    ),
  );
}

modern_openai.OpenAIReasoningEffort? mapCompatOpenAIReasoningEffort(
  ReasoningEffort? effort,
) {
  return switch (effort) {
    null => null,
    ReasoningEffort.minimal => modern_openai.OpenAIReasoningEffort.minimal,
    ReasoningEffort.low => modern_openai.OpenAIReasoningEffort.low,
    ReasoningEffort.medium => modern_openai.OpenAIReasoningEffort.medium,
    ReasoningEffort.high => modern_openai.OpenAIReasoningEffort.high,
  };
}

List<modern_openai.OpenAIBuiltInTool>? mapCompatOpenAIBuiltInTools(
  List<OpenAIBuiltInTool>? tools,
) {
  if (tools == null || tools.isEmpty) {
    return null;
  }

  final mapped = <modern_openai.OpenAIBuiltInTool>[];
  for (final tool in tools) {
    switch (tool) {
      case OpenAIWebSearchTool():
        mapped.add(modern_openai.OpenAIBuiltInTools.webSearch());
      case OpenAIFileSearchTool(
          :final vectorStoreIds,
          :final parameters,
        ):
        mapped.add(
          modern_openai.OpenAIBuiltInTools.fileSearch(
            vectorStoreIds: vectorStoreIds,
            parameters: parameters == null
                ? null
                : compatNormalizeJsonValue(parameters) as Map<String, Object?>,
          ),
        );
      case OpenAIComputerUseTool(
          :final displayWidth,
          :final displayHeight,
          :final environment,
          :final parameters,
        ):
        mapped.add(
          modern_openai.OpenAIBuiltInTools.computerUse(
            displayWidth: displayWidth,
            displayHeight: displayHeight,
            environment: environment,
            parameters: parameters == null
                ? null
                : compatNormalizeJsonValue(parameters) as Map<String, Object?>,
          ),
        );
      default:
        break;
    }
  }

  return mapped.isEmpty ? null : mapped;
}
