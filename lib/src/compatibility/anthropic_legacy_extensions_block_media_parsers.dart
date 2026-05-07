part of 'anthropic_legacy_extensions.dart';

AnthropicLegacyImageBlock _parseImageBlock(
  Map<String, Object?> block, {
  required String path,
}) {
  final extraKeys = block.keys.where(
    (key) => key != 'type' && key != 'source' && key != 'cache_control',
  );
  if (extraKeys.isNotEmpty) {
    throw UnsupportedError(
      'Anthropic compatibility only supports type/source/cache_control in raw image blocks.',
    );
  }

  final source = _asMap(
    block['source'],
    path: '$path.source',
  );
  final sourceType = source['type'];
  if (sourceType is! String || sourceType.isEmpty) {
    throw UnsupportedError(
      'Anthropic image source at $path.source requires a type.',
    );
  }

  final cacheControl = block['cache_control'] == null
      ? null
      : _parseCacheControl(
          block['cache_control'],
          path: '$path.cache_control',
        );

  switch (sourceType) {
    case 'base64':
      final mediaType = _parseRequiredString(
        source['media_type'],
        path: '$path.source.media_type',
      );
      if (!_supportedImageMediaTypes.contains(mediaType)) {
        throw UnsupportedError(
          'Anthropic compatibility only supports JPEG, PNG, GIF, and WebP raw image blocks.',
        );
      }

      final data = _parseRequiredString(
        source['data'],
        path: '$path.source.data',
      );

      return AnthropicLegacyImageBlock(
        mediaType: mediaType,
        bytes: _decodeBase64(
          data,
          path: '$path.source.data',
        ),
        cacheControl: cacheControl,
      );
    case 'url':
      return AnthropicLegacyImageBlock(
        mediaType: 'image/*',
        uri: _parseHttpUri(
          source['url'],
          path: '$path.source.url',
        ),
        cacheControl: cacheControl,
      );
    default:
      throw UnsupportedError(
        'Anthropic compatibility only supports base64 and url raw image sources.',
      );
  }
}

AnthropicLegacyDocumentBlock _parseDocumentBlock(
  Map<String, Object?> block, {
  required String path,
}) {
  final extraKeys = block.keys.where(
    (key) =>
        key != 'type' &&
        key != 'source' &&
        key != 'title' &&
        key != 'cache_control',
  );
  if (extraKeys.isNotEmpty) {
    throw UnsupportedError(
      'Anthropic compatibility only supports type/source/title/cache_control in raw document blocks.',
    );
  }

  final source = _asMap(
    block['source'],
    path: '$path.source',
  );
  final sourceType = source['type'];
  if (sourceType is! String || sourceType.isEmpty) {
    throw UnsupportedError(
      'Anthropic document source at $path.source requires a type.',
    );
  }

  final title = block['title'];
  if (title != null && (title is! String || title.isEmpty)) {
    throw UnsupportedError(
      'Anthropic document title at $path.title must be a non-empty string when provided.',
    );
  }

  final cacheControl = block['cache_control'] == null
      ? null
      : _parseCacheControl(
          block['cache_control'],
          path: '$path.cache_control',
        );

  switch (sourceType) {
    case 'base64':
      final mediaType = _parseRequiredString(
        source['media_type'],
        path: '$path.source.media_type',
      );
      if (mediaType != 'application/pdf') {
        throw UnsupportedError(
          'Anthropic compatibility only supports base64 PDF raw document blocks.',
        );
      }

      final data = _parseRequiredString(
        source['data'],
        path: '$path.source.data',
      );

      return AnthropicLegacyDocumentBlock(
        mediaType: mediaType,
        title: title as String?,
        bytes: _decodeBase64(
          data,
          path: '$path.source.data',
        ),
        cacheControl: cacheControl,
      );
    case 'text':
      final mediaType = _parseRequiredString(
        source['media_type'],
        path: '$path.source.media_type',
      );
      if (mediaType != 'text/plain') {
        throw UnsupportedError(
          'Anthropic compatibility only supports text/plain raw text-document blocks.',
        );
      }

      final data = _parseRequiredString(
        source['data'],
        path: '$path.source.data',
      );

      return AnthropicLegacyDocumentBlock(
        mediaType: mediaType,
        title: title as String?,
        bytes: utf8.encode(data),
        cacheControl: cacheControl,
      );
    default:
      throw UnsupportedError(
        'Anthropic compatibility only supports base64 PDF and text/plain raw document sources.',
      );
  }
}
