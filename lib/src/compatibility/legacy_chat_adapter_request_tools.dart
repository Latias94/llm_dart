part of 'legacy_chat_adapter.dart';

core.FunctionToolDefinition _convertTool(Tool tool) {
  if (tool.toolType != 'function') {
    throw UnsupportedError(
      'Only function tools can be bridged into the refactored language-model API.',
    );
  }

  return core.FunctionToolDefinition(
    name: tool.function.name,
    description: tool.function.description,
    inputSchema: core.ToolJsonSchema.raw(
      _normalizeMap(tool.function.parameters.toJson()),
    ),
  );
}

core.ToolChoice? _convertToolChoice(ToolChoice? toolChoice) {
  return switch (toolChoice) {
    null => null,
    AutoToolChoice() => const core.AutoToolChoice(),
    AnyToolChoice() => const core.RequiredToolChoice(),
    NoneToolChoice() => const core.NoneToolChoice(),
    SpecificToolChoice(:final toolName) => core.SpecificToolChoice(toolName),
  };
}
