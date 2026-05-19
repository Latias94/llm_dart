import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_tools.dart';

Set<String> resolveAnthropicDeferredToolNames({
  required List<String> deferredToolNames,
  required Set<String> commonToolNames,
  required List<AnthropicNativeTool> nativeTools,
  required List<ModelWarning> warnings,
}) {
  final deferredToolNameSet = {
    for (final toolName in deferredToolNames)
      if (toolName.trim().isNotEmpty) toolName.trim(),
  };

  if (deferredToolNameSet.length != deferredToolNames.length) {
    warnings.add(anthropicDeferredToolNamesNormalizedWarning);
  }

  final unknownDeferredToolNames = deferredToolNameSet
      .where((toolName) => !commonToolNames.contains(toolName))
      .toList(growable: false)
    ..sort();
  if (unknownDeferredToolNames.isNotEmpty) {
    warnings.add(
      unknownAnthropicDeferredToolNamesWarning(unknownDeferredToolNames),
    );
  }

  if (deferredToolNameSet.isNotEmpty &&
      !hasAnthropicToolSearchNativeTool(nativeTools)) {
    warnings.add(anthropicDeferredToolNamesWithoutSearchWarning);
  }

  return deferredToolNameSet;
}

void validateAnthropicSpecificToolChoice({
  required ToolChoice? toolChoice,
  required Set<String> commonToolNames,
}) {
  if (toolChoice case SpecificToolChoice(toolName: final toolName)) {
    if (commonToolNames.contains(toolName)) {
      return;
    }

    throw unsupportedAnthropicSpecificToolChoice();
  }
}

bool hasAnthropicToolSearchNativeTool(List<AnthropicNativeTool> nativeTools) {
  return nativeTools.any(isAnthropicToolSearchNativeTool);
}

bool isAnthropicToolSearchNativeTool(AnthropicNativeTool tool) {
  return tool.name == 'tool_search_tool_regex' ||
      tool.name == 'tool_search_tool_bm25';
}

UnsupportedError unsupportedAnthropicThinkingToolChoice() {
  return UnsupportedError(
    'Anthropic extended thinking only supports AutoToolChoice or '
    'NoneToolChoice. Forced tool use is incompatible with thinking.',
  );
}

UnsupportedError unsupportedAnthropicSpecificToolChoice() {
  return UnsupportedError(
    'Anthropic SpecificToolChoice currently only supports declared common '
    'function tools. Selecting native or undeclared tools requires a '
    'provider-owned Anthropic tool-selection surface.',
  );
}

const anthropicDeferredToolNamesNormalizedWarning = ModelWarning(
  type: ModelWarningType.compatibility,
  field: 'deferredToolNames',
  message:
      'Anthropic deferredToolNames contained duplicates or empty values. The request uses the normalized unique non-empty subset.',
);

const anthropicDeferredToolNamesWithoutSearchWarning = ModelWarning(
  type: ModelWarningType.compatibility,
  field: 'deferredToolNames',
  message:
      'Anthropic deferredToolNames are set without a tool-search native tool. The defer_loading flags will still be encoded, but they are usually only useful with Anthropic tool-search or tool-reference flows.',
);

ModelWarning unknownAnthropicDeferredToolNamesWarning(
  List<String> toolNames,
) {
  return ModelWarning(
    type: ModelWarningType.compatibility,
    field: 'deferredToolNames',
    message:
        'Anthropic deferredToolNames only apply to common function tools. Ignoring unknown names: ${toolNames.join(', ')}.',
  );
}
