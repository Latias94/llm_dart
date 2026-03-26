typedef JsonMap = Map<String, Object?>;
typedef JsonList = List<Object?>;

Object? ensureJsonValue(
  Object? value, {
  String path = r'$',
}) {
  return switch (value) {
    null || bool() || num() || String() => value,
    List() => value
        .asMap()
        .entries
        .map(
          (entry) => ensureJsonValue(
            entry.value,
            path: '$path[${entry.key}]',
          ),
        )
        .toList(growable: false),
    Map() => _ensureJsonMap(value, path: path),
    _ => throw FormatException(
        'Unsupported non-JSON value at $path: ${value.runtimeType}',
      ),
  };
}

JsonMap asJsonMap(
  Object? value, {
  required String path,
}) {
  if (value is! Map) {
    throw FormatException('Expected JSON object at $path.');
  }

  return value.map((key, value) {
    if (key is! String) {
      throw FormatException('Expected string key at $path.');
    }

    return MapEntry(key, value);
  });
}

JsonList asJsonList(
  Object? value, {
  required String path,
}) {
  if (value is! List) {
    throw FormatException('Expected JSON array at $path.');
  }

  return value.cast<Object?>();
}

String asJsonString(
  Object? value, {
  required String path,
}) {
  if (value is! String) {
    throw FormatException('Expected string at $path.');
  }

  return value;
}

String? asNullableJsonString(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  return asJsonString(value, path: path);
}

bool asJsonBool(
  Object? value, {
  required String path,
}) {
  if (value is! bool) {
    throw FormatException('Expected bool at $path.');
  }

  return value;
}

bool? asNullableJsonBool(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  return asJsonBool(value, path: path);
}

int? asNullableJsonInt(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  throw FormatException('Expected int at $path.');
}

JsonMap _ensureJsonMap(
  Map value, {
  required String path,
}) {
  final result = <String, Object?>{};

  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('Expected string key at $path.');
    }

    result[entry.key as String] = ensureJsonValue(
      entry.value,
      path: '$path.${entry.key}',
    );
  }

  return result;
}
