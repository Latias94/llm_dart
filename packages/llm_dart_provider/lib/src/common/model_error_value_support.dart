import 'json_codec_common.dart';

Object? freezeModelErrorJsonValue(Object? value) {
  return switch (value) {
    List() => List<Object?>.unmodifiable(
        value.map(freezeModelErrorJsonValue),
      ),
    Map() => Map<String, Object?>.unmodifiable(
        asJsonMap(value, path: r'$.error.details').map((key, nested) {
          return MapEntry(key, freezeModelErrorJsonValue(nested));
        }),
      ),
    _ => value,
  };
}

bool modelErrorDeepEquals(Object? left, Object? right) {
  if (identical(left, right)) {
    return true;
  }

  if (left is Map && right is Map) {
    if (left.length != right.length) {
      return false;
    }

    for (final entry in left.entries) {
      if (!right.containsKey(entry.key)) {
        return false;
      }

      if (!modelErrorDeepEquals(entry.value, right[entry.key])) {
        return false;
      }
    }

    return true;
  }

  if (left is List && right is List) {
    if (left.length != right.length) {
      return false;
    }

    for (var index = 0; index < left.length; index += 1) {
      if (!modelErrorDeepEquals(left[index], right[index])) {
        return false;
      }
    }

    return true;
  }

  return left == right;
}

int modelErrorDeepHash(Object? value) {
  return switch (value) {
    null => 0,
    Map() => Object.hashAll(
        value.entries
            .map(
              (entry) => (
                key: entry.key.toString(),
                hash: Object.hash(
                  entry.key,
                  modelErrorDeepHash(entry.value),
                ),
              ),
            )
            .toList()
          ..sort((left, right) => left.key.compareTo(right.key)),
      ),
    List() => Object.hashAll(value.map(modelErrorDeepHash)),
    _ => value.hashCode,
  };
}
