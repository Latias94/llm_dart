/// Normalizes header inputs into a plain map with lower-case keys.
///
/// This mirrors Vercel AI SDK's `normalizeHeaders(...)` behavior:
/// - Keys are lower-cased
/// - `null` values are removed
///
/// Supported inputs:
/// - `Map` (keys converted to string)
/// - `List` of 2-element tuples (e.g. `[[key, value], ...]`)
Map<String, String> normalizeHeaders(Object? headers) {
  if (headers == null) return const <String, String>{};

  final normalized = <String, String>{};

  if (headers is Map) {
    for (final entry in headers.entries) {
      final key = entry.key.toString().toLowerCase();
      final value = entry.value;
      if (value == null) continue;
      normalized[key] = value.toString();
    }
    return normalized;
  }

  if (headers is List) {
    for (final item in headers) {
      if (item is! List || item.length < 2) continue;
      final key = item[0]?.toString();
      final value = item[1];
      if (key == null || key.isEmpty || value == null) continue;
      normalized[key.toLowerCase()] = value.toString();
    }
    return normalized;
  }

  return const <String, String>{};
}
