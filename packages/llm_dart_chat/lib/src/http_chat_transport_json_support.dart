typedef HttpChatTransportJsonMap = Map<String, Object?>;
typedef HttpChatTransportJsonList = List<Object?>;

final class HttpChatTransportJson {
  const HttpChatTransportJson._();

  static Object? ensureValue(
    Object? value, {
    required String path,
  }) {
    return switch (value) {
      null || bool() || num() || String() => value,
      List() => value
          .asMap()
          .entries
          .map(
            (entry) => ensureValue(
              entry.value,
              path: '$path[${entry.key}]',
            ),
          )
          .toList(growable: false),
      Map() => ensureMap(value, path: path),
      _ => throw FormatException(
          'Unsupported non-JSON value at $path: ${value.runtimeType}',
        ),
    };
  }

  static HttpChatTransportJsonMap ensureMap(
    Map value, {
    required String path,
  }) {
    final result = <String, Object?>{};

    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw FormatException('Expected string key at $path.');
      }

      result[entry.key as String] = ensureValue(
        entry.value,
        path: '$path.${entry.key}',
      );
    }

    return result;
  }

  static HttpChatTransportJsonMap asMap(
    Object? value, {
    required String path,
  }) {
    if (value is! Map) {
      throw FormatException('Expected JSON object at $path.');
    }

    return value.map((key, nestedValue) {
      if (key is! String) {
        throw FormatException('Expected string key at $path.');
      }

      return MapEntry(key, nestedValue);
    });
  }

  static Map<String, String> asStringMap(
    Object? value, {
    required String path,
  }) {
    final map = asMap(value, path: path);
    return map.map(
      (key, nestedValue) => MapEntry(
        key,
        asString(nestedValue, path: '$path.$key'),
      ),
    );
  }

  static HttpChatTransportJsonList asList(
    Object? value, {
    required String path,
  }) {
    if (value is! List) {
      throw FormatException('Expected JSON array at $path.');
    }

    return value.cast<Object?>();
  }

  static String asString(
    Object? value, {
    required String path,
  }) {
    if (value is! String) {
      throw FormatException('Expected string at $path.');
    }

    return value;
  }

  static String? asNullableString(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return null;
    }

    return asString(value, path: path);
  }

  static bool? asNullableBool(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return null;
    }

    if (value is bool) {
      return value;
    }

    throw FormatException('Expected bool at $path.');
  }

  static int? asNullableInt(
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

  static int? asNullableNonNegativeInt(
    Object? value, {
    required String path,
  }) {
    final intValue = asNullableInt(value, path: path);
    if (intValue == null || intValue >= 0) {
      return intValue;
    }

    throw FormatException('Expected non-negative int at $path.');
  }

  static double? asNullableDouble(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    throw FormatException('Expected number at $path.');
  }
}
