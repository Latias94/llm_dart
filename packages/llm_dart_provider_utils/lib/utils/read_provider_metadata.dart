/// Read provider-specific metadata from a `providerMetadata` map.
///
/// `providerMetadata` is a namespaced map where keys are provider identifiers
/// (e.g. `openai`, `openai.chat`, `azure.responses`) and values are
/// provider-specific payloads (usually JSON-like maps).
///
/// Canonicalization convention (Vercel AI SDK parity):
/// - Prefer reading the **base provider id** key (e.g. `openai`), where
///   `baseProviderId = providerId.split('.').first`.
/// - Capability keys (e.g. `openai.chat`, `openai.responses`) may be emitted as
///   aliases and should deep-equal the base payload when present.
///
/// Best-effort lookup order:
/// 1. `providerMetadata[baseProviderId]`
/// 2. `providerMetadata[providerId]`
/// 3. Common capability aliases (`$baseProviderId.chat`, `$baseProviderId.responses`)
/// 4. Single-entry map fallback (when the map contains exactly one entry)
T? readProviderMetadata<T>(
  Map<String, dynamic>? providerMetadata,
  String providerId,
) {
  final meta = providerMetadata;
  if (meta == null || meta.isEmpty) return null;

  final trimmedProviderId = providerId.trim();
  final String? baseProviderId =
      trimmedProviderId.isEmpty ? null : _baseProviderId(trimmedProviderId);

  dynamic readKey(String key) => meta.containsKey(key) ? meta[key] : null;

  if (baseProviderId != null) {
    final base = readKey(baseProviderId);
    if (base is T) return base;
  }

  if (trimmedProviderId.isNotEmpty) {
    final direct = readKey(trimmedProviderId);
    if (direct is T) return direct;
  }

  if (baseProviderId != null) {
    final chat = readKey('$baseProviderId.chat');
    if (chat is T) return chat;

    final responses = readKey('$baseProviderId.responses');
    if (responses is T) return responses;
  }

  if (meta.length == 1) {
    final only = meta.values.first;
    if (only is T) return only;
  }

  return null;
}

String _baseProviderId(String providerId) {
  final idx = providerId.indexOf('.');
  if (idx <= 0) return providerId;
  return providerId.substring(0, idx);
}
