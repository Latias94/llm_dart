/// Namespaced provider-specific options, similar to Vercel AI SDK `providerOptions`.
///
/// Outer key: provider ID (e.g. "openai", "anthropic", "xai-openai").
/// Inner map: provider-specific options (JSON-like).
typedef ProviderOptions = Map<String, Map<String, dynamic>>;

/// Transport-level configuration (HTTP proxy, headers, timeouts, etc.).
///
/// This is intentionally provider-agnostic. Provider implementations may
/// interpret it based on their underlying HTTP client.
typedef TransportOptions = Map<String, dynamic>;

Map<String, dynamic>? providerOptionsNamespace(
  ProviderOptions providerOptions,
  String providerId, {
  String? fallbackProviderId,
}) {
  final direct = providerOptions[providerId];
  if (direct != null) return direct;
  if (fallbackProviderId == null) return null;
  return providerOptions[fallbackProviderId];
}

T? readProviderOption<T>(
  ProviderOptions providerOptions,
  String providerId,
  String key, {
  String? fallbackProviderId,
}) {
  final ns = providerOptionsNamespace(
    providerOptions,
    providerId,
    fallbackProviderId: fallbackProviderId,
  );
  final raw = ns?[key];
  if (raw is T) return raw;
  return null;
}

/// Read a provider option value and ensure it is a JSON-like map.
///
/// Returns `null` when the option is absent or not a map.
Map<String, dynamic>? readProviderOptionMap(
  ProviderOptions providerOptions,
  String providerId,
  String key, {
  String? fallbackProviderId,
}) {
  final raw = readProviderOption<dynamic>(
    providerOptions,
    providerId,
    key,
    fallbackProviderId: fallbackProviderId,
  );
  if (raw == null) return null;

  if (raw is Map<String, dynamic>) {
    return raw;
  }

  if (raw is! Map) return null;

  final result = <String, dynamic>{};
  try {
    raw.forEach((k, v) {
      if (k is String) result[k] = v;
    });
  } catch (_) {
    return null;
  }
  return result.isEmpty ? null : result;
}

/// Read a provider option value and ensure it is a list.
///
/// Returns `null` when the option is absent or not a list.
List<dynamic>? readProviderOptionList(
  ProviderOptions providerOptions,
  String providerId,
  String key, {
  String? fallbackProviderId,
}) {
  final raw = readProviderOption<dynamic>(
    providerOptions,
    providerId,
    key,
    fallbackProviderId: fallbackProviderId,
  );
  if (raw is! List) return null;
  return raw;
}
