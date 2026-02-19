/// Mirrors Vercel AI SDK's `isUrlSupported(...)`.
///
/// Checks if [url] is supported by a model given a [supportedUrls] registry.
///
/// Notes:
/// - [mediaType] and [url] are normalized to lowercase before matching.
/// - Keys in [supportedUrls] may use wildcards like `image/*`, `*/*`, or `*`.
bool isUrlSupported({
  required String mediaType,
  required String url,
  required Map<String, List<RegExp>> supportedUrls,
}) {
  final urlLower = url.toLowerCase();
  final mediaTypeLower = mediaType.toLowerCase();

  final regexes = supportedUrls.entries
      .map((entry) {
        final keyLower = entry.key.toLowerCase();
        if (keyLower == '*' || keyLower == '*/*') {
          return (mediaTypePrefix: '', regexes: entry.value);
        }
        return (
          mediaTypePrefix: keyLower.replaceAll('*', ''),
          regexes: entry.value,
        );
      })
      .where((e) => mediaTypeLower.startsWith(e.mediaTypePrefix))
      .expand((e) => e.regexes);

  for (final pattern in regexes) {
    if (pattern.hasMatch(urlLower)) return true;
  }

  return false;
}
