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
