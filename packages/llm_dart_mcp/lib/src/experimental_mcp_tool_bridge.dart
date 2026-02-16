import 'dart:async';
import 'dart:convert';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:mcp_dart/mcp_dart.dart' as mcp;

import 'experimental_mcp_connection.dart';

/// Experimental tool bridge that exposes MCP tools as local function tools.
///
/// The model calls tools as "function tools" and the handlers forward the call
/// to the connected MCP server via `tools/call`.
class ExperimentalMcpToolBridge {
  final ToolSet toolSet;
  final ToolCatalog toolCatalog;

  /// Map from the function tool name (advertised to the model) to the MCP tool name.
  final Map<String, String> functionNameToMcpToolName;

  /// Reverse map from MCP tool name to function tool name.
  final Map<String, String> mcpToolNameToFunctionName;

  const ExperimentalMcpToolBridge({
    required this.toolSet,
    required this.toolCatalog,
    required this.functionNameToMcpToolName,
    required this.mcpToolNameToFunctionName,
  });
}

/// Experimental options for mapping MCP tools into function tools.
class ExperimentalMcpToolBridgeOptions {
  /// Prefix used when generating safe function tool names.
  ///
  /// Default: `mcp`.
  final String toolNamePrefix;

  /// Whether to namespace tool names by [ExperimentalMcpConnection.serverLabel].
  ///
  /// Default: true.
  final bool namespaceByServerLabel;

  /// When an MCP tool provides no `properties` schema, wrap tool arguments as:
  /// `{ "input": <any> }` and forward only `input` to the MCP server.
  ///
  /// This keeps our parameter validation permissive for "open" schemas.
  ///
  /// Default: true.
  final bool wrapInputForOpenSchemas;

  /// Optional output schemas used to validate MCP tool outputs.
  ///
  /// Keys are MCP tool names (as returned by `tools/list`).
  /// Values are `ParameterProperty` schemas (JSON-like), e.g. built via
  /// `Schema.object(...)`.
  ///
  /// When provided, the bridge will:
  /// - Prefer `structuredContent` when available and validate it.
  /// - Otherwise, attempt to parse single text content as JSON and validate it.
  /// - Throw if the output cannot be validated against the schema.
  final Map<String, ParameterProperty> outputSchemasByMcpToolName;

  /// Whether to attempt parsing single `text` tool outputs as JSON when
  /// validating against [outputSchemasByMcpToolName].
  ///
  /// Default: true.
  final bool parseTextContentAsJsonForOutputSchema;

  /// Whether to infer output schemas from MCP tool definitions returned by
  /// `tools/list` when the server provides `outputSchema`.
  ///
  /// When enabled and an MCP tool definition includes an `outputSchema`, the
  /// bridge will validate tool outputs by default (Vercel AI SDK-style
  /// "schemas=automatic" ergonomics).
  ///
  /// Default: true.
  final bool inferOutputSchemaFromToolDefinitions;

  const ExperimentalMcpToolBridgeOptions({
    this.toolNamePrefix = 'mcp',
    this.namespaceByServerLabel = true,
    this.wrapInputForOpenSchemas = true,
    this.outputSchemasByMcpToolName = const {},
    this.parseTextContentAsJsonForOutputSchema = true,
    this.inferOutputSchemaFromToolDefinitions = true,
  });

  ExperimentalMcpToolBridgeOptions copyWith({
    String? toolNamePrefix,
    bool? namespaceByServerLabel,
    bool? wrapInputForOpenSchemas,
    Map<String, ParameterProperty>? outputSchemasByMcpToolName,
    bool? parseTextContentAsJsonForOutputSchema,
    bool? inferOutputSchemaFromToolDefinitions,
  }) {
    return ExperimentalMcpToolBridgeOptions(
      toolNamePrefix: toolNamePrefix ?? this.toolNamePrefix,
      namespaceByServerLabel:
          namespaceByServerLabel ?? this.namespaceByServerLabel,
      wrapInputForOpenSchemas:
          wrapInputForOpenSchemas ?? this.wrapInputForOpenSchemas,
      outputSchemasByMcpToolName:
          outputSchemasByMcpToolName ?? this.outputSchemasByMcpToolName,
      parseTextContentAsJsonForOutputSchema:
          parseTextContentAsJsonForOutputSchema ??
              this.parseTextContentAsJsonForOutputSchema,
      inferOutputSchemaFromToolDefinitions:
          inferOutputSchemaFromToolDefinitions ??
              this.inferOutputSchemaFromToolDefinitions,
    );
  }
}

/// Experimental: create a [ToolSet] + [ToolCatalog] bridge for MCP tools.
Future<ExperimentalMcpToolBridge> experimentalCreateMcpToolBridge({
  required ExperimentalMcpConnection connection,
  ExperimentalMcpToolBridgeOptions options =
      const ExperimentalMcpToolBridgeOptions(),
}) async {
  final list = await connection.experimentalClient.listTools();
  final tools = list.tools;

  final serverLabel = connection.serverLabel;
  final serverPrefix = options.namespaceByServerLabel && serverLabel != null
      ? '${_safeName(serverLabel)}__'
      : '';

  final basePrefix = '${_safeName(options.toolNamePrefix)}__$serverPrefix';

  final functionNameToMcpName = <String, String>{};
  final mcpNameToFunctionName = <String, String>{};
  final usedNames = <String>{};

  final localTools = <LocalTool>[];

  for (final mcpTool in tools) {
    final functionName =
        _uniqueName('$basePrefix${_safeName(mcpTool.name)}', usedNames);

    functionNameToMcpName[functionName] = mcpTool.name;
    mcpNameToFunctionName[mcpTool.name] = functionName;

    final schemaInfo = _parametersSchemaFromMcpTool(
      tool: mcpTool,
      wrapInputForOpenSchemas: options.wrapInputForOpenSchemas,
    );

    final outputSchema = options.outputSchemasByMcpToolName[mcpTool.name] ??
        (options.inferOutputSchemaFromToolDefinitions
            ? _outputSchemaFromMcpTool(mcpTool)
            : null);

    final handler = (Map<String, dynamic> input,
        ToolExecutionOptions executionOptions) async {
      connection.throwIfCancelled(executionOptions.cancelToken);

      final originalName = functionNameToMcpName[executionOptions.toolName];
      if (originalName == null) {
        throw StateError(
            'Unknown MCP tool mapping: ${executionOptions.toolName}');
      }

      final forwardedArgs = schemaInfo.forwardArgs(input);

      final result = await connection.experimentalClient.callTool(
        mcp.CallToolRequestParams(
          name: originalName,
          arguments: forwardedArgs,
        ),
      );

      if (result.isError == true) {
        final message = _callToolResultToBestEffortText(result);
        throw StateError('MCP tool error: $message');
      }

      if (outputSchema != null) {
        final validated = _validateToolOutputAgainstSchema(
          result,
          outputSchema,
          toolName: mcpTool.name,
          parseTextAsJson: options.parseTextContentAsJsonForOutputSchema,
        );
        if (validated.ok) {
          return validated.value!;
        }
        throw validated.error!;
      }

      return _callToolResultToBestEffortToolOutputValue(result);
    };

    final description = mcpTool.description?.trim().isNotEmpty == true
        ? mcpTool.description!.trim()
        : (mcpTool.annotations?.title.trim().isNotEmpty == true
            ? mcpTool.annotations!.title.trim()
            : 'MCP tool: ${mcpTool.name}');

    localTools.add(
      functionTool(
        name: functionName,
        description: description,
        parameters: schemaInfo.schema,
        handler: handler,
      ),
    );
  }

  final toolSet = ToolSet(localTools);
  final toolCatalog = ToolSetCatalog(toolSet);

  return ExperimentalMcpToolBridge(
    toolSet: toolSet,
    toolCatalog: toolCatalog,
    functionNameToMcpToolName: Map.unmodifiable(functionNameToMcpName),
    mcpToolNameToFunctionName: Map.unmodifiable(mcpNameToFunctionName),
  );
}

class _ToolSchemaInfo {
  final ParametersSchema schema;
  final bool wrapInput;

  const _ToolSchemaInfo({required this.schema, required this.wrapInput});

  Map<String, dynamic>? forwardArgs(Map<String, dynamic> parsedArgs) {
    if (!wrapInput) return parsedArgs;
    final input = parsedArgs['input'];
    if (input == null) return null;
    if (input is Map<String, dynamic>) return input;
    if (input is Map) return Map<String, dynamic>.from(input);
    throw const InvalidRequestError(
      'Wrapped MCP tool requires "input" to be a JSON object (map).',
    );
  }
}

_ToolSchemaInfo _parametersSchemaFromMcpTool({
  required mcp.Tool tool,
  required bool wrapInputForOpenSchemas,
}) {
  final props = tool.inputSchema.properties;
  final required = tool.inputSchema.required ?? const <String>[];

  if (props == null || props.isEmpty) {
    if (!wrapInputForOpenSchemas) {
      // No properties; accept empty args.
      return const _ToolSchemaInfo(
        schema: ParametersSchema(
          schemaType: 'object',
          properties: <String, ParameterProperty>{},
          required: <String>[],
        ),
        wrapInput: false,
      );
    }

    return _ToolSchemaInfo(
      schema: const ParametersSchema(
        schemaType: 'object',
        properties: {
          'input': ParameterProperty(
            propertyType: 'object',
            description: 'Tool arguments (free-form).',
          ),
        },
        required: <String>[],
      ),
      wrapInput: true,
    );
  }

  final properties = <String, ParameterProperty>{};
  for (final entry in props.entries) {
    final key = entry.key;
    final raw = entry.value;
    if (raw is Map<String, dynamic>) {
      properties[key] = _jsonSchemaToParameterProperty(
        raw,
        descriptionFallback: key,
      );
    } else if (raw is Map) {
      properties[key] = _jsonSchemaToParameterProperty(
        Map<String, dynamic>.from(raw),
        descriptionFallback: key,
      );
    } else {
      properties[key] = ParameterProperty(
        propertyType: 'string',
        description: key,
      );
    }
  }

  return _ToolSchemaInfo(
    schema: ParametersSchema(
      schemaType: 'object',
      properties: properties,
      required: required,
    ),
    wrapInput: false,
  );
}

ParameterProperty? _outputSchemaFromMcpTool(mcp.Tool tool) {
  final out = tool.outputSchema;
  if (out == null) return null;

  final props = out.properties;
  if (props == null || props.isEmpty) return null;

  final required = out.required ?? const <String>[];

  final properties = <String, ParameterProperty>{};
  for (final entry in props.entries) {
    final key = entry.key;
    final raw = entry.value;
    if (raw is Map<String, dynamic>) {
      properties[key] = _jsonSchemaToParameterProperty(
        raw,
        descriptionFallback: key,
      );
    } else if (raw is Map) {
      properties[key] = _jsonSchemaToParameterProperty(
        Map<String, dynamic>.from(raw),
        descriptionFallback: key,
      );
    } else {
      properties[key] = ParameterProperty(
        propertyType: 'string',
        description: key,
      );
    }
  }

  return ParameterProperty(
    propertyType: 'object',
    description: 'Tool output',
    properties: properties,
    required: required.isEmpty ? null : required,
  );
}

ParameterProperty _jsonSchemaToParameterProperty(
  Map<String, dynamic> schema, {
  required String descriptionFallback,
}) {
  final description =
      (schema['description'] as String?)?.trim().isNotEmpty == true
          ? (schema['description'] as String).trim()
          : descriptionFallback;

  final enumRaw = schema['enum'];
  final enumStrings = enumRaw is List
      ? enumRaw.whereType<String>().toList(growable: false)
      : null;

  String? type = schema['type'] as String?;

  // Best-effort inference when type is omitted.
  if (type == null) {
    if (schema['properties'] is Map) type = 'object';
    if (schema['items'] is Map) type = 'array';
  }

  switch (type) {
    case 'string':
      return ParameterProperty(
        propertyType: 'string',
        description: description,
        enumList: enumStrings,
      );
    case 'number':
      return ParameterProperty(
        propertyType: 'number',
        description: description,
      );
    case 'integer':
      return ParameterProperty(
        propertyType: 'integer',
        description: description,
      );
    case 'boolean':
      return ParameterProperty(
        propertyType: 'boolean',
        description: description,
      );
    case 'array':
      final itemsRaw = schema['items'];
      final itemsSchema = itemsRaw is Map<String, dynamic>
          ? itemsRaw
          : itemsRaw is Map
              ? Map<String, dynamic>.from(itemsRaw)
              : null;
      return ParameterProperty(
        propertyType: 'array',
        description: description,
        items: itemsSchema != null
            ? _jsonSchemaToParameterProperty(
                itemsSchema,
                descriptionFallback: 'item',
              )
            : null,
      );
    case 'object':
      final propsRaw = schema['properties'];
      Map<String, ParameterProperty>? nestedProps;
      if (propsRaw is Map) {
        nestedProps = {};
        propsRaw.forEach((k, v) {
          if (k is! String) return;
          if (v is Map<String, dynamic>) {
            nestedProps![k] = _jsonSchemaToParameterProperty(
              v,
              descriptionFallback: k,
            );
          } else if (v is Map) {
            nestedProps![k] = _jsonSchemaToParameterProperty(
              Map<String, dynamic>.from(v),
              descriptionFallback: k,
            );
          }
        });
        if (nestedProps.isEmpty) nestedProps = null;
      }

      final required = schema['required'] is List
          ? (schema['required'] as List).whereType<String>().toList()
          : null;

      return ParameterProperty(
        propertyType: 'object',
        description: description,
        properties: nestedProps,
        required: required,
      );
  }

  return ParameterProperty(
    propertyType: 'string',
    description: description,
    enumList: enumStrings,
  );
}

String _callToolResultToBestEffortText(mcp.CallToolResult result) {
  if (result.structuredContent.isNotEmpty) {
    return jsonEncode(result.structuredContent);
  }
  final content = result.content;
  if (content.isEmpty) return 'unknown error';
  if (content.length == 1 && content.single is mcp.TextContent) {
    return (content.single as mcp.TextContent).text;
  }
  return jsonEncode(content.map((c) => c.toJson()).toList(growable: false));
}

({bool ok, Object? value, LLMError? error}) _validateToolOutputAgainstSchema(
  mcp.CallToolResult result,
  ParameterProperty outputSchema, {
  required String toolName,
  required bool parseTextAsJson,
}) {
  void validateOrThrow(Object? value, {required String source}) {
    final errors = ToolValidator.validateJsonLike(
      value,
      outputSchema,
      path: r'$',
    );
    if (errors.isNotEmpty) {
      throw ToolOutputValidationError(
        'Output does not match outputSchema.',
        toolName: toolName,
        validationErrors: errors,
        source: source,
      );
    }
  }

  if (result.structuredContent.isNotEmpty) {
    final value = result.structuredContent;
    try {
      validateOrThrow(value, source: 'structuredContent');
      return (ok: true, value: value, error: null);
    } catch (e) {
      return (
        ok: false,
        value: null,
        error: e is LLMError
            ? e
            : ToolOutputValidationError(
                e.toString(),
                toolName: toolName,
                validationErrors: const [],
                source: 'structuredContent',
              ),
      );
    }
  }

  final content = result.content;
  if (parseTextAsJson &&
      content.length == 1 &&
      content.single is mcp.TextContent) {
    final text = (content.single as mcp.TextContent).text;
    try {
      final decoded = jsonDecode(text) as Object?;
      validateOrThrow(decoded, source: 'text-json');
      return (ok: true, value: decoded, error: null);
    } catch (e) {
      return (
        ok: false,
        value: null,
        error: e is LLMError
            ? e
            : ToolOutputValidationError(
                'Failed to parse/validate JSON tool output.',
                toolName: toolName,
                validationErrors: [e.toString()],
                source: 'text-json',
              ),
      );
    }
  }

  return (
    ok: false,
    value: null,
    error: ToolOutputValidationError(
      'Tool did not return structuredContent or JSON text output required by outputSchema.',
      toolName: toolName,
      validationErrors: const [],
      source: 'missing',
    ),
  );
}

Object _callToolResultToBestEffortToolOutputValue(mcp.CallToolResult result) {
  if (result.structuredContent.isNotEmpty) {
    return result.structuredContent;
  }

  final content = result.content;
  if (content.isEmpty) return '';

  if (content.length == 1 && content.single is mcp.TextContent) {
    return (content.single as mcp.TextContent).text;
  }

  ToolResultContentItem toItem(mcp.Content part) {
    switch (part) {
      case mcp.TextContent(:final text):
        return ToolResultContentText(text);
      case mcp.ImageContent(:final data, :final mimeType):
        return ToolResultContentImageData(data: data, mediaType: mimeType);
      case mcp.AudioContent(:final data, :final mimeType):
        return ToolResultContentFileData(data: data, mediaType: mimeType);
      case mcp.EmbeddedResource():
      case mcp.UnknownContent():
        return ToolResultContentText(jsonEncode(part.toJson()));
    }
  }

  final items = content.map(toItem).toList(growable: false);
  return ToolResultContentOutput(items).toJson();
}

String _safeName(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return 'tool';

  final sb = StringBuffer();
  for (final codeUnit in trimmed.codeUnits) {
    final c = String.fromCharCode(codeUnit);
    final isAz = codeUnit >= 65 && codeUnit <= 90;
    final isaz = codeUnit >= 97 && codeUnit <= 122;
    final is09 = codeUnit >= 48 && codeUnit <= 57;
    if (isAz || isaz || is09 || c == '_' || c == '-') {
      sb.write(c);
    } else {
      sb.write('_');
    }
  }

  var out = sb.toString().replaceAll(RegExp('_+'), '_');
  out = out.replaceAll(RegExp('^_+'), '').replaceAll(RegExp(r'_+$'), '');
  if (out.isEmpty) out = 'tool';
  if (out.length > 60) out = out.substring(0, 60);
  return out;
}

String _uniqueName(String base, Set<String> used) {
  var candidate = base;
  var counter = 1;
  while (used.contains(candidate)) {
    candidate = '${base}__${counter++}';
  }
  used.add(candidate);
  return candidate;
}
