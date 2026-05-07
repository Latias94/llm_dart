part of 'openai_assistant_support.dart';

final class _OpenAIAssistantToolSupport {
  const _OpenAIAssistantToolSupport();

  List<AssistantTool> mergeTools(
    List<AssistantTool> currentTools,
    List<AssistantTool> toolsToAdd,
  ) {
    return [...currentTools, ...toolsToAdd];
  }

  List<AssistantTool> removeToolsByType(
    List<AssistantTool> currentTools,
    List<String> toolTypes,
  ) {
    return currentTools
        .where(
          (tool) => !toolTypes.contains(tool.type.value),
        )
        .toList();
  }

  AssistantTool parseToolFromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;

    switch (type) {
      case 'code_interpreter':
        return const CodeInterpreterTool();
      case 'file_search':
        return const FileSearchTool();
      case 'function':
        final functionData = json['function'] as Map<String, dynamic>;
        return AssistantFunctionTool(
          function: FunctionObject.fromJson(functionData),
        );
      default:
        throw ArgumentError('Unknown tool type: $type');
    }
  }
}
