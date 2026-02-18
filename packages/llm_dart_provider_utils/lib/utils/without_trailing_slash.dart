/// Removes a single trailing `/` from the URL, if present.
///
/// Mirrors Vercel AI SDK's `withoutTrailingSlash(...)`.
String? withoutTrailingSlash(String? url) {
  if (url == null) return null;
  if (!url.endsWith('/')) return url;
  return url.substring(0, url.length - 1);
}
