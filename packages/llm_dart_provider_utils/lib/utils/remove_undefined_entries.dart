/// Removes entries where the value is null.
///
/// Mirrors Vercel AI SDK's `removeUndefinedEntries(...)` behavior.
Map<String, T> removeUndefinedEntries<T>(Map<String, T?> record) {
  final out = <String, T>{};
  for (final entry in record.entries) {
    final v = entry.value;
    if (v == null) continue;
    out[entry.key] = v;
  }
  return out;
}
