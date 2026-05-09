import 'dart:convert';

import 'anthropic_legacy_extensions_models.dart';
import 'anthropic_legacy_extensions_utils.dart';

AnthropicLegacyImageBlock parseAnthropicLegacyImageBlock(
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

  final source = asAnthropicLegacyMap(
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
      : parseAnthropicLegacyCacheControl(
          block['cache_control'],
          path: '$path.cache_control',
        );

  switch (sourceType) {
    case 'base64':
      final mediaType = parseAnthropicLegacyRequiredString(
        source['media_type'],
        path: '$path.source.media_type',
      );
      if (!supportedAnthropicLegacyImageMediaTypes.contains(mediaType)) {
        throw UnsupportedError(
          'Anthropic compatibility only supports JPEG, PNG, GIF, and WebP raw image blocks.',
        );
      }

      final data = parseAnthropicLegacyRequiredString(
        source['data'],
        path: '$path.source.data',
      );

      return AnthropicLegacyImageBlock(
        mediaType: mediaType,
        bytes: decodeAnthropicLegacyBase64(
          data,
          path: '$path.source.data',
        ),
        cacheControl: cacheControl,
      );
    case 'url':
      return AnthropicLegacyImageBlock(
        mediaType: 'image/*',
        uri: parseAnthropicLegacyHttpUri(
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

AnthropicLegacyDocumentBlock parseAnthropicLegacyDocumentBlock(
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

  final source = asAnthropicLegacyMap(
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
      : parseAnthropicLegacyCacheControl(
          block['cache_control'],
          path: '$path.cache_control',
        );

  switch (sourceType) {
    case 'base64':
      final mediaType = parseAnthropicLegacyRequiredString(
        source['media_type'],
        path: '$path.source.media_type',
      );
      if (mediaType != 'application/pdf') {
        throw UnsupportedError(
          'Anthropic compatibility only supports base64 PDF raw document blocks.',
        );
      }

      final data = parseAnthropicLegacyRequiredString(
        source['data'],
        path: '$path.source.data',
      );

      return AnthropicLegacyDocumentBlock(
        mediaType: mediaType,
        title: title as String?,
        bytes: decodeAnthropicLegacyBase64(
          data,
          path: '$path.source.data',
        ),
        cacheControl: cacheControl,
      );
    case 'text':
      final mediaType = parseAnthropicLegacyRequiredString(
        source['media_type'],
        path: '$path.source.media_type',
      );
      if (mediaType != 'text/plain') {
        throw UnsupportedError(
          'Anthropic compatibility only supports text/plain raw text-document blocks.',
        );
      }

      final data = parseAnthropicLegacyRequiredString(
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
