import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_beta_features.dart';
import 'anthropic_cache_options.dart';
import 'anthropic_function_tool_options.dart';
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
  required Map<String, AnthropicFunctionToolOptions>? functionToolOptions,
  required bool defaultEagerInputStreaming,
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
  final functionToolOptionsByName = resolveAnthropicFunctionToolOptions(
    optionsByToolName: functionToolOptions,
    commonToolNames: commonToolNames,
    warnings: warnings,
  );

  final encodedTools = <Map<String, Object?>>[
    for (final tool in tools)
      _encodeFunctionTool(
        tool,
        options: functionToolOptionsByName[tool.name],
        deferredToolNames: deferredToolNameSet,
        defaultEagerInputStreaming: defaultEagerInputStreaming,
      ),
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
  if (functionToolOptionsByName.values.any(
    (options) => options.usesAdvancedToolUse,
  )) {
    betaFeatures.add(anthropicAdvancedToolUseBeta);
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

Map<String, Object?> _encodeFunctionTool(
  FunctionToolDefinition tool, {
  required AnthropicFunctionToolOptions? options,
  required Set<String> deferredToolNames,
  required bool defaultEagerInputStreaming,
}) {
  final deferLoading = options?.deferLoading ??
      (deferredToolNames.contains(tool.name) ? true : null);
  final eagerInputStreaming =
      options?.eagerInputStreaming ?? defaultEagerInputStreaming;
  final allowedCallers = options?.allowedCallers;
  final inputExamples = options?.inputExamples;

  return {
    'name': tool.name,
    if (tool.description != null) 'description': tool.description,
    'input_schema': tool.inputSchema.toJson(),
    if (tool.strict != null) 'strict': tool.strict,
    if (deferLoading != null) 'defer_loading': deferLoading,
    if (eagerInputStreaming) 'eager_input_streaming': true,
    if (allowedCallers != null && allowedCallers.isNotEmpty)
      'allowed_callers': [
        for (final caller in allowedCallers) caller.value,
      ],
    if (inputExamples != null && inputExamples.isNotEmpty)
      'input_examples': [
        for (final example in inputExamples) example.input,
      ],
  };
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
