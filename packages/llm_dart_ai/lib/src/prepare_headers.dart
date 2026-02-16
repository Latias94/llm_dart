/// Prepares HTTP response headers by applying defaults.
///
/// Mirrors Vercel AI SDK `prepareHeaders`:
/// - Start with the provided headers (if any)
/// - Add each default header only when it is not already present
/// - Header name checks are case-insensitive
library;

Map<String, String> prepareHeaders(
  Map<String, String>? headers,
  Map<String, String> defaultHeaders,
) {
  final out = <String, String>{};
  if (headers != null && headers.isNotEmpty) {
    out.addAll(headers);
  }

  final existingLower = <String>{};
  for (final key in out.keys) {
    existingLower.add(key.toLowerCase());
  }

  for (final entry in defaultHeaders.entries) {
    final keyLower = entry.key.toLowerCase();
    if (existingLower.contains(keyLower)) continue;
    out[entry.key] = entry.value;
  }

  return Map<String, String>.unmodifiable(out);
}
