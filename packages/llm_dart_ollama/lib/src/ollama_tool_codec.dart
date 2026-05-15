import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

final class OllamaToolCodec {
  const OllamaToolCodec();

  List<Map<String, Object?>> encodeToolDefinitions({
    required List<FunctionToolDefinition> tools,
    required ToolChoice? toolChoice,
    required List<ModelWarning> warnings,
  }) {
    final shouldIncludeTools = switch (toolChoice) {
      NoneToolChoice() => false,
      _ => true,
    };
    if (!shouldIncludeTools) return const [];

    if (toolChoice is RequiredToolChoice || toolChoice is SpecificToolChoice) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.compatibility,
          field: 'toolChoice',
          message:
              'Ollama does not support explicit toolChoice control. Declared tools remain available for provider-side automatic selection.',
        ),
      );
    }

    return tools
        .map(
          (tool) => {
            'type': 'function',
            'function': {
              'name': tool.name,
              if (tool.description != null) 'description': tool.description,
              'parameters': tool.inputSchema.toJson(),
            },
          },
        )
        .toList(growable: false);
  }

  Map<String, Object?> encodeAssistantToolCall({
    required int index,
    required String toolName,
    required Object? input,
  }) {
    return {
      'type': 'function',
      'function': {
        'index': index,
        'name': toolName,
        'arguments': normalizeToolInput(input),
      },
    };
  }

  List<ToolCallContent> decodeToolCalls(Map<String, Object?>? message) {
    final toolCalls = message?['tool_calls'];
    if (toolCalls is! List || toolCalls.isEmpty) return const [];

    return toolCalls.asMap().entries.map((entry) {
      final item = entry.value;
      if (item is! Map) {
        throw StateError(
          'Expected Ollama tool_calls[${entry.key}] to be a JSON object.',
        );
      }

      final map = Map<String, Object?>.from(item);
      final function = _asObject(map['function']);
      if (function == null) {
        throw StateError(
          'Expected Ollama tool_calls[${entry.key}] to contain a function object.',
        );
      }

      final name = _asString(function['name']);
      if (name == null || name.isEmpty) {
        throw StateError(
          'Expected Ollama tool call ${entry.key} to contain a function name.',
        );
      }

      return ToolCallContent(
        toolCallId: _asString(map['id']) ?? 'ollama-tool-${entry.key}-$name',
        toolName: name,
        input: normalizeDecodedToolArguments(function['arguments']),
      );
    }).toList(growable: false);
  }

  Object? normalizeToolInput(Object? input) {
    return switch (input) {
      null || bool() || num() || String() || List() || Map() => input,
      _ => jsonDecode(jsonEncode(input)),
    };
  }

  Object? normalizeDecodedToolArguments(Object? arguments) {
    if (arguments is String) {
      final trimmed = arguments.trim();
      if (trimmed.isEmpty) return null;
      try {
        return jsonDecode(trimmed);
      } catch (_) {
        return arguments;
      }
    }
    if (arguments is Map) return Map<String, Object?>.from(arguments);
    if (arguments is List) return List<Object?>.from(arguments);
    return arguments;
  }

  String stringifyToolOutput(ToolOutput output) {
    if (output is ExecutionDeniedToolOutput) {
      return output.reason ?? 'Tool execution denied';
    }

    if (output is ContentToolOutput) {
      return jsonEncode(projectToolOutputContentPartsToJson(output.parts));
    }

    final value = output.value;
    if (value == null) {
      return output.isError ? 'Tool execution failed' : '';
    }

    return value is String ? value : jsonEncode(normalizeJsonValue(value));
  }
}

Map<String, Object?>? _asObject(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return Map<String, Object?>.from(value);
  return null;
}

String? _asString(Object? value) => value is String ? value : null;
