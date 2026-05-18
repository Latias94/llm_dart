import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_beta_features.dart';
import 'anthropic_options.dart';
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
  _validateSpecificToolChoice(
    toolChoice: toolChoice,
    commonToolNames: commonToolNames,
  );
  final deferredToolNameSet = {
    for (final toolName in deferredToolNames)
      if (toolName.trim().isNotEmpty) toolName.trim(),
  };

  if (deferredToolNameSet.length != deferredToolNames.length) {
    warnings.add(
      const ModelWarning(
        type: ModelWarningType.compatibility,
        field: 'deferredToolNames',
        message:
            'Anthropic deferredToolNames contained duplicates or empty values. The request uses the normalized unique non-empty subset.',
      ),
    );
  }

  final unknownDeferredToolNames = deferredToolNameSet
      .where((toolName) => !commonToolNames.contains(toolName))
      .toList(growable: false)
    ..sort();
  if (unknownDeferredToolNames.isNotEmpty) {
    warnings.add(
      ModelWarning(
        type: ModelWarningType.compatibility,
        field: 'deferredToolNames',
        message:
            'Anthropic deferredToolNames only apply to common function tools. Ignoring unknown names: ${unknownDeferredToolNames.join(', ')}.',
      ),
    );
  }

  final hasToolSearchNativeTool = nativeTools.any(_isToolSearchNativeTool);
  if (deferredToolNameSet.isNotEmpty && !hasToolSearchNativeTool) {
    warnings.add(
      const ModelWarning(
        type: ModelWarningType.compatibility,
        field: 'deferredToolNames',
        message:
            'Anthropic deferredToolNames are set without a tool-search native tool. The defer_loading flags will still be encoded, but they are usually only useful with Anthropic tool-search or tool-reference flows.',
      ),
    );
  }

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
      throw UnsupportedError(
        'Anthropic extended thinking only supports AutoToolChoice or '
        'NoneToolChoice. Forced tool use is incompatible with thinking.',
      );
    case null:
    case AutoToolChoice():
    case NoneToolChoice():
      return;
  }
}

bool _isToolSearchNativeTool(AnthropicNativeTool tool) {
  return tool.name == 'tool_search_tool_regex' ||
      tool.name == 'tool_search_tool_bm25';
}

void _validateSpecificToolChoice({
  required ToolChoice? toolChoice,
  required Set<String> commonToolNames,
}) {
  if (toolChoice case SpecificToolChoice(toolName: final toolName)) {
    if (commonToolNames.contains(toolName)) {
      return;
    }

    throw UnsupportedError(
      'Anthropic SpecificToolChoice currently only supports declared common '
      'function tools. Selecting native or undeclared tools requires a '
      'provider-owned Anthropic tool-selection surface.',
    );
  }
}
