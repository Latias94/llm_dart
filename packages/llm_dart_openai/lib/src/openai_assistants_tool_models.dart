import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_json_value.dart';

enum OpenAIAssistantToolType {
  codeInterpreter('code_interpreter'),
  fileSearch('file_search'),
  function('function'),
  raw('');

  const OpenAIAssistantToolType(this.value);

  final String value;

  static OpenAIAssistantToolType fromString(String value) {
    return switch (value) {
      'code_interpreter' => OpenAIAssistantToolType.codeInterpreter,
      'file_search' => OpenAIAssistantToolType.fileSearch,
      'function' => OpenAIAssistantToolType.function,
      _ => OpenAIAssistantToolType.raw,
    };
  }
}

abstract interface class OpenAIAssistantTool {
  OpenAIAssistantToolType get type;

  Map<String, Object?> toJson();
}

final class OpenAIAssistantCodeInterpreterTool implements OpenAIAssistantTool {
  const OpenAIAssistantCodeInterpreterTool();

  @override
  OpenAIAssistantToolType get type => OpenAIAssistantToolType.codeInterpreter;

  @override
  Map<String, Object?> toJson() {
    return {
      'type': type.value,
    };
  }
}

final class OpenAIAssistantFileSearchTool implements OpenAIAssistantTool {
  final int? maxNumResults;

  const OpenAIAssistantFileSearchTool({
    this.maxNumResults,
  });

  @override
  OpenAIAssistantToolType get type => OpenAIAssistantToolType.fileSearch;

  @override
  Map<String, Object?> toJson() {
    return {
      'type': type.value,
      if (maxNumResults != null)
        'file_search': {
          'max_num_results': maxNumResults,
        },
    };
  }
}

final class OpenAIAssistantFunctionTool implements OpenAIAssistantTool {
  final FunctionToolDefinition function;

  const OpenAIAssistantFunctionTool({
    required this.function,
  });

  @override
  OpenAIAssistantToolType get type => OpenAIAssistantToolType.function;

  @override
  Map<String, Object?> toJson() {
    return {
      'type': type.value,
      'function': openAIFunctionToolDefinitionToJson(function),
    };
  }
}

final class OpenAIAssistantRawTool implements OpenAIAssistantTool {
  final String rawType;
  final Map<String, Object?> json;

  OpenAIAssistantRawTool({
    required this.rawType,
    required Map<String, Object?> json,
  }) : json = Map.unmodifiable(json);

  @override
  OpenAIAssistantToolType get type => OpenAIAssistantToolType.raw;

  @override
  Map<String, Object?> toJson() {
    return {
      ...json,
      'type': rawType,
    };
  }
}

OpenAIAssistantTool openAIAssistantToolFromJson(Map<String, Object?> json) {
  final rawType = openAIRequiredNonEmptyString(
    json['type'],
    path: 'assistant_tool.type',
  );
  return switch (OpenAIAssistantToolType.fromString(rawType)) {
    OpenAIAssistantToolType.codeInterpreter =>
      const OpenAIAssistantCodeInterpreterTool(),
    OpenAIAssistantToolType.fileSearch => OpenAIAssistantFileSearchTool(
        maxNumResults: openAIOptionalInt(
          openAIOptionalMap(
            json['file_search'],
            path: 'assistant_tool.file_search',
          )?['max_num_results'],
          path: 'assistant_tool.file_search.max_num_results',
        ),
      ),
    OpenAIAssistantToolType.function => OpenAIAssistantFunctionTool(
        function: openAIFunctionToolDefinitionFromJson(
          openAIRequiredMap(json['function'], path: 'assistant_tool.function'),
        ),
      ),
    OpenAIAssistantToolType.raw => OpenAIAssistantRawTool(
        rawType: rawType,
        json: json,
      ),
  };
}

Map<String, Object?> openAIFunctionToolDefinitionToJson(
  FunctionToolDefinition function,
) {
  return {
    'name': function.name,
    if (function.description != null) 'description': function.description,
    'parameters': function.inputSchema.toJson(),
    if (function.strict != null) 'strict': function.strict,
  };
}

FunctionToolDefinition openAIFunctionToolDefinitionFromJson(
  Map<String, Object?> json,
) {
  final rawParameters = json['parameters'];
  return FunctionToolDefinition(
    name: openAIRequiredNonEmptyString(json['name'], path: 'function.name'),
    description: openAIOptionalString(
      json['description'],
      path: 'function.description',
    ),
    inputSchema: rawParameters == null
        ? ToolJsonSchema.object()
        : ToolJsonSchema.raw(
            openAIRequiredMap(rawParameters, path: 'function.parameters'),
          ),
    strict: openAIOptionalBool(json['strict'], path: 'function.strict'),
  );
}
