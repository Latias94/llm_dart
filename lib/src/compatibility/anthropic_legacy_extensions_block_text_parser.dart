part of 'anthropic_legacy_extensions.dart';

AnthropicLegacyTextBlock _parseTextBlock(
  Map<String, Object?> block, {
  required String path,
}) {
  final extraKeys = block.keys.where(
    (key) => key != 'type' && key != 'text' && key != 'cache_control',
  );
  if (extraKeys.isNotEmpty) {
    throw UnsupportedError(
      'Anthropic compatibility only supports type/text/cache_control in raw text blocks.',
    );
  }

  final text = block['text'];
  if (text is! String) {
    throw UnsupportedError(
      'Anthropic text block at $path requires a string text field.',
    );
  }

  return AnthropicLegacyTextBlock(
    text: text,
    cacheControl: block['cache_control'] == null
        ? null
        : _parseCacheControl(
            block['cache_control'],
            path: '$path.cache_control',
          ),
  );
}
