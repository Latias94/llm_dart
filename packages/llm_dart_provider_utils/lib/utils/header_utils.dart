/// Header utilities shared across providers.
library;

/// Remove all header entries whose name matches [headerName] case-insensitively.
void removeHeaderIgnoreCase(Map<String, String> headers, String headerName) {
  final needle = headerName.toLowerCase();
  final keysToRemove = <String>[];
  for (final k in headers.keys) {
    if (k.toLowerCase() == needle) keysToRemove.add(k);
  }
  for (final k in keysToRemove) {
    headers.remove(k);
  }
}

/// Set a header value, removing any existing entries with the same name
/// (case-insensitive).
void setHeaderCaseInsensitive(
  Map<String, String> headers,
  String headerName,
  String value,
) {
  removeHeaderIgnoreCase(headers, headerName);
  headers[headerName] = value;
}

/// Merge headers with case-insensitive key matching.
///
/// - Entries from [overrides] take precedence.
/// - When overriding `User-Agent`, values are concatenated as:
///   `overrides['User-Agent'] + base['User-Agent']` (space-separated).
///
/// This mirrors the behavior used by `HttpConfigUtils`.
Map<String, String> mergeHeadersCaseInsensitive(
  Map<String, String> base,
  Map<String, String> overrides,
) {
  if (overrides.isEmpty) return base;

  final result = <String, String>{...base};

  for (final entry in overrides.entries) {
    final keyLower = entry.key.toLowerCase();
    final existingKeys = result.keys
        .where((k) => k.toLowerCase() == keyLower)
        .toList(growable: false);

    final isUserAgent = keyLower == 'user-agent';
    if (isUserAgent) {
      final existingValues = existingKeys
          .map((k) => result[k])
          .whereType<String>()
          .where((v) => v.trim().isNotEmpty)
          .toList(growable: false);

      for (final k in existingKeys) {
        result.remove(k);
      }

      final customValue = entry.value.trim();
      final combined = [
        if (customValue.isNotEmpty) customValue,
        ...existingValues,
      ].join(' ');
      if (combined.isNotEmpty) {
        result['User-Agent'] = combined;
      }
      continue;
    }

    for (final k in existingKeys) {
      result.remove(k);
    }
    result[entry.key] = entry.value;
  }

  return result;
}
