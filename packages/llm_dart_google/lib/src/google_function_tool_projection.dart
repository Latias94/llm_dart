import 'package:llm_dart_provider/llm_dart_provider.dart';

Map<String, Object?> googleFunctionDeclarationsTool(
  List<FunctionToolDefinition> tools,
) {
  return {
    'functionDeclarations': [
      for (final tool in tools) googleFunctionDeclaration(tool),
    ],
  };
}

Map<String, Object?> googleFunctionDeclaration(
  FunctionToolDefinition tool,
) {
  return {
    'name': tool.name,
    'description': tool.description ?? '',
    'parameters': tool.inputSchema.toJson(),
  };
}

Map<String, Object?>? googleFunctionCallingToolConfig({
  required List<FunctionToolDefinition> tools,
  required ToolChoice? toolChoice,
  required bool includeServerSideToolInvocations,
}) {
  if (tools.isEmpty && !includeServerSideToolInvocations) {
    return null;
  }

  final functionCallingConfig = googleFunctionCallingConfig(
    tools: tools,
    toolChoice: toolChoice,
  );

  return {
    if (includeServerSideToolInvocations)
      'includeServerSideToolInvocations': true,
    if (functionCallingConfig != null)
      'functionCallingConfig': functionCallingConfig,
  };
}

Map<String, Object?>? googleFunctionCallingConfig({
  required List<FunctionToolDefinition> tools,
  required ToolChoice? toolChoice,
}) {
  if (tools.isEmpty) {
    return null;
  }

  final hasStrictTools = tools.any((tool) => tool.strict == true);
  String? mode;
  List<String>? allowedFunctionNames;

  switch (toolChoice) {
    case null:
      if (hasStrictTools) {
        mode = 'VALIDATED';
      }
    case AutoToolChoice():
      mode = hasStrictTools ? 'VALIDATED' : 'AUTO';
    case NoneToolChoice():
      mode = 'NONE';
    case RequiredToolChoice():
      mode = hasStrictTools ? 'VALIDATED' : 'ANY';
    case SpecificToolChoice(toolName: final toolName):
      mode = hasStrictTools ? 'VALIDATED' : 'ANY';
      allowedFunctionNames = [toolName];
  }

  if (mode == null) {
    return null;
  }

  return {
    'mode': mode,
    if (allowedFunctionNames != null)
      'allowedFunctionNames': allowedFunctionNames,
  };
}
