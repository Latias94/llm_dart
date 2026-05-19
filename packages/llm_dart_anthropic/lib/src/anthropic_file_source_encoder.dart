import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_prompt_limitations.dart';

final class AnthropicFileSourceEncoder {
  const AnthropicFileSourceEncoder();

  Map<String, Object?> encodeUserBinarySource({
    required String mediaType,
    required FileData data,
    required String path,
  }) {
    if (data.providerReference case final reference?) {
      return {
        'type': 'file',
        'file_id': reference.requireProvider(
          'anthropic',
          context: 'Anthropic $path',
        ),
      };
    }

    final bytes = data.bytes;
    if (bytes != null) {
      return {
        'type': 'base64',
        'media_type': mediaType,
        'data': base64Encode(bytes),
      };
    }

    final uri = data.uri;
    if (uri != null && _isHttpUri(uri)) {
      return {
        'type': 'url',
        'url': uri.toString(),
      };
    }

    throw missingAnthropicUserBinarySource(path);
  }

  Map<String, Object?> encodeUserTextDocumentSource({
    required FileData data,
    required String path,
  }) {
    if (data.providerReference case final reference?) {
      return {
        'type': 'file',
        'file_id': reference.requireProvider(
          'anthropic',
          context: 'Anthropic $path',
        ),
      };
    }

    if (data.text case final text?) {
      return {
        'type': 'text',
        'media_type': 'text/plain',
        'data': text,
      };
    }

    if (data.bytes case final bytes?) {
      return {
        'type': 'text',
        'media_type': 'text/plain',
        'data': utf8.decode(bytes),
      };
    }

    final uri = data.uri;
    if (uri != null && _isHttpUri(uri)) {
      return {
        'type': 'url',
        'url': uri.toString(),
      };
    }

    throw missingAnthropicUserTextDocumentSource();
  }

  Map<String, Object?> encodeToolOutputFileBlock({
    required String mediaType,
    required String? filename,
    required FileData data,
    required String path,
  }) {
    final reference = data.providerReference;
    final isImage = isImageMediaType(mediaType);
    final hasAnthropicReference =
        reference?.containsProvider('anthropic') == true;
    final isDocument = isImage ||
        hasAnthropicReference ||
        isDocumentToolOutputMediaType(mediaType);

    if (!isDocument) {
      throw unsupportedAnthropicToolOutputFileMediaType(mediaType);
    }

    if (hasAnthropicReference) {
      final fileId = reference!.requireProvider(
        'anthropic',
        context: 'Anthropic tool output file part',
      );
      return {
        'type': isImage ? 'image' : 'document',
        'source': {
          'type': 'file',
          'file_id': fileId,
        },
      };
    }

    final uri = data.uri;
    if (uri != null) {
      return {
        'type': isImage ? 'image' : 'document',
        'source': {
          'type': 'url',
          'url': uri.toString(),
        },
        if (!isImage && filename != null) 'title': filename,
      };
    }

    final bytes = data.bytes;
    if (bytes != null) {
      return {
        'type': isImage ? 'image' : 'document',
        'source': isImage
            ? {
                'type': 'base64',
                'media_type': normalizeImageMediaType(mediaType),
                'data': base64Encode(bytes),
              }
            : {
                'type': 'base64',
                'media_type': normalizeDocumentMediaType(mediaType),
                'data': base64Encode(bytes),
              },
        if (!isImage && filename != null) 'title': filename,
      };
    }

    final text = data.text;
    if (text != null) {
      if (isImage) {
        throw missingAnthropicToolOutputImageData();
      }

      return {
        'type': 'document',
        'source': {
          'type': 'text',
          'media_type': 'text/plain',
          'data': text,
        },
        if (filename != null) 'title': filename,
      };
    }

    throw missingAnthropicToolOutputFileData();
  }

  String normalizeImageMediaType(String mediaType) {
    return mediaType == 'image/*' ? 'image/jpeg' : mediaType;
  }

  String normalizeDocumentMediaType(String mediaType) {
    if (_isTextualDocumentMediaType(mediaType)) {
      return 'text/plain';
    }

    return mediaType;
  }

  bool isImageMediaType(String mediaType) {
    return mediaType == 'image/*' || mediaType.startsWith('image/');
  }

  bool isDocumentToolOutputMediaType(String mediaType) {
    return mediaType == 'application/pdf' ||
        mediaType == 'text/plain' ||
        mediaType.startsWith('text/') ||
        mediaType == 'application/json' ||
        mediaType.endsWith('+json') ||
        mediaType == 'application/xml' ||
        mediaType.endsWith('+xml');
  }

  bool _isTextualDocumentMediaType(String mediaType) {
    return mediaType == 'text/plain' ||
        mediaType.startsWith('text/') ||
        mediaType == 'application/json' ||
        mediaType.endsWith('+json') ||
        mediaType == 'application/xml' ||
        mediaType.endsWith('+xml');
  }

  bool _isHttpUri(Uri uri) {
    return uri.scheme == 'http' || uri.scheme == 'https';
  }
}
