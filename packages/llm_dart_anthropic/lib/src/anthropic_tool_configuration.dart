import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_beta_features.dart';
import 'anthropic_cache_options.dart';
import 'anthropic_tool_limitations.dart';
import 'anthropic_tools.dart';

final class AnthropicToolConfiguration {
  final List<Map<String, Object?>>? tools;
  final Map<String, Object?>? toolChoice;
  final List<String> betaFeatures;

  const AnthropicToolConfiguration({
    this.tools,
    this.toolChoice,
    this.betaFeatures = const [],
  });
}

AnthropicToolConfiguration resolveAnthropicToolConfiguration({
  required List<FunctionToolDefinition> tools,
  required List<AnthropicNativeTool> nativeTools,
  required ToolChoice? toolChoice,
  required List<String> deferredToolNames,
  required AnthropicCacheControl? toolsCacheControl,
  required List<ModelWarning> warnings,
}) {
  if ((tools.isEmpty && nativeTools.isEmpty) || toolChoice is NoneToolChoice) {
    return const AnthropicToolConfiguration();
  }

  final commonToolNames = {
    for (final tool in tools) tool.name,
  };
  validateAnthropicSpecificToolChoice(
    toolChoice: toolChoice,
    commonToolNames: commonToolNames,
  );
  final deferredToolNameSet = resolveAnthropicDeferredToolNames(
    deferredToolNames: deferredToolNames,
    commonToolNames: commonToolNames,
    nativeTools: nativeTools,
    warnings: warnings,
  );

  final encodedTools = <Map<String, Object?>>[
    for (final tool in tools)
      {
        'name': tool.name,
        if (tool.description != null) 'description': tool.description,
        'input_schema': tool.inputSchema.toJson(),
        if (tool.strict != null) 'strict': tool.strict,
        if (deferredToolNameSet.contains(tool.name)) 'defer_loading': true,
      },
    for (final tool in nativeTools) tool.toJson(),
  ];

  if (toolsCacheControl != null && encodedTools.isNotEmpty) {
    encodedTools[encodedTools.length - 1] = {
      ...encodedTools.last,
      'cache_control': toolsCacheControl.toJson(),
    };
  }

  final betaFeatures = <String>{};
  if (toolsCacheControl != null && encodedTools.isNotEmpty) {
    betaFeatures.add(anthropicExtendedCacheTtlBeta);
  }

  final encodedToolChoice = switch (toolChoice) {
    null => null,
    AutoToolChoice() => const {
        'type': 'auto',
      },
    RequiredToolChoice() => const {
        'type': 'any',
      },
    SpecificToolChoice(toolName: final toolName) => {
        'type': 'tool',
        'name': toolName,
      },
    NoneToolChoice() => null,
  };

  return AnthropicToolConfiguration(
    tools: encodedTools,
    toolChoice: encodedToolChoice,
    betaFeatures: sortedAnthropicBetaFeatures(betaFeatures),
  );
}

void validateAnthropicThinkingCompatibleToolChoice({
  required bool extendedThinking,
  required ToolChoice? toolChoice,
}) {
  if (!extendedThinking) {
    return;
  }

  switch (toolChoice) {
    case RequiredToolChoice():
    case SpecificToolChoice():
      throw unsupportedAnthropicThinkingToolChoice();
    case null:
    case AutoToolChoice():
    case NoneToolChoice():
      return;
  }
}
