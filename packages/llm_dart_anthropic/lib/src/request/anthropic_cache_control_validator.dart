import '../models/anthropic_models.dart';

/// Validator for Anthropic cache_control usage.
///
/// This mirrors the behavior of the Vercel AI SDK's CacheControlValidator
/// in spirit, while keeping the implementation light-weight for Dart:
///
/// - At most 4 cache breakpoints per request
/// - cache_control can only be set in allowed contexts
/// - Unsupported usages are silently ignored for now (no warnings surfaced)
class AnthropicCacheControlValidator {
  static const int _maxCacheBreakpoints = 4;

  int _breakpointCount = 0;

  /// Extracts cache_control config from Anthropic-specific provider options.
  ///
  /// [providerOptions] is expected to be the Anthropic provider options map,
  /// e.g. the value of `providerOptions['anthropic']`.
  /// Recognized keys:
  /// - `cacheControl`: `{ "type": "ephemeral", "ttl": "5m" | "1h" }`
  /// - `cache_control`: same as above (alternate casing)
  AnthropicCacheControl? _extractCacheControl(
    Map<String, dynamic>? providerOptions,
  ) {
    if (providerOptions == null) return null;

    final raw =
        providerOptions['cacheControl'] ?? providerOptions['cache_control'];

    if (raw is! Map<String, dynamic>) return null;

    final type = raw['type'];
    if (type != 'ephemeral') return null;

    final ttl = raw['ttl'] as String?;
    if (ttl == null) {
      return const AnthropicCacheControl.ephemeral();
    }

    final ttlEnum = AnthropicCacheTtl.fromString(ttl);
    return AnthropicCacheControl.ephemeral(ttl: ttlEnum?.value ?? ttl);
  }

  /// Returns an AnthropicCacheControl for the given context if allowed,
  /// or null if the cache setting should be ignored.
  ///
  /// [contextType] is a human-readable description used for diagnostics,
  /// e.g. "system message", "user message part".
  /// [canCache] indicates whether cache_control is allowed in this position.
  AnthropicCacheControl? getCacheControl(
    Map<String, dynamic>? providerOptions, {
    required String contextType,
    required bool canCache,
  }) {
    final cacheControl = _extractCacheControl(providerOptions);
    if (cacheControl == null) return null;

    if (!canCache) {
      // In the future we may surface a CallWarning here.
      return null;
    }

    _breakpointCount++;
    if (_breakpointCount > _maxCacheBreakpoints) {
      // In the future we may surface a CallWarning here as well.
      return null;
    }

    return cacheControl;
  }
}
