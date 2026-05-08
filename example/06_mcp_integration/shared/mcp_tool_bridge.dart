import 'dart:convert';

import 'package:llm_dart/core.dart' as core;
import 'package:mcp_dart/mcp_dart.dart' as mcp;

typedef McpToolExecutionStartCallback = void Function(
  core.GenerateTextFunctionToolExecutionRequest request,
  Map<String, dynamic> arguments,
);

typedef McpToolExecutionFinishCallback = void Function(
  core.GenerateTextFunctionToolExecutionRequest request,
  Map<String, dynamic> arguments,
  mcp.CallToolResult result,
  core.GenerateTextToolExecutionResult executionResult,
);

typedef McpToolExecutionErrorCallback = void Function(
  core.GenerateTextFunctionToolExecutionRequest request,
  Map<String, dynamic>? arguments,
  Object error,
);

Future<List<core.FunctionToolDefinition>> discoverMcpFunctionTools(
  mcp.McpClient client,
) async {
  final toolsResult = await client.listTools();
  return toolsResult.tools
      .map(_mcpToolToFunctionToolDefinition)
      .toList(growable: false);
}

core.GenerateTextFunctionToolExecutor createMcpFunctionToolExecutor(
  mcp.McpClient client, {
  McpToolExecutionStartCallback? onExecutionStart,
  McpToolExecutionFinishCallback? onExecutionFinish,
  McpToolExecutionErrorCallback? onExecutionError,
}) {
  return (request) async {
    Map<String, dynamic>? arguments;

    try {
      arguments = decodeMcpToolArguments(
        request.toolCall.input,
        toolName: request.toolCall.toolName,
        toolCallId: request.toolCall.toolCallId,
      );
    } catch (error) {
      onExecutionError?.call(request, null, error);
      return core.GenerateTextToolExecutionResult.error(
        _buildToolExecutionErrorPayload(
          toolName: request.toolCall.toolName,
          toolCallId: request.toolCall.toolCallId,
          error: error,
        ),
      );
    }

    onExecutionStart?.call(request, arguments);

    try {
      final result = await client.callTool(
        mcp.CallToolRequest(
          name: request.toolCall.toolName,
          arguments: arguments,
        ),
      );

      final output = normalizeMcpToolResultOutput(result);
      final executionResult = result.isError == true
          ? core.GenerateTextToolExecutionResult.error(
              output ??
                  _buildToolExecutionErrorPayload(
                    toolName: request.toolCall.toolName,
                    toolCallId: request.toolCall.toolCallId,
                    error: 'MCP tool returned an error state.',
                  ),
            )
          : core.GenerateTextToolExecutionResult.output(output);

      onExecutionFinish?.call(request, arguments, result, executionResult);
      return executionResult;
    } catch (error) {
      onExecutionError?.call(request, arguments, error);
      return core.GenerateTextToolExecutionResult.error(
        _buildToolExecutionErrorPayload(
          toolName: request.toolCall.toolName,
          toolCallId: request.toolCall.toolCallId,
          arguments: arguments,
          error: error,
        ),
      );
    }
  };
}

Map<String, dynamic> decodeMcpToolArguments(
  Object? input, {
  required String toolName,
  required String toolCallId,
}) {
  final path = 'toolCall($toolCallId:$toolName).input';
  final decodedInput = switch (input) {
    null => const <String, Object?>{},
    String() => _decodeJsonStringInput(input, path: path),
    _ => _normalizeJsonValue(input, path: path),
  };

  if (decodedInput == null) {
    return <String, dynamic>{};
  }

  if (decodedInput is! Map<String, Object?>) {
    throw FormatException(
      'MCP tool "$toolName" requires an object input, '
      'but received ${decodedInput.runtimeType}.',
    );
  }

  return decodedInput.map(
    (key, value) => MapEntry(key, value),
  );
}

Object? normalizeMcpToolResultOutput(mcp.CallToolResult result) {
  final rawStructuredContent = result.structuredContent;
  final structuredContent =
      rawStructuredContent == null || rawStructuredContent.isEmpty
          ? null
          : _normalizeJsonObject(
              rawStructuredContent,
              path: 'callToolResult.structuredContent',
            );
  final content = <Map<String, Object?>>[
    for (var index = 0; index < result.content.length; index++)
      _normalizeJsonObject(
        result.content[index].toJson(),
        path: 'callToolResult.content[$index]',
      ),
  ];
  final meta = result.meta == null
      ? null
      : _normalizeJsonObject(
          result.meta!,
          path: 'callToolResult.meta',
        );
  final text = result.content.whereType<mcp.TextContent>().map((item) {
    return item.text;
  }).join('\n\n');

  if (structuredContent == null && meta == null && content.isEmpty) {
    return null;
  }

  if (structuredContent == null &&
      meta == null &&
      content.every((item) => item['type'] == 'text')) {
    return text;
  }

  if (structuredContent != null && meta == null && content.isEmpty) {
    return structuredContent;
  }

  final payload = <String, Object?>{
    if (structuredContent != null) 'structuredContent': structuredContent,
    if (content.isNotEmpty) 'content': content,
    if (meta != null && meta.isNotEmpty) 'meta': meta,
  };

  if (text.isNotEmpty &&
      (structuredContent != null ||
          content.any((item) => item['type'] != 'text'))) {
    payload['text'] = text;
  }

  return payload.isEmpty ? null : payload;
}

String formatMcpValue(
  Object? value, {
  bool pretty = true,
}) {
  if (value == null) {
    return 'null';
  }

  if (value is String) {
    return value;
  }

  if (value is num || value is bool) {
    return value.toString();
  }

  final normalized = _normalizeJsonValue(value, path: 'formatMcpValue');
  return pretty
      ? const JsonEncoder.withIndent('  ').convert(normalized)
      : jsonEncode(normalized);
}

core.FunctionToolDefinition _mcpToolToFunctionToolDefinition(mcp.Tool tool) {
  final schema = _normalizeJsonObject(
    tool.inputSchema.toJson(),
    path: 'tool(${tool.name}).inputSchema',
  );

  return core.FunctionToolDefinition(
    name: tool.name,
    description:
        tool.description ?? tool.annotations?.title ?? 'MCP tool: ${tool.name}',
    inputSchema: core.ToolJsonSchema.raw(schema),
  );
}

Object? _decodeJsonStringInput(
  String input, {
  required String path,
}) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return const <String, Object?>{};
  }

  final decoded = jsonDecode(trimmed);
  return _normalizeJsonValue(decoded, path: path);
}

Map<String, Object?> _buildToolExecutionErrorPayload({
  required String toolName,
  required String toolCallId,
  Map<String, dynamic>? arguments,
  required Object error,
}) {
  return {
    'toolName': toolName,
    'toolCallId': toolCallId,
    if (arguments != null && arguments.isNotEmpty) 'arguments': arguments,
    'error': error.toString(),
  };
}

Map<String, Object?> _normalizeJsonObject(
  Map value, {
  required String path,
}) {
  final normalized = _normalizeJsonValue(value, path: path);
  if (normalized is! Map<String, Object?>) {
    throw FormatException('Expected a JSON object at $path.');
  }

  return normalized;
}

Object? _normalizeJsonValue(
  Object? value, {
  required String path,
}) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }

  if (value is Map) {
    final normalized = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        throw FormatException('Expected a string key at $path.');
      }

      normalized[key] = _normalizeJsonValue(
        entry.value,
        path: '$path.$key',
      );
    }
    return normalized;
  }

  if (value is List) {
    return [
      for (var index = 0; index < value.length; index++)
        _normalizeJsonValue(
          value[index],
          path: '$path[$index]',
        ),
    ];
  }

  throw FormatException(
    'Expected a JSON-safe value at $path, but received ${value.runtimeType}.',
  );
}
