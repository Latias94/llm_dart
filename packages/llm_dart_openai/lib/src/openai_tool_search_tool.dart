import 'openai_builtin_tool.dart';

enum OpenAIToolSearchExecution {
  server('server'),
  client('client');

  const OpenAIToolSearchExecution(this.value);

  final String value;
}

final class OpenAIToolSearchTool implements OpenAIBuiltInTool {
  final OpenAIToolSearchExecution? execution;
  final String? description;
  final Map<String, Object?>? parameters;

  const OpenAIToolSearchTool({
    this.execution,
    this.description,
    this.parameters,
  });

  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.toolSearch;

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'tool_search',
      if (execution != null) 'execution': execution!.value,
      if (description != null) 'description': description,
      if (parameters != null) 'parameters': parameters,
    };
  }
}
