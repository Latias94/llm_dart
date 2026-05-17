Object? freezeStructuredOutputJsonValue(Object? value) {
  return switch (value) {
    null || bool() || num() || String() => value,
    List() => List<Object?>.unmodifiable(
        value.map(freezeStructuredOutputJsonValue),
      ),
    Map() => Map<String, Object?>.unmodifiable(
        value.map(
          (key, nestedValue) => MapEntry(
            key as String,
            freezeStructuredOutputJsonValue(nestedValue),
          ),
        ),
      ),
    _ => value,
  };
}

bool structuredOutputValueEquals(Object? left, Object? right) {
  if (identical(left, right)) {
    return true;
  }

  if (left is List && right is List) {
    if (left.length != right.length) {
      return false;
    }

    for (var index = 0; index < left.length; index++) {
      if (!structuredOutputValueEquals(left[index], right[index])) {
        return false;
      }
    }

    return true;
  }

  if (left is Map && right is Map) {
    if (left.length != right.length) {
      return false;
    }

    for (final entry in left.entries) {
      if (!right.containsKey(entry.key) ||
          !structuredOutputValueEquals(entry.value, right[entry.key])) {
        return false;
      }
    }

    return true;
  }

  return left == right;
}
