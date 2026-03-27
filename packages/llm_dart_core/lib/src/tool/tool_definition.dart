sealed class ToolChoice {
  const ToolChoice();
}

final class AutoToolChoice extends ToolChoice {
  const AutoToolChoice();
}

final class RequiredToolChoice extends ToolChoice {
  const RequiredToolChoice();
}

final class NoneToolChoice extends ToolChoice {
  const NoneToolChoice();
}

final class SpecificToolChoice extends ToolChoice {
  final String toolName;

  const SpecificToolChoice(this.toolName);
}

final class ToolJsonSchema {
  final Map<String, Object?> _json;

  ToolJsonSchema._(Map<String, Object?> json) : _json = Map.unmodifiable(json);

  /// Creates a tool input schema from a raw JSON Schema object.
  ///
  /// Tool input schemas are intentionally constrained to an object root,
  /// because cross-provider function calling expects object-shaped arguments.
  factory ToolJsonSchema.raw(Map<String, Object?> schema) {
    final normalized = _normalizeJsonObject(
      schema,
      path: r'$.inputSchema',
    );

    if (normalized['type'] != 'object') {
      throw ArgumentError.value(
        schema,
        'schema',
        'Tool input schemas must use a JSON object root with type "object".',
      );
    }

    final propertiesValue = normalized['properties'];
    final requiredValue = normalized['required'];

    final propertyNames = switch (propertiesValue) {
      null => const <String>{},
      Map<String, Object?>() => propertiesValue.keys.toSet(),
      _ => throw ArgumentError.value(
          schema,
          'schema',
          'Tool input schema properties must be a JSON object.',
        ),
    };

    switch (requiredValue) {
      case null:
        break;
      case List():
        for (var index = 0; index < requiredValue.length; index++) {
          final entry = requiredValue[index];
          if (entry is! String) {
            throw ArgumentError.value(
              schema,
              'schema',
              'Tool input schema required[$index] must be a string.',
            );
          }

          if (propertyNames.isNotEmpty && !propertyNames.contains(entry)) {
            throw ArgumentError.value(
              schema,
              'schema',
              'Tool input schema required field "$entry" is missing from properties.',
            );
          }
        }
      default:
        throw ArgumentError.value(
          schema,
          'schema',
          'Tool input schema required must be a JSON array.',
        );
    }

    return ToolJsonSchema._(normalized);
  }

  /// Creates a JSON object schema for function-tool input.
  factory ToolJsonSchema.object({
    Map<String, Object?> properties = const {},
    List<String> required = const [],
    String? description,
    Object? additionalProperties,
    Map<String, Object?> extra = const {},
  }) {
    return ToolJsonSchema.raw({
      'type': 'object',
      if (description != null) 'description': description,
      if (properties.isNotEmpty) 'properties': properties,
      if (required.isNotEmpty) 'required': required,
      if (additionalProperties != null)
        'additionalProperties': additionalProperties,
      ...extra,
    });
  }

  Map<String, Object?> toJson() => Map.unmodifiable(_json);
}

sealed class ToolDefinition {
  const ToolDefinition();

  String get name;
}

final class FunctionToolDefinition extends ToolDefinition {
  @override
  final String name;

  final String? description;
  final ToolJsonSchema inputSchema;
  final bool? strict;

  const FunctionToolDefinition({
    required this.name,
    this.description,
    required this.inputSchema,
    this.strict,
  });
}

Map<String, Object?> _normalizeJsonObject(
  Map<String, Object?> value, {
  required String path,
}) {
  final normalized = <String, Object?>{};

  for (final entry in value.entries) {
    normalized[entry.key] = _normalizeJsonValue(
      entry.value,
      path: '$path.${entry.key}',
    );
  }

  return normalized;
}

Object? _normalizeJsonValue(
  Object? value, {
  required String path,
}) {
  return switch (value) {
    null || bool() || num() || String() => value,
    List() => value
        .asMap()
        .entries
        .map(
          (entry) => _normalizeJsonValue(
            entry.value,
            path: '$path[${entry.key}]',
          ),
        )
        .toList(growable: false),
    Map() => _normalizeAnonymousMap(value, path: path),
    _ => throw ArgumentError.value(
        value,
        path,
        'Tool schemas only support JSON-safe values.',
      ),
  };
}

Map<String, Object?> _normalizeAnonymousMap(
  Map value, {
  required String path,
}) {
  final normalized = <String, Object?>{};

  for (final entry in value.entries) {
    final key = entry.key;
    if (key is! String) {
      throw ArgumentError.value(
        key,
        path,
        'Tool schemas only support string object keys.',
      );
    }

    normalized[key] = _normalizeJsonValue(
      entry.value,
      path: '$path.$key',
    );
  }

  return normalized;
}
