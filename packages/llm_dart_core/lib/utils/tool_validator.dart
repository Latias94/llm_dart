import 'dart:convert';

import '../core/llm_error.dart';
import '../models/chat_models.dart';
import '../models/tool_models.dart';

/// Tool validation utility for ensuring tool calls and tool inputs are valid.
///
/// This is a best-effort validator that checks JSON-like tool inputs against a
/// subset of JSON Schema keywords used in AI SDK-style tool schemas.
class ToolValidator {
  /// Validate a JSON-like value against a [JsonSchema].
  ///
  /// Returns a list of validation error messages (empty if valid).
  static List<String> validateJsonLike(
    Object? value,
    JsonSchema schema, {
    String path = r'$',
  }) {
    return _validateJsonLikeValue(path, value, schema);
  }

  /// Validate a tool call against its tool definition.
  ///
  /// Returns true if valid, throws [ToolValidationError] if invalid.
  static bool validateToolCall(ToolCall toolCall, Tool toolDefinition) {
    if (toolCall.function.name != toolDefinition.function.name) {
      throw ToolValidationError(
        'Tool name mismatch: expected ${toolDefinition.function.name}, got ${toolCall.function.name}',
        toolName: toolDefinition.function.name,
      );
    }

    Map<String, dynamic> arguments;
    try {
      arguments = jsonDecode(toolCall.function.arguments) as Map<String, dynamic>;
    } catch (e) {
      throw ToolValidationError(
        'Invalid JSON in tool arguments: $e',
        toolName: toolCall.function.name,
      );
    }

    final validationErrors = validateParameters(
      arguments,
      toolDefinition.function.inputSchema,
    );

    if (validationErrors.isNotEmpty) {
      throw ToolValidationError(
        'Parameter validation failed: ${validationErrors.join(', ')}',
        toolName: toolCall.function.name,
      );
    }

    return true;
  }

  /// Validate parameters against a tool input schema.
  ///
  /// The schema is expected to be a JSON Schema object (typically
  /// `type: object`).
  static List<String> validateParameters(
    Map<String, dynamic> arguments,
    JsonSchema schema,
  ) {
    return _validateJsonLikeValue(r'$', arguments, schema);
  }

  static List<String> _validateJsonLikeValue(
    String path,
    Object? value,
    JsonSchema schema,
  ) {
    final errors = <String>[];

    // enum
    final enumValues = schema['enum'];
    if (enumValues is List && enumValues.isNotEmpty) {
      if (!enumValues.contains(value)) {
        errors.add('Value $path must be one of $enumValues, got $value');
      }
      return errors;
    }

    // oneOf/anyOf/allOf (best-effort)
    final oneOf = schema['oneOf'];
    if (oneOf is List && oneOf.isNotEmpty) {
      final anyOk = oneOf.whereType<Map>().any((candidate) {
        return _validateJsonLikeValue(
          path,
          value,
          candidate.cast<String, dynamic>(),
        ).isEmpty;
      });
      if (!anyOk) errors.add('Value $path does not match any schema in oneOf.');
      return errors;
    }

    final anyOf = schema['anyOf'];
    if (anyOf is List && anyOf.isNotEmpty) {
      final anyOk = anyOf.whereType<Map>().any((candidate) {
        return _validateJsonLikeValue(
          path,
          value,
          candidate.cast<String, dynamic>(),
        ).isEmpty;
      });
      if (!anyOk) errors.add('Value $path does not match any schema in anyOf.');
      return errors;
    }

    final allOf = schema['allOf'];
    if (allOf is List && allOf.isNotEmpty) {
      for (final candidate in allOf.whereType<Map>()) {
        errors.addAll(
          _validateJsonLikeValue(path, value, candidate.cast<String, dynamic>()),
        );
      }
      return errors;
    }

    final schemaType = schema['type'];
    switch (schemaType) {
      case 'string':
        if (value is! String) {
          errors.add('Value $path must be a string, got ${value.runtimeType}');
        }
        return errors;

      case 'number':
        if (value is! num) {
          errors.add('Value $path must be a number, got ${value.runtimeType}');
        }
        return errors;

      case 'integer':
        if (value is! int) {
          errors.add('Value $path must be an integer, got ${value.runtimeType}');
        }
        return errors;

      case 'boolean':
        if (value is! bool) {
          errors.add('Value $path must be a boolean, got ${value.runtimeType}');
        }
        return errors;

      case 'array':
        if (value is! List) {
          errors.add('Value $path must be an array, got ${value.runtimeType}');
          return errors;
        }
        final items = schema['items'];
        if (items is Map) {
          final itemSchema = items.cast<String, dynamic>();
          for (var i = 0; i < value.length; i++) {
            errors.addAll(
              _validateJsonLikeValue('$path[$i]', value[i] as Object?, itemSchema),
            );
          }
        }
        return errors;

      case 'object':
        if (value is! Map) {
          errors.add('Value $path must be an object, got ${value.runtimeType}');
          return errors;
        }

        final map = <String, Object?>{};
        value.forEach((k, v) => map[k.toString()] = v as Object?);

        final required = schema['required'];
        if (required is List) {
          for (final item in required) {
            if (item is String && !map.containsKey(item)) {
              errors.add('Object $path missing required property: $item');
            }
          }
        }

        final propsRaw = schema['properties'];
        final props = propsRaw is Map ? propsRaw.cast<String, dynamic>() : null;

        final additionalProperties = schema['additionalProperties'];
        final disallowAdditional = additionalProperties == false;

        if (props != null && props.isNotEmpty) {
          for (final entry in map.entries) {
            final key = entry.key;
            final valueForKey = entry.value;
            final schemaForKey = props[key];

            if (schemaForKey == null) {
              if (disallowAdditional) {
                errors.add('Object $path has unknown property: $key');
              }
              continue;
            }

            if (schemaForKey is Map) {
              errors.addAll(
                _validateJsonLikeValue(
                  '$path.$key',
                  valueForKey,
                  schemaForKey.cast<String, dynamic>(),
                ),
              );
            }
          }
        }

        return errors;

      case null:
        // Best-effort: if `type` is absent, do not hard-fail.
        return errors;

      default:
        // Best-effort: ignore unknown schema keywords/types.
        return errors;
    }
  }

  /// Validate tool choice against available tools.
  ///
  /// Returns true if valid, throws [ToolValidationError] if invalid.
  static bool validateToolChoice(
    ToolChoice toolChoice,
    List<Tool> availableTools,
  ) {
    switch (toolChoice) {
      case SpecificToolChoice(toolName: final name):
        final toolExists =
            availableTools.any((tool) => tool.function.name == name);
        if (!toolExists) {
          throw ToolValidationError(
            'Specified tool "$name" not found in available tools',
            toolName: name,
          );
        }
        break;
      case AutoToolChoice():
      case AnyToolChoice():
      case NoneToolChoice():
        break;
    }
    return true;
  }

  /// Validate structured output format.
  static bool validateStructuredOutput(StructuredOutputFormat format) {
    if (format.name.isEmpty) {
      throw const StructuredOutputError('Structured output name cannot be empty');
    }

    if (format.schema != null) {
      final schema = format.schema!;
      if (schema['type'] == null) {
        throw StructuredOutputError(
          'Schema must have a type field',
          schemaName: format.name,
          schema: schema,
        );
      }

      if (schema['type'] == 'object' && schema['properties'] == null) {
        throw StructuredOutputError(
          'Object schema must have properties field',
          schemaName: format.name,
          schema: schema,
        );
      }
    }

    return true;
  }

  /// Get tool by name from a list of tools.
  static Tool? findTool(String toolName, List<Tool> tools) {
    try {
      return tools.firstWhere((tool) => tool.function.name == toolName);
    } catch (_) {
      return null;
    }
  }

  /// Validate multiple tool calls against their definitions.
  ///
  /// Returns a map of tool call ID to validation errors.
  static Map<String, List<String>> validateToolCalls(
    List<ToolCall> toolCalls,
    List<Tool> availableTools,
  ) {
    final errors = <String, List<String>>{};

    for (final toolCall in toolCalls) {
      final tool = findTool(toolCall.function.name, availableTools);
      if (tool == null) {
        errors[toolCall.id] = ['Tool not found: ${toolCall.function.name}'];
        continue;
      }

      try {
        validateToolCall(toolCall, tool);
      } catch (e) {
        if (e is ToolValidationError) {
          errors[toolCall.id] = [e.message];
        } else {
          errors[toolCall.id] = ['Validation error: $e'];
        }
      }
    }

    return errors;
  }
}

