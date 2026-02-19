import '../core/provider_options.dart';

/// JSON Schema (AI SDK v3 style).
///
/// In upstream AI SDK, function tools carry `inputSchema: JSONSchema7`.
/// In Dart we represent it as a JSON-like map for maximum interoperability.
typedef JsonSchema = Map<String, dynamic>;

/// Represents a function definition for a tool
class FunctionTool {
  /// The name of the function
  final String name;

  /// Description of what the function does
  final String? description;

  /// JSON schema for the tool input (AI SDK v3 `inputSchema`).
  final JsonSchema inputSchema;

  const FunctionTool({
    required this.name,
    this.description,
    required this.inputSchema,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null && description!.trim().isNotEmpty)
          'description': description,
        'inputSchema': inputSchema,
      };

  factory FunctionTool.fromJson(Map<String, dynamic> json) => FunctionTool(
        name: json['name'] as String,
        description: json['description'] as String?,
        inputSchema: (json['inputSchema'] as Map?)?.cast<String, dynamic>() ??
            (json['parameters'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
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

  /// Optional strict mode hint (provider-dependent).
  ///
  /// - OpenAI: forwarded as `function.strict` (Chat Completions) or `strict`
  ///   (Responses API) when supported.
  /// - Anthropic: forwarded as `strict` for structured outputs (beta-gated).
  final bool? strict;

  /// Optional tool input examples (provider-dependent).
  ///
  /// Anthropic supports `input_examples` (beta-gated).
  final List<Map<String, dynamic>>? inputExamples;

  /// Optional provider-specific tool options (provider-dependent).
  ///
  /// This mirrors Vercel AI SDK where tool definitions can carry namespaced
  /// provider options (e.g. `providerOptions.anthropic.allowedCallers`).
  final ProviderOptions providerOptions;

  const Tool({
    required this.toolType,
    required this.function,
    this.strict,
    this.inputExamples,
    this.providerOptions = const {},
  });

  /// AI SDK v3-style tool JSON (flattened).
  ///
  /// Providers are responsible for mapping this representation into their
  /// wire formats (e.g. OpenAI Chat Completions vs Responses API).
  Map<String, dynamic> toJson() => {
        'type': toolType,
        'name': function.name,
        if (function.description != null &&
            function.description!.trim().isNotEmpty)
          'description': function.description,
        'inputSchema': function.inputSchema,
        if (strict != null) 'strict': strict,
        if (inputExamples != null && inputExamples!.isNotEmpty)
          'inputExamples': inputExamples,
        if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
      };

  /// OpenAI Chat Completions / Assistants tool JSON (nested `function` object).
  Map<String, dynamic> toOpenAIChatCompletionsJson() => {
        'type': toolType,
        'function': {
          'name': function.name,
          if (function.description != null &&
              function.description!.trim().isNotEmpty)
            'description': function.description,
          // OpenAI expects `parameters` (JSON Schema object).
          'parameters': function.inputSchema,
          if (strict != null) 'strict': strict,
        },
      };

  /// OpenAI Responses API tool JSON (flattened `name` + `parameters`).
  Map<String, dynamic> toOpenAIResponsesJson() => {
        'type': toolType,
        'name': function.name,
        if (function.description != null &&
            function.description!.trim().isNotEmpty)
          'description': function.description,
        'parameters': function.inputSchema,
        if (strict != null) 'strict': strict,
      };

  factory Tool.fromJson(Map<String, dynamic> json) {
    final functionRaw = json['function'];
    final hasNestedFunction = functionRaw != null;

    final functionMap = hasNestedFunction
        ? functionRaw is Map<String, dynamic>
            ? functionRaw
            : functionRaw is Map
                ? Map<String, dynamic>.from(functionRaw)
                : const <String, dynamic>{}
        : const <String, dynamic>{};

    final strict = hasNestedFunction ? functionMap['strict'] : json['strict'];

    List<Map<String, dynamic>>? parseExamples(dynamic raw) {
      if (raw is! List) return null;
      final result = <Map<String, dynamic>>[];
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          result.add(item);
        } else if (item is Map) {
          result.add(Map<String, dynamic>.from(item));
        }
      }
      return result.isEmpty ? null : result;
    }

    ProviderOptions parseProviderOptions(dynamic raw) {
      if (raw is ProviderOptions) return raw;
      if (raw is! Map) return const {};
      final result = <String, Map<String, dynamic>>{};
      for (final entry in raw.entries) {
        final key = entry.key;
        if (key is! String) continue;
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          result[key] = value;
        } else if (value is Map) {
          result[key] = Map<String, dynamic>.from(value);
        }
      }
      return result.isEmpty ? const {} : result;
    }

    final toolType = (json['type'] as String?) ?? (json['toolType'] as String?);
    if (toolType == null || toolType.trim().isEmpty) {
      throw ArgumentError.value(json, 'json', 'Tool requires type/toolType.');
    }

    // Accept both AI SDK v3 flattened tool JSON and OpenAI-style nested tool JSON.
    final name =
        (hasNestedFunction ? functionMap['name'] : json['name']) as String?;
    if (name == null || name.trim().isEmpty) {
      throw ArgumentError.value(json, 'json', 'Tool requires name.');
    }

    final description = (hasNestedFunction
        ? functionMap['description']
        : json['description']) as String?;

    final inputSchemaRaw = hasNestedFunction
        ? (functionMap['inputSchema'] ?? functionMap['parameters'])
        : (json['inputSchema'] ?? json['parameters']);
    final inputSchema = inputSchemaRaw is Map<String, dynamic>
        ? inputSchemaRaw
        : inputSchemaRaw is Map
            ? Map<String, dynamic>.from(inputSchemaRaw)
            : const <String, dynamic>{};

    return Tool(
      toolType: toolType,
      function: FunctionTool(
        name: name,
        description: description,
        inputSchema: inputSchema,
      ),
      strict: strict is bool ? strict : null,
      inputExamples: parseExamples(
        json['inputExamples'] ?? json['input_examples'],
      ),
      providerOptions: parseProviderOptions(json['providerOptions']),
    );
  }

  /// Create a function tool
  factory Tool.function({
    required String name,
    required String description,
    required JsonSchema inputSchema,
    bool? strict,
    List<Map<String, dynamic>>? inputExamples,
    ProviderOptions providerOptions = const {},
  }) =>
      Tool(
        toolType: 'function',
        function: FunctionTool(
          name: name,
          description: description,
          inputSchema: inputSchema,
        ),
        strict: strict,
        inputExamples: inputExamples,
        providerOptions: providerOptions,
      );
}

/// A provider-executed tool (aka "built-in tool" / "provider-native tool").
///
/// Unlike [Tool] / [FunctionTool], provider tools are **not executed locally**.
/// They are configured and executed by the provider (e.g. web search, file
/// search, computer use, grounding).
///
/// Design notes:
/// - [id] should be stable and versionable (Vercel-style), e.g.
///   `openai.web_search_preview`, `anthropic.web_search_20250305`,
///   `google.google_search`.
/// - [options] is a JSON-like map that can carry provider-specific tool config.
class ProviderTool {
  /// Stable, versionable tool identifier.
  final String id;

  /// Optional user-facing tool name.
  ///
  /// This mirrors the Vercel AI SDK `name` field for provider-native tools.
  /// When present, streaming parsers should prefer this value when emitting
  /// canonical v3 `toolName` fields for provider-executed tool calls.
  ///
  /// If omitted, implementations should fall back to a provider-derived name
  /// (e.g. request tool type or id suffix).
  final String? name;

  /// Provider tool arguments (JSON-like), upstream name: `args`.
  final Map<String, dynamic> args;

  /// Whether this provider tool may return its results in a later step/turn.
  ///
  /// This mirrors the Vercel AI SDK `supportsDeferredResults` flag for provider
  /// tools (e.g. programmatic tool calling scenarios such as code execution).
  ///
  /// Orchestration layers may use this signal to decide whether to continue a
  /// multi-step loop even when no client-side tool calls are pending.
  final bool supportsDeferredResults;

  const ProviderTool({
    required this.id,
    this.name,
    this.args = const {},
    this.supportsDeferredResults = false,
  });

  /// Best-effort provider id inference from `[providerId].[toolName...]`.
  ///
  /// Returns `null` if [id] does not contain a `.`.
  String? get inferredProviderId {
    final dot = id.indexOf('.');
    if (dot <= 0) return null;
    return id.substring(0, dot);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (name != null && name!.isNotEmpty) 'name': name,
        if (args.isNotEmpty) 'args': args,
        if (supportsDeferredResults) 'supportsDeferredResults': true,
      };

  factory ProviderTool.fromJson(Map<String, dynamic> json) => ProviderTool(
        id: json['id'] as String,
        name: json['name'] as String?,
        args: (json['args'] as Map?)?.cast<String, dynamic>() ??
            (json['options'] as Map?)?.cast<String, dynamic>() ??
            const {},
        supportsDeferredResults: json['supportsDeferredResults'] == true,
      );

  @override
  String toString() =>
      'ProviderTool(id: $id, name: $name, args: $args, supportsDeferredResults: $supportsDeferredResults)';
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

  /// The tool output payload (JSON-like).
  ///
  /// This is aligned with AI SDK v3 `tool-result.result`, i.e. a JSON value.
  /// For simple tools, this can be a string/number/bool/map/list/null.
  final Object? result;

  /// Whether this result represents an error
  final bool isError;

  /// Optional metadata about the execution
  final Map<String, dynamic>? metadata;

  const ToolResult({
    required this.toolCallId,
    required this.result,
    this.isError = false,
    this.metadata,
  });

  /// Create a successful tool result
  factory ToolResult.success({
    required String toolCallId,
    required Object? result,
    Map<String, dynamic>? metadata,
  }) =>
      ToolResult(
        toolCallId: toolCallId,
        result: result,
        isError: false,
        metadata: metadata,
      );

  /// Create an error tool result
  factory ToolResult.error({
    required String toolCallId,
    required Object? error,
    Map<String, dynamic>? metadata,
  }) =>
      ToolResult(
        toolCallId: toolCallId,
        result: error,
        isError: true,
        metadata: metadata,
      );

  Map<String, dynamic> toJson() => {
        'tool_call_id': toolCallId,
        'result': result,
        'is_error': isError,
        if (metadata != null) 'metadata': metadata,
      };

  factory ToolResult.fromJson(Map<String, dynamic> json) {
    final toolCallId =
        (json['tool_call_id'] as String?) ?? (json['toolCallId'] as String?);
    if (toolCallId == null || toolCallId.trim().isEmpty) {
      throw ArgumentError.value(
        json,
        'json',
        'ToolResult requires tool_call_id/toolCallId',
      );
    }

    // Backward compatibility: older encodings used `content` as a string.
    final result =
        json.containsKey('result') ? json['result'] : json['content'];

    return ToolResult(
      toolCallId: toolCallId,
      result: result,
      isError:
          (json['is_error'] as bool?) ?? (json['isError'] as bool?) ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
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
