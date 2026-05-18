const String anthropicInterleavedThinkingBeta =
    'interleaved-thinking-2025-05-14';
const String anthropicMcpClientBeta = 'mcp-client-2025-04-04';
const String anthropicExtendedCacheTtlBeta = 'extended-cache-ttl-2025-04-11';
const String anthropicFilesApiBeta = 'files-api-2025-04-14';

List<String> sortedAnthropicBetaFeatures(Set<String> betaFeatures) {
  return betaFeatures.toList(growable: false)..sort();
}

bool containsAnthropicCacheControl(Object? value) {
  if (value is Map) {
    if (value.containsKey('cache_control')) {
      return true;
    }

    for (final nestedValue in value.values) {
      if (containsAnthropicCacheControl(nestedValue)) {
        return true;
      }
    }
    return false;
  }

  if (value is List) {
    return value.any(containsAnthropicCacheControl);
  }

  return false;
}

bool containsAnthropicFileSource(Object? value) {
  if (value is Map) {
    if (value['type'] == 'file' && value.containsKey('file_id')) {
      return true;
    }

    for (final nestedValue in value.values) {
      if (containsAnthropicFileSource(nestedValue)) {
        return true;
      }
    }
    return false;
  }

  if (value is List) {
    return value.any(containsAnthropicFileSource);
  }

  return false;
}
