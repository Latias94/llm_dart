part of 'anthropic_legacy_extensions.dart';

bool _isAnthropicCacheMarker(Map<String, Object?> block) {
  return block['type'] == 'text' &&
      block['text'] == '' &&
      block['cache_control'] != null;
}
