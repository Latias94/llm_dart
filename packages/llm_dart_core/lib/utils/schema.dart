import '../models/tool_models.dart';

/// Convenience builders for tool input schemas (JSON Schema).
class Schema {
  Schema._();

  /// Top-level schema (typically `type: object`).
  static JsonSchema params({
    required Map<String, JsonSchema> properties,
    List<String> required = const <String>[],
  }) {
    return <String, dynamic>{
      'type': 'object',
      'properties': properties,
      if (required.isNotEmpty) 'required': required,
    };
  }

  static JsonSchema string(
    String description, {
    List<String>? enumValues,
  }) {
    return <String, dynamic>{
      'type': 'string',
      'description': description,
      if (enumValues != null && enumValues.isNotEmpty) 'enum': enumValues,
    };
  }

  static JsonSchema number(String description) {
    return <String, dynamic>{
      'type': 'number',
      'description': description,
    };
  }

  static JsonSchema integer(String description) {
    return <String, dynamic>{
      'type': 'integer',
      'description': description,
    };
  }

  static JsonSchema boolean(String description) {
    return <String, dynamic>{
      'type': 'boolean',
      'description': description,
    };
  }

  static JsonSchema array(
    String description, {
    required JsonSchema items,
  }) {
    return <String, dynamic>{
      'type': 'array',
      'description': description,
      'items': items,
    };
  }

  static JsonSchema object(
    String description, {
    required Map<String, JsonSchema> properties,
    List<String> required = const <String>[],
  }) {
    return <String, dynamic>{
      'type': 'object',
      'description': description,
      'properties': properties,
      if (required.isNotEmpty) 'required': required,
    };
  }
}
