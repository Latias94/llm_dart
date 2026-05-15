import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_options.dart';

final class AnthropicContentEncoder {
  const AnthropicContentEncoder();

  Map<String, Object?> encodeUserPart(PromptPart part) {
    if (part is TextPromptPart) {
      return encodeTextContent(
        part,
        path: 'user.text',
      );
    }

    if (part is ImagePromptPart) {
      return applyCacheControl(
        {
          'type': 'image',
          'source': _encodeBinarySource(
            mediaType: _normalizeImageMediaType(part.mediaType),
            data: part.data,
            path: 'user.image',
          ),
        },
        providerOptions: part.providerOptions,
        path: 'user.image',
      );
    }

    if (part is FilePromptPart) {
      return _encodeFilePromptPart(part);
    }

    throw UnsupportedError(
      'Anthropic user prompt part ${part.runtimeType} is not supported yet.',
    );
  }

  Map<String, Object?> encodeTextContent(
    TextPromptPart part, {
    required String path,
    String? text,
  }) {
    final cacheControl = _extractPromptPartCacheControl(
      part.providerOptions,
      path: '$path.providerOptions',
    );

    return {
      'type': 'text',
      'text': text ?? part.text,
      if (cacheControl != null) 'cache_control': cacheControl,
    };
  }

  Map<String, Object?> applyCacheControl(
    Map<String, Object?> block, {
    required ProviderPromptPartOptions? providerOptions,
    required String path,
  }) {
    final cacheControl = _extractPromptPartCacheControl(
      providerOptions,
      path: '$path.providerOptions',
    );
    if (cacheControl == null) {
      return block;
    }

    return {
      ...block,
      'cache_control': cacheControl,
    };
  }

  Object? encodeToolOutput(
    ToolOutput output, {
    required String path,
  }) {
    if (output is ExecutionDeniedToolOutput) {
      return output.reason ?? 'Tool execution denied';
    }

    if (output is ContentToolOutput) {
      return _encodeContentToolOutput(
        output.parts,
        path: path,
      );
    }

    final value = output.value;
    if (value == null) {
      return 'null';
    }

    if (value is String) {
      return value;
    }

    return jsonEncode(
      normalizeJsonValue(value, path: path),
    );
  }

  Map<String, Object?> _encodeFilePromptPart(FilePromptPart part) {
    if (part.mediaType == 'application/pdf') {
      return applyCacheControl(
        {
          'type': 'document',
          'source': _encodeBinarySource(
            mediaType: part.mediaType,
            data: part.data,
            path: 'user.document',
          ),
          if (part.filename != null) 'title': part.filename,
        },
        providerOptions: part.providerOptions,
        path: 'user.document',
      );
    }

    if (part.mediaType == 'text/plain') {
      return applyCacheControl(
        {
          'type': 'document',
          'source': _encodeTextDocumentSource(part),
          if (part.filename != null) 'title': part.filename,
        },
        providerOptions: part.providerOptions,
        path: 'user.document',
      );
    }

    throw UnsupportedError(
      'Anthropic document media type ${part.mediaType} is not supported yet.',
    );
  }

  Map<String, Object?> _encodeBinarySource({
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

    throw UnsupportedError(
      'Anthropic $path requires in-memory bytes or an HTTP/HTTPS URI.',
    );
  }

  Map<String, Object?> _encodeTextDocumentSource(FilePromptPart part) {
    final data = part.data;

    if (data.providerReference case final reference?) {
      return {
        'type': 'file',
        'file_id': reference.requireProvider(
          'anthropic',
          context: 'Anthropic user.document',
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

    throw UnsupportedError(
      'Anthropic text documents require UTF-8 bytes or an HTTP/HTTPS URI.',
    );
  }

  List<Object?> _encodeContentToolOutput(
    List<ToolOutputContentPart> parts, {
    required String path,
  }) {
    return [
      for (var index = 0; index < parts.length; index++)
        _encodeContentToolOutputPart(
          parts[index],
          path: '$path.parts[$index]',
        ),
    ];
  }

  Object _encodeContentToolOutputPart(
    ToolOutputContentPart part, {
    required String path,
  }) {
    return switch (part) {
      TextToolOutputContentPart(
        :final text,
        :final providerOptions,
      ) =>
        _encodeToolOutputTextBlock(
          text,
          providerOptions: providerOptions,
          path: path,
        ),
      JsonToolOutputContentPart(
        :final value,
        :final providerOptions,
      ) =>
        _encodeToolOutputTextBlock(
          jsonEncode(normalizeJsonValue(value, path: '$path.value')),
          providerOptions: providerOptions,
          path: path,
        ),
      FileToolOutputContentPart(
        :final mediaType,
        :final filename,
        :final data,
        :final providerOptions,
      ) =>
        _encodeToolOutputFileBlock(
          mediaType: mediaType,
          filename: filename,
          data: data,
          providerOptions: providerOptions,
          path: path,
        ),
      CustomToolOutputContentPart(
        :final kind,
        :final data,
        :final providerOptions,
      ) =>
        _encodeToolOutputTextBlock(
          jsonEncode(
            normalizeJsonValue(
              {
                'type': 'custom',
                'kind': kind,
                if (data != null) 'data': data,
              },
              path: '$path.data',
            ),
          ),
          providerOptions: providerOptions,
          path: path,
        ),
    };
  }

  Map<String, Object?> _encodeToolOutputTextBlock(
    String text, {
    required ProviderPromptPartOptions? providerOptions,
    required String path,
  }) {
    return applyCacheControl(
      {
        'type': 'text',
        'text': text,
      },
      providerOptions: providerOptions,
      path: path,
    );
  }

  Map<String, Object?> _encodeToolOutputFileBlock({
    required String mediaType,
    required String? filename,
    required FileData data,
    required ProviderPromptPartOptions? providerOptions,
    required String path,
  }) {
    final reference = data.providerReference;
    final isImage = mediaType == 'image/*' || mediaType.startsWith('image/');
    final hasAnthropicReference =
        reference?.containsProvider('anthropic') == true;
    final isDocument = isImage ||
        hasAnthropicReference ||
        _isDocumentToolOutputMediaType(mediaType);

    if (!isDocument) {
      throw UnsupportedError(
        'Anthropic tool output file part media type $mediaType is not supported yet.',
      );
    }

    if (hasAnthropicReference) {
      final fileId = reference!.requireProvider(
        'anthropic',
        context: 'Anthropic tool output file part',
      );
      return applyCacheControl(
        {
          'type': isImage ? 'image' : 'document',
          'source': {
            'type': 'file',
            'file_id': fileId,
          },
        },
        providerOptions: providerOptions,
        path: path,
      );
    }

    final uri = data.uri;
    if (uri != null) {
      return applyCacheControl(
        {
          'type': isImage ? 'image' : 'document',
          'source': {
            'type': 'url',
            'url': uri.toString(),
          },
          if (!isImage && filename != null) 'title': filename,
        },
        providerOptions: providerOptions,
        path: path,
      );
    }

    final bytes = data.bytes;
    if (bytes != null) {
      return applyCacheControl(
        {
          'type': isImage ? 'image' : 'document',
          'source': isImage
              ? {
                  'type': 'base64',
                  'media_type': _normalizeImageMediaType(mediaType),
                  'data': base64Encode(bytes),
                }
              : {
                  'type': 'base64',
                  'media_type': _normalizeDocumentMediaType(mediaType),
                  'data': base64Encode(bytes),
                },
          if (!isImage && filename != null) 'title': filename,
        },
        providerOptions: providerOptions,
        path: path,
      );
    }

    final text = data.text;
    if (text != null) {
      if (isImage) {
        throw UnsupportedError(
          'Anthropic tool output image parts require in-memory bytes, a URI, or an Anthropic provider reference.',
        );
      }

      return applyCacheControl(
        {
          'type': 'document',
          'source': {
            'type': 'text',
            'media_type': 'text/plain',
            'data': text,
          },
          if (filename != null) 'title': filename,
        },
        providerOptions: providerOptions,
        path: path,
      );
    }

    throw UnsupportedError(
      'Anthropic tool output file part requires in-memory bytes, text, a URI, or an Anthropic provider reference.',
    );
  }

  Map<String, Object?>? _extractPromptPartCacheControl(
    ProviderPromptPartOptions? providerOptions, {
    required String path,
  }) {
    final options =
        resolveProviderPromptPartOptions<AnthropicPromptPartOptions>(
      providerOptions,
      parameterName: path,
      expectedTypeName: 'AnthropicPromptPartOptions',
      usageContext: 'Anthropic prompt parts',
    );
    final cacheControl = options?.cacheControl;
    if (cacheControl == null) {
      return null;
    }

    return _normalizeCacheControl(
      cacheControl.toJson(),
      path: '$path.cacheControl',
    );
  }

  Map<String, Object?> _normalizeCacheControl(
    Object? value, {
    required String path,
  }) {
    final normalized = normalizeJsonValue(
      value,
      path: path,
    );
    if (normalized is! Map<String, Object?>) {
      throw UnsupportedError('Expected a cache control object at $path.');
    }

    final type = normalized['type'];
    if (type is! String || type.isEmpty) {
      throw UnsupportedError('Expected a cache control type at $path.');
    }

    final ttl = normalized['ttl'];
    if (ttl != null && (ttl is! String || ttl.isEmpty)) {
      throw UnsupportedError(
        'Expected a non-empty cache control ttl string at $path.',
      );
    }

    return {
      'type': type,
      if (ttl != null) 'ttl': ttl,
    };
  }

  String _normalizeImageMediaType(String mediaType) {
    return mediaType == 'image/*' ? 'image/jpeg' : mediaType;
  }

  bool _isDocumentToolOutputMediaType(String mediaType) {
    return mediaType == 'application/pdf' ||
        mediaType == 'text/plain' ||
        mediaType.startsWith('text/') ||
        mediaType == 'application/json' ||
        mediaType.endsWith('+json') ||
        mediaType == 'application/xml' ||
        mediaType.endsWith('+xml');
  }

  String _normalizeDocumentMediaType(String mediaType) {
    if (_isTextualDocumentMediaType(mediaType)) {
      return 'text/plain';
    }

    return mediaType;
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
