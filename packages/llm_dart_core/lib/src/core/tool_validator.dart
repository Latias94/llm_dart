import 'dart:convert';

import '../models/tool_models.dart';
import '../models/chat_models.dart';
import 'llm_error.dart';

/// Tool validation utility for ensuring tool calls and parameters are valid.
///
/// This class provides static methods for validating tool calls against their
/// definitions and ensuring parameter types and requirements are met.
class ToolValidator {
  /// Validate a tool call against its tool definition.
  ///
  /// [toolCall] - The tool call to validate.
  /// [toolDefinition] - The tool definition to validate against.
  ///
  /// Returns true if valid, throws [ToolValidationError] if invalid.
  static bool validateToolCall(ToolCall toolCall, Tool toolDefinition) {
    // Check if tool names match.
    if (toolCall.function.name != toolDefinition.function.name) {
      throw ToolValidationError(
        'Tool name mismatch: expected ${toolDefinition.function.name}, got ${toolCall.function.name}',
        toolName: toolDefinition.function.name,
      );
    }

    // Parse and validate arguments.
    Map<String, dynamic> arguments;
    try {
      arguments =
          jsonDecode(toolCall.function.arguments) as Map<String, dynamic>;
    } catch (e) {
      throw ToolValidationError(
        'Invalid JSON in tool arguments: $e',
        toolName: toolCall.function.name,
      );
    }

    // Validate parameters.
    final validationErrors = validateParameters(
      arguments,
      toolDefinition.function.parameters,
    );

    if (validationErrors.isNotEmpty) {
      throw ToolValidationError(
        'Parameter validation failed: ${validationErrors.join(', ')}',
        toolName: toolCall.function.name,
      );
    }

    return true;
  }

  /// Validate parameters against a schema.
  ///
  /// [arguments] - The arguments to validate.
  /// [schema] - The parameter schema to validate against.
  ///
  /// Returns a list of validation error messages (empty if valid).
  static List<String> validateParameters(
    Map<String, dynamic> arguments,
    ParametersSchema schema,
  ) {
    final errors = <String>[];

    // Check required parameters.
    for (final requiredParam in schema.required) {
      if (!arguments.containsKey(requiredParam)) {
        errors.add('Missing required parameter: $requiredParam');
      }
    }

    // Validate each provided parameter.
    for (final entry in arguments.entries) {
      final paramName = entry.key;
      final paramValue = entry.value;
      final paramProperty = schema.properties[paramName];

      if (paramProperty == null) {
        errors.add('Unknown parameter: $paramName');
        continue;
      }

      final paramErrors = _validateParameterValue(
        paramName,
        paramValue,
        paramProperty,
      );
      errors.addAll(paramErrors);
    }

    return errors;
  }

  /// Validate a single parameter value against its property definition.
  static List<String> _validateParameterValue(
    String paramName,
    dynamic value,
    ParameterProperty property,
  ) {
    final errors = <String>[];

    // Type validation.
    switch (property.propertyType) {
      case 'string':
        if (value is! String) {
          errors.add(
            'Parameter $paramName must be a string, got ${value.runtimeType}',
          );
        } else if (property.enumList != null &&
            !property.enumList!.contains(value)) {
          errors.add(
            'Parameter $paramName must be one of ${property.enumList}, got $value',
          );
        }
        break;

      case 'number':
      case 'integer':
        if (value is! num) {
          errors.add(
            'Parameter $paramName must be a number, got ${value.runtimeType}',
          );
        } else if (property.propertyType == 'integer' && value is! int) {
          errors.add(
            'Parameter $paramName must be an integer, got ${value.runtimeType}',
          );
        }
        break;

      case 'boolean':
        if (value is! bool) {
          errors.add(
            'Parameter $paramName must be a boolean, got ${value.runtimeType}',
          );
        }
        break;

      case 'array':
        if (value is! List) {
          errors.add(
            'Parameter $paramName must be an array, got ${value.runtimeType}',
          );
        } else if (property.items != null) {
          // Validate array items.
          for (int i = 0; i < value.length; i++) {
            final itemErrors = _validateParameterValue(
              '$paramName[$i]',
              value[i],
              property.items!,
            );
            errors.addAll(itemErrors);
          }
        }
        break;

      case 'object':
        if (value is! Map<String, dynamic>) {
          errors.add(
            'Parameter $paramName must be an object, got ${value.runtimeType}',
          );
        } else if (property.properties != null) {
          // Validate object properties if schema is defined.
          final objectValue = value;

          // Check required properties.
          if (property.required != null) {
            for (final requiredProp in property.required!) {
              if (!objectValue.containsKey(requiredProp)) {
                errors.add(
                  'Object $paramName missing required property: $requiredProp',
                );
              }
            }
          }

          // Validate each provided property.
          for (final entry in objectValue.entries) {
            final propName = entry.key;
            final propValue = entry.value;
            final propProperty = property.properties![propName];

            if (propProperty == null) {
              errors.add(
                'Object $paramName has unknown property: $propName',
              );
              continue;
            }

            final propErrors = _validateParameterValue(
              '$paramName.$propName',
              propValue,
              propProperty,
            );
            errors.addAll(propErrors);
          }
        }
        break;

      default:
        // Allow unknown types for flexibility.
        break;
    }

    return errors;
  }

  /// Validate tool choice against available tools.
  ///
  /// [toolChoice] - The tool choice to validate.
  /// [availableTools] - List of available tools.
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
        // These are always valid.
        break;
    }

    return true;
  }

  /// Validate structured output format.
  ///
  /// [format] - The structured output format to validate.
  ///
  /// Returns true if valid, throws [StructuredOutputError] if invalid.
  static bool validateStructuredOutput(StructuredOutputFormat format) {
    if (format.name.isEmpty) {
      throw const StructuredOutputError(
        'Structured output name cannot be empty',
      );
    }

    if (format.schema != null) {
      final schema = format.schema!;

      // Basic JSON schema validation.
      if (schema['type'] == null) {
        throw StructuredOutputError(
          'Schema must have a type field',
          schemaName: format.name,
          schema: schema,
        );
      }

      // Validate required properties for object type.
      if (schema['type'] == 'object') {
        if (schema['properties'] == null) {
          throw StructuredOutputError(
            'Object schema must have properties field',
            schemaName: format.name,
            schema: schema,
          );
        }
      }
    }

    return true;
  }

  /// Get tool by name from a list of tools.
  ///
  /// [toolName] - Name of the tool to find.
  /// [tools] - List of tools to search in.
  ///
  /// Returns the tool if found, null otherwise.
  static Tool? findTool(String toolName, List<Tool> tools) {
    try {
      return tools.firstWhere((tool) => tool.function.name == toolName);
    } catch (_) {
      return null;
    }
  }

  /// Validate multiple tool calls against their definitions.
  ///
  /// [toolCalls] - List of tool calls to validate.
  /// [availableTools] - List of available tool definitions.
  ///
  /// Returns a map of tool call ID to validation errors (empty map if all valid).
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
