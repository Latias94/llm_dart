/// Header helpers aligned with Vercel AI SDK's `@ai-sdk/provider-utils`.
///
/// See upstream: `combineHeaders(...)`.
Map<String, String?> combineHeaders([
  Map<String, String?>? h1,
  Map<String, String?>? h2,
  Map<String, String?>? h3,
  Map<String, String?>? h4,
  Map<String, String?>? h5,
]) {
  final out = <String, String?>{};

  void merge(Map<String, String?>? headers) {
    if (headers == null) return;
    for (final entry in headers.entries) {
      out[entry.key] = entry.value;
    }
  }

  merge(h1);
  merge(h2);
  merge(h3);
  merge(h4);
  merge(h5);

  return out;
}
