/// Call-level options for a single provider request.
///
/// This mirrors the AI SDK idea that you can override request headers and
/// include additional JSON fields per call, without mutating global provider
/// configuration.
library;

class LLMCallOptions {
  /// Additional HTTP headers for the call (best-effort).
  ///
  /// Providers may ignore this when they are not HTTP-based.
  /// When supported, these headers should override any default headers
  /// configured on the provider (case-insensitive).
  final Map<String, String>? headers;

  /// Additional JSON fields to merge into the provider request body.
  ///
  /// This is intended as an escape hatch for provider-specific fields.
  /// When supported, these fields should override standard fields when keys
  /// collide.
  final Map<String, dynamic>? body;

  const LLMCallOptions({
    this.headers,
    this.body,
  });

  /// Returns a new request body with [body] deeply merged into [requestBody].
  ///
  /// - Properties from [body] override those in [requestBody] with the same key.
  /// - Nested maps are merged recursively (deep merge).
  /// - Lists are replaced, not merged.
  /// - Primitive values are replaced.
  ///
  /// This mirrors the AI SDK `mergeObjects` semantics.
  Map<String, dynamic> mergeIntoRequestBody(
    Map<String, dynamic> requestBody,
  ) {
    final extra = body;
    if (extra == null || extra.isEmpty) return requestBody;
    if (requestBody.isEmpty) return Map<String, dynamic>.from(extra);
    return _deepMergeJsonMaps(requestBody, extra);
  }

  bool get isEmpty =>
      (headers == null || headers!.isEmpty) && (body == null || body!.isEmpty);
}

Map<String, dynamic> _deepMergeJsonMaps(
  Map<String, dynamic> a,
  Map<String, dynamic> b,
) {
  final out = Map<String, dynamic>.from(a);
  for (final entry in b.entries) {
    final key = entry.key;
    final bv = entry.value;
    final av = out[key];
    if (av is Map && bv is Map) {
      out[key] = _deepMergeJsonMaps(
        _asStringDynamicMap(av),
        _asStringDynamicMap(bv),
      );
    } else {
      out[key] = bv;
    }
  }
  return out;
}

Map<String, dynamic> _asStringDynamicMap(Map input) {
  if (input is Map<String, dynamic>) return input;
  final out = <String, dynamic>{};
  input.forEach((k, v) {
    out[k.toString()] = v;
  });
  return out;
}
