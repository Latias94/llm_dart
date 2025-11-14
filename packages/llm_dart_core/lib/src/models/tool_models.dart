/// Represents a parameter in a function tool
class ParameterProperty {
  /// The type of the parameter (e.g. "string", "number", "array", etc)
  final String propertyType;

  /// Description of what the parameter does
  final String description;

  /// When type is "array", this defines the type of the array items
  final ParameterProperty? items;

  /// When type is "enum", this defines the possible values for the parameter
  final List<String>? enumList;

  /// When type is "object", this defines the properties of the object
  final Map<String, ParameterProperty>? properties;

  /// When type is "object", this defines which properties are required
  final List<String>? required;

  const ParameterProperty({
    required this.propertyType,
    required this.description,
    this.items,
    this.enumList,
    this.properties,
    this.required,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'type': propertyType,
      'description': description,
    };

    if (items != null) {
      json['items'] = items!.toJson();
    }

    if (enumList != null) {
      json['enum'] = enumList;
    }

    if (properties != null) {
      json['properties'] =
          properties!.map((key, value) => MapEntry(key, value.toJson()));
    }

    if (required != null) {
      json['required'] = required;
    }

    return json;
  }

  factory ParameterProperty.fromJson(Map<String, dynamic> json) =>
      ParameterProperty(
        propertyType: json['type'] as String,
        description: json['description'] as String,
        items: json['items'] != null
            ? ParameterProperty.fromJson(json['items'] as Map<String, dynamic>)
            : null,
        enumList: json['enum'] != null
            ? List<String>.from(json['enum'] as List)
            : null,
        properties: json['properties'] != null
            ? (json['properties'] as Map<String, dynamic>).map(
                (key, value) => MapEntry(
                  key,
                  ParameterProperty.fromJson(value as Map<String, dynamic>),
                ),
              )
            : null,
        required: json['required'] != null
            ? List<String>.from(json['required'] as List)
            : null,
      );
}

/// Represents the parameters schema for a function tool
class ParametersSchema {
  /// The type of the parameters object (usually "object")
  final String schemaType;

  /// Map of parameter names to their properties
  final Map<String, ParameterProperty> properties;

  /// List of required parameter names
  final List<String> required;

  const ParametersSchema({
    required this.schemaType,
    required this.properties,
    required this.required,
  });

  Map<String, dynamic> toJson() => {
        'type': schemaType,
        'properties':
            properties.map((key, value) => MapEntry(key, value.toJson())),
        'required': required,
      };

  factory ParametersSchema.fromJson(Map<String, dynamic> json) =>
      ParametersSchema(
        schemaType: json['type'] as String,
        properties: (json['properties'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(
            key,
            ParameterProperty.fromJson(value as Map<String, dynamic>),
          ),
        ),
        required: List<String>.from(json['required'] as List),
      );
}

/// Represents a function definition for a tool
class FunctionTool {
  /// The name of the function
  final String name;

  /// Description of what the function does
  final String description;

  /// The parameters schema for the function
  final ParametersSchema parameters;

  const FunctionTool({
    required this.name,
    required this.description,
    required this.parameters,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'parameters': parameters.toJson(),
      };

  factory FunctionTool.fromJson(Map<String, dynamic> json) => FunctionTool(
        name: json['name'] as String,
        description: json['description'] as String,
        parameters: ParametersSchema.fromJson(
          json['parameters'] as Map<String, dynamic>,
        ),
      );
}

/// Represents a function object for assistants (similar to FunctionTool but with optional parameters)
class FunctionObject {
  /// The name of the function
  final String name;

  /// Description of what the function does
  final String? description;

  /// The parameters schema for the function (optional for assistants)
  final Map<String, dynamic>? parameters;

  /// Whether to enable strict schema adherence
  final bool? strict;

  const FunctionObject({
    required this.name,
    this.description,
    this.parameters,
    this.strict,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'name': name};

    if (description != null) {
      json['description'] = description;
    }

    if (parameters != null) {
      json['parameters'] = parameters;
    }

    if (strict != null) {
      json['strict'] = strict;
    }

    return json;
  }

  factory FunctionObject.fromJson(Map<String, dynamic> json) => FunctionObject(
        name: json['name'] as String,
        description: json['description'] as String?,
        parameters: json['parameters'] as Map<String, dynamic>?,
        strict: json['strict'] as bool?,
      );
}

/// Represents a tool that can be used in chat
class Tool {
  /// The type of tool (e.g. "function")
  final String toolType;

  /// The function definition if this is a function tool
  final FunctionTool function;

  const Tool({required this.toolType, required this.function});

  Map<String, dynamic> toJson() => {
        'type': toolType,
        'function': function.toJson(),
      };

  factory Tool.fromJson(Map<String, dynamic> json) => Tool(
        toolType: json['type'] as String,
        function:
            FunctionTool.fromJson(json['function'] as Map<String, dynamic>),
      );

  /// Create a function tool
  factory Tool.function({
    required String name,
    required String description,
    required ParametersSchema parameters,
  }) =>
      Tool(
        toolType: 'function',
        function: FunctionTool(
          name: name,
          description: description,
          parameters: parameters,
        ),
      );
}

/// Tool choice determines how the LLM uses available tools.
/// The behavior is standardized across different LLM providers.
///
/// **API References:**
/// - OpenAI: https://platform.openai.com/docs/guides/tools
/// - Anthropic: https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/overview
/// - xAI: https://docs.x.ai/docs/guides/function-calling
sealed class ToolChoice {
  const ToolChoice();

  Map<String, dynamic> toJson();

  /// Convert to OpenAI format
  Map<String, dynamic> toOpenAIJson() => toJson();

  /// Convert to Anthropic format
  String toAnthropicJson() {
    return switch (this) {
      AutoToolChoice() => 'auto',
      AnyToolChoice() => 'any',
      NoneToolChoice() => 'none',
      SpecificToolChoice(toolName: final name) =>
        '{"type": "tool", "name": "$name"}',
    };
  }

  /// Convert to xAI format (OpenAI-compatible)
  Map<String, dynamic> toXAIJson() => toOpenAIJson();
}

/// Model can use any tool, but it must use at least one.
/// This is useful when you want to force the model to use tools.
///
/// Maps to:
/// - OpenAI: `{"type": "required"}`
/// - Anthropic: `"any"` or `{"type": "any", "disable_parallel_tool_use": true}`
/// - xAI: `{"type": "required"}`
class AnyToolChoice extends ToolChoice {
  /// Whether to disable parallel tool use (Anthropic only)
  final bool? disableParallelToolUse;

  const AnyToolChoice({this.disableParallelToolUse});

  @override
  Map<String, dynamic> toJson() => {'type': 'required'};

  @override
  String toAnthropicJson() {
    if (disableParallelToolUse == true) {
      return '{"type": "any", "disable_parallel_tool_use": true}';
    }
    return 'any';
  }
}

/// Model can use any tool, and may elect to use none.
/// This is the default behavior and gives the model flexibility.
///
/// Maps to:
/// - OpenAI: `{"type": "auto"}`
/// - Anthropic: `"auto"` or `{"type": "auto", "disable_parallel_tool_use": true}`
/// - xAI: `{"type": "auto"}`
class AutoToolChoice extends ToolChoice {
  /// Whether to disable parallel tool use (Anthropic only)
  final bool? disableParallelToolUse;

  const AutoToolChoice({this.disableParallelToolUse});

  @override
  Map<String, dynamic> toJson() => {'type': 'auto'};

  @override
  String toAnthropicJson() {
    if (disableParallelToolUse == true) {
      return '{"type": "auto", "disable_parallel_tool_use": true}';
    }
    return 'auto';
  }
}

/// Model must use the specified tool and only the specified tool.
/// The string parameter is the name of the required tool.
/// This is useful when you want the model to call a specific function.
///
/// Maps to:
/// - OpenAI: `{"type": "function", "function": {"name": "tool_name"}}`
/// - Anthropic: `{"type": "tool", "name": "tool_name"}` or with disable_parallel_tool_use
/// - xAI: `{"type": "function", "function": {"name": "tool_name"}}`
class SpecificToolChoice extends ToolChoice {
  final String toolName;

  /// Whether to disable parallel tool use (Anthropic only)
  final bool? disableParallelToolUse;

  const SpecificToolChoice(this.toolName, {this.disableParallelToolUse});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'function',
        'function': {'name': toolName},
      };

  @override
  String toAnthropicJson() {
    if (disableParallelToolUse == true) {
      return '{"type": "tool", "name": "$toolName", "disable_parallel_tool_use": true}';
    }
    return '{"type": "tool", "name": "$toolName"}';
  }
}

/// Explicitly disables the use of tools.
/// The model will not use any tools even if they are provided.
///
/// Maps to:
/// - OpenAI: `{"type": "none"}`
/// - Anthropic: `"none"`
/// - xAI: `{"type": "none"}`
class NoneToolChoice extends ToolChoice {
  const NoneToolChoice();

  @override
  Map<String, dynamic> toJson() => {'type': 'none'};

  @override
  String toAnthropicJson() => 'none';
}

/// Defines rules for structured output responses based on OpenAI's structured output requirements.
///
/// **API Reference:** https://platform.openai.com/docs/guides/structured-outputs
class StructuredOutputFormat {
  /// Name of the schema
  final String name;

  /// The description of the schema
  final String? description;

  /// The JSON schema for the structured output
  final Map<String, dynamic>? schema;

  /// Whether to enable strict schema adherence
  final bool? strict;

  const StructuredOutputFormat({
    required this.name,
    this.description,
    this.schema,
    this.strict,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'name': name};

    if (description != null) {
      json['description'] = description;
    }

    if (schema != null) {
      json['schema'] = schema;
    }

    if (strict != null) {
      json['strict'] = strict;
    }

    return json;
  }

  /// Convert to OpenAI response_format
  Map<String, dynamic> toOpenAIResponseFormat() => {
        'type': 'json_schema',
        'json_schema': toJson(),
      };

  factory StructuredOutputFormat.fromJson(Map<String, dynamic> json) =>
      StructuredOutputFormat(
        name: json['name'] as String,
        description: json['description'] as String?,
        schema: json['schema'] as Map<String, dynamic>?,
        strict: json['strict'] as bool?,
      );
}

/// Tool execution result that can be returned to the model
class ToolResult {
  /// The ID of the tool call this result corresponds to
  final String toolCallId;

  /// The result content (can be text, JSON, or error message)
  final String content;

  /// Whether this result represents an error
  final bool isError;

  /// Optional metadata about the execution
  final Map<String, dynamic>? metadata;

  const ToolResult({
    required this.toolCallId,
    required this.content,
    this.isError = false,
    this.metadata,
  });

  /// Create a successful tool result
  factory ToolResult.success({
    required String toolCallId,
    required String content,
    Map<String, dynamic>? metadata,
  }) =>
      ToolResult(
        toolCallId: toolCallId,
        content: content,
        isError: false,
        metadata: metadata,
      );

  /// Create an error tool result
  factory ToolResult.error({
    required String toolCallId,
    required String errorMessage,
    Map<String, dynamic>? metadata,
  }) =>
      ToolResult(
        toolCallId: toolCallId,
        content: errorMessage,
        isError: true,
        metadata: metadata,
      );

  Map<String, dynamic> toJson() => {
        'tool_call_id': toolCallId,
        'content': content,
        'is_error': isError,
        if (metadata != null) 'metadata': metadata,
      };

  factory ToolResult.fromJson(Map<String, dynamic> json) => ToolResult(
        toolCallId: json['tool_call_id'] as String,
        content: json['content'] as String,
        isError: json['is_error'] as bool? ?? false,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

/// Parallel tool execution configuration
class ParallelToolConfig {
  /// Maximum number of tools to execute in parallel
  final int maxParallel;

  /// Timeout for individual tool execution
  final Duration? toolTimeout;

  /// Whether to continue execution if one tool fails
  final bool continueOnError;

  const ParallelToolConfig({
    this.maxParallel = 5,
    this.toolTimeout,
    this.continueOnError = true,
  });

  Map<String, dynamic> toJson() => {
        'max_parallel': maxParallel,
        if (toolTimeout != null) 'tool_timeout_ms': toolTimeout!.inMilliseconds,
        'continue_on_error': continueOnError,
      };

  factory ParallelToolConfig.fromJson(Map<String, dynamic> json) =>
      ParallelToolConfig(
        maxParallel: json['max_parallel'] as int? ?? 5,
        toolTimeout: json['tool_timeout_ms'] != null
            ? Duration(milliseconds: json['tool_timeout_ms'] as int)
            : null,
        continueOnError: json['continue_on_error'] as bool? ?? true,
      );
}
