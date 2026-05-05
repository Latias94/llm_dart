final class JsonSchema {
  final Map<String, Object?> _json;

  JsonSchema._(Map<String, Object?> json) : _json = Map.unmodifiable(json);

  factory JsonSchema.raw(Map<String, Object?> schema) {
    return JsonSchema._(
      _normalizeJsonObject(
        schema,
        path: r'$.schema',
      ),
    );
  }

  factory JsonSchema.object({
    Map<String, Object?> properties = const {},
    List<String> required = const [],
    String? description,
    Object? additionalProperties,
    Map<String, Object?> extra = const {},
  }) {
    return JsonSchema.raw({
      'type': 'object',
      if (description != null) 'description': description,
      if (properties.isNotEmpty) 'properties': properties,
      if (required.isNotEmpty) 'required': required,
      if (additionalProperties != null)
        'additionalProperties': additionalProperties,
      ...extra,
    });
  }

  factory JsonSchema.array({
    Object? items,
    String? description,
    Object? minItems,
    Object? maxItems,
    Map<String, Object?> extra = const {},
  }) {
    return JsonSchema.raw({
      'type': 'array',
      if (description != null) 'description': description,
      if (items != null) 'items': items,
      if (minItems != null) 'minItems': minItems,
      if (maxItems != null) 'maxItems': maxItems,
      ...extra,
    });
  }

  factory JsonSchema.string({
    String? description,
    List<String>? enumValues,
    Map<String, Object?> extra = const {},
  }) {
    return JsonSchema.raw({
      'type': 'string',
      if (description != null) 'description': description,
      if (enumValues != null) 'enum': enumValues,
      ...extra,
    });
  }

  Map<String, Object?> toJson() => Map.unmodifiable(_json);
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
        'JSON schemas only support JSON-safe values.',
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
        'JSON schemas only support string object keys.',
      );
    }

    normalized[key] = _normalizeJsonValue(
      entry.value,
      path: '$path.$key',
    );
  }

  return normalized;
}
