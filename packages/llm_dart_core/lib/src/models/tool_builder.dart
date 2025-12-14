import 'tool_models.dart';

/// Fluent builder for constructing function tools and their parameter schemas.
///
/// This builder provides a more ergonomic API on top of the lower-level
/// [Tool], [ParametersSchema], and [ParameterProperty] types. It is
/// especially useful when defining tools with many parameters or nested
/// objects, where writing JSON schema maps by hand becomes verbose.
class ToolBuilder {
  /// Logical function/tool name exposed to the model.
  final String name;

  String _description = '';
  final Map<String, ParameterProperty> _properties = {};
  final List<String> _required = [];

  ToolBuilder(this.name);

  /// Set human-readable description for this tool.
  ToolBuilder description(String description) {
    _description = description;
    return this;
  }

  /// Register a raw [ParameterProperty] for advanced scenarios.
  ///
  /// This is the lowest-level escape hatch. For most cases prefer the
  /// typed helpers like [stringParam], [enumParam], [arrayParam], etc.
  ToolBuilder property(
    String paramName,
    ParameterProperty property, {
    bool required = false,
  }) {
    _properties[paramName] = property;
    if (required && !_required.contains(paramName)) {
      _required.add(paramName);
    }
    return this;
  }

  /// Define a `string` parameter.
  ToolBuilder stringParam(
    String paramName, {
    String? description,
    bool required = false,
  }) {
    return property(
      paramName,
      ParameterProperty(
        propertyType: 'string',
        description: description ?? paramName,
      ),
      required: required,
    );
  }

  /// Define a `number` parameter.
  ToolBuilder numberParam(
    String paramName, {
    String? description,
    bool required = false,
  }) {
    return property(
      paramName,
      ParameterProperty(
        propertyType: 'number',
        description: description ?? paramName,
      ),
      required: required,
    );
  }

  /// Define an `integer` parameter.
  ToolBuilder integerParam(
    String paramName, {
    String? description,
    bool required = false,
  }) {
    return property(
      paramName,
      ParameterProperty(
        propertyType: 'integer',
        description: description ?? paramName,
      ),
      required: required,
    );
  }

  /// Define a `boolean` parameter.
  ToolBuilder booleanParam(
    String paramName, {
    String? description,
    bool required = false,
  }) {
    return property(
      paramName,
      ParameterProperty(
        propertyType: 'boolean',
        description: description ?? paramName,
      ),
      required: required,
    );
  }

  /// Define an enum-like `string` parameter.
  ///
  /// This uses the underlying `enum` JSON schema keyword while keeping
  /// the type as `string`.
  ToolBuilder enumParam(
    String paramName, {
    required List<String> values,
    String? description,
    bool required = false,
  }) {
    return property(
      paramName,
      ParameterProperty(
        propertyType: 'string',
        description: description ?? paramName,
        enumList: values,
      ),
      required: required,
    );
  }

  /// Define an `array` parameter with a given item schema.
  ToolBuilder arrayParam(
    String paramName, {
    required ParameterProperty items,
    String? description,
    bool required = false,
  }) {
    return property(
      paramName,
      ParameterProperty(
        propertyType: 'array',
        description: description ?? paramName,
        items: items,
      ),
      required: required,
    );
  }

  /// Define an `object` parameter with nested properties.
  ///
  /// This is useful for grouping related settings under a single
  /// object-valued parameter.
  ToolBuilder objectParam(
    String paramName, {
    required String description,
    required Map<String, ParameterProperty> properties,
    List<String>? requiredKeys,
    bool required = false,
  }) {
    return property(
      paramName,
      ParameterProperty(
        propertyType: 'object',
        description: description,
        properties: properties,
        required: requiredKeys,
      ),
      required: required,
    );
  }

  /// Build the final [Tool] instance with a function definition and
  /// JSON-schema style parameters.
  Tool build() {
    return Tool.function(
      name: name,
      description: _description,
      parameters: ParametersSchema(
        schemaType: 'object',
        properties: Map.unmodifiable(_properties),
        required: List.unmodifiable(_required),
      ),
    );
  }
}

/// Top-level helper for building a function [Tool] with a concise API.
///
/// Example:
/// ```dart
/// final getWeather = tool('getWeather', (t) {
///   t
///     ..description('Get weather for a city')
///     ..stringParam('city', description: 'City name', required: true)
///     ..enumParam(
///       'unit',
///       description: 'Temperature unit',
///       values: ['c', 'f'],
///     );
/// });
/// ```
Tool tool(
  String name,
  void Function(ToolBuilder builder) configure,
) {
  final builder = ToolBuilder(name);
  configure(builder);
  return builder.build();
}
