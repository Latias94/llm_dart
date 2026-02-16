import '../models/tool_models.dart';

/// Convenience builders for tool parameter schemas.
///
/// This keeps the underlying data structures ([ParametersSchema],
/// [ParameterProperty]) unchanged while making schema construction less
/// verbose in Dart code.
class Schema {
  Schema._();

  /// Top-level parameters schema (always an object in our tool model).
  static ParametersSchema params({
    required Map<String, ParameterProperty> properties,
    List<String> required = const <String>[],
  }) {
    return ParametersSchema(
      schemaType: 'object',
      properties: properties,
      required: required,
    );
  }

  static ParameterProperty string(
    String description, {
    List<String>? enumValues,
  }) {
    return ParameterProperty(
      propertyType: 'string',
      description: description,
      enumList: enumValues,
    );
  }

  static ParameterProperty number(String description) {
    return ParameterProperty(
      propertyType: 'number',
      description: description,
    );
  }

  static ParameterProperty integer(String description) {
    return ParameterProperty(
      propertyType: 'integer',
      description: description,
    );
  }

  static ParameterProperty boolean(String description) {
    return ParameterProperty(
      propertyType: 'boolean',
      description: description,
    );
  }

  static ParameterProperty array(
    String description, {
    required ParameterProperty items,
  }) {
    return ParameterProperty(
      propertyType: 'array',
      description: description,
      items: items,
    );
  }

  static ParameterProperty object(
    String description, {
    required Map<String, ParameterProperty> properties,
    List<String> required = const <String>[],
  }) {
    return ParameterProperty(
      propertyType: 'object',
      description: description,
      properties: properties,
      required: required.isEmpty ? null : required,
    );
  }
}
