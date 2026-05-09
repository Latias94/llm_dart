bool isAnthropicLegacyCacheMarker(Map<String, Object?> block) {
  return block['type'] == 'text' &&
      block['text'] == '' &&
      block['cache_control'] != null;
}
