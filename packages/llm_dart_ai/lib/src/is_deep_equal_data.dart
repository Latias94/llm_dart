/// Performs a deep-equal comparison of two JSON-like objects.
///
/// Mirrors Vercel AI SDK's `isDeepEqualData(...)`.
bool isDeepEqualData(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;

  if (a is num || a is bool || a is String) {
    return a == b;
  }

  if (a is DateTime && b is DateTime) {
    return a.isAtSameMomentAs(b);
  }

  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!isDeepEqualData(a[i], b[i])) return false;
    }
    return true;
  }

  if (a is Map && b is Map) {
    if (a.length != b.length) return false;

    for (final entry in a.entries) {
      final key = entry.key;
      if (key is! String) return false;
      if (!b.containsKey(key)) return false;
      if (!isDeepEqualData(entry.value, b[key])) return false;
    }
    return true;
  }

  return a == b;
}
