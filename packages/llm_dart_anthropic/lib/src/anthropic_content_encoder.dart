part of 'anthropic_messages_codec.dart';

Map<String, Object?> _encodeAnthropicUserPart(PromptPart part) {
  if (part is TextPromptPart) {
    return _encodeAnthropicTextContent(
      part,
      path: 'user.text',
    );
  }

  if (part is ImagePromptPart) {
    return _applyAnthropicCacheControl(
      {
        'type': 'image',
        'source': _encodeAnthropicBinarySource(
          mediaType: _normalizeAnthropicImageMediaType(part.mediaType),
          data: part.data,
          path: 'user.image',
        ),
      },
      providerOptions: part.providerOptions,
      path: 'user.image',
    );
  }

  if (part is FilePromptPart) {
    return _encodeAnthropicFilePromptPart(part);
  }

  throw UnsupportedError(
    'Anthropic user prompt part ${part.runtimeType} is not supported yet.',
  );
}

Map<String, Object?> _encodeAnthropicFilePromptPart(FilePromptPart part) {
  if (part.mediaType == 'application/pdf') {
    return _applyAnthropicCacheControl(
      {
        'type': 'document',
        'source': _encodeAnthropicBinarySource(
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
    return _applyAnthropicCacheControl(
      {
        'type': 'document',
        'source': _encodeAnthropicTextDocumentSource(part),
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

Map<String, Object?> _encodeAnthropicBinarySource({
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

Map<String, Object?> _encodeAnthropicTextDocumentSource(
  FilePromptPart part,
) {
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

Map<String, Object?> _encodeAnthropicTextContent(
  TextPromptPart part, {
  required String path,
  String? text,
}) {
  final cacheControl = _extractAnthropicPromptPartCacheControl(
    part.providerOptions,
    path: '$path.providerOptions',
  );

  return {
    'type': 'text',
    'text': text ?? part.text,
    if (cacheControl != null) 'cache_control': cacheControl,
  };
}

Map<String, Object?> _applyAnthropicCacheControl(
  Map<String, Object?> block, {
  required ProviderPromptPartOptions? providerOptions,
  required String path,
}) {
  final cacheControl = _extractAnthropicPromptPartCacheControl(
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

Object? _encodeAnthropicToolOutput(
  ToolOutput output, {
  required String path,
}) {
  if (output is ExecutionDeniedToolOutput) {
    return output.reason ?? 'Tool execution denied';
  }

  if (output is ContentToolOutput) {
    return _encodeAnthropicContentToolOutput(
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

List<Object?> _encodeAnthropicContentToolOutput(
  List<ToolOutputContentPart> parts, {
  required String path,
}) {
  return [
    for (var index = 0; index < parts.length; index++)
      _encodeAnthropicContentToolOutputPart(
        parts[index],
        path: '$path.parts[$index]',
      ),
  ];
}

Object _encodeAnthropicContentToolOutputPart(
  ToolOutputContentPart part, {
  required String path,
}) {
  return switch (part) {
    TextToolOutputContentPart(
      :final text,
      :final providerOptions,
    ) =>
      _encodeAnthropicToolOutputTextBlock(
        text,
        providerOptions: providerOptions,
        path: path,
      ),
    JsonToolOutputContentPart(
      :final value,
      :final providerOptions,
    ) =>
      _encodeAnthropicToolOutputTextBlock(
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
      _encodeAnthropicToolOutputFileBlock(
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
      _encodeAnthropicToolOutputTextBlock(
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

Map<String, Object?> _encodeAnthropicToolOutputTextBlock(
  String text, {
  required ProviderPromptPartOptions? providerOptions,
  required String path,
}) {
  return _applyAnthropicCacheControl(
    {
      'type': 'text',
      'text': text,
    },
    providerOptions: providerOptions,
    path: path,
  );
}

Map<String, Object?> _encodeAnthropicToolOutputFileBlock({
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
      _isAnthropicDocumentToolOutputMediaType(mediaType);

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
    return _applyAnthropicCacheControl(
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
    return _applyAnthropicCacheControl(
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
    return _applyAnthropicCacheControl(
      {
        'type': isImage ? 'image' : 'document',
        'source': isImage
            ? {
                'type': 'base64',
                'media_type': _normalizeAnthropicImageMediaType(mediaType),
                'data': base64Encode(bytes),
              }
            : {
                'type': 'base64',
                'media_type': _normalizeAnthropicDocumentMediaType(mediaType),
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

    return _applyAnthropicCacheControl(
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

String _normalizeAnthropicImageMediaType(String mediaType) {
  return mediaType == 'image/*' ? 'image/jpeg' : mediaType;
}

bool _isAnthropicDocumentToolOutputMediaType(String mediaType) {
  return mediaType == 'application/pdf' ||
      mediaType == 'text/plain' ||
      mediaType.startsWith('text/') ||
      mediaType == 'application/json' ||
      mediaType.endsWith('+json') ||
      mediaType == 'application/xml' ||
      mediaType.endsWith('+xml');
}

String _normalizeAnthropicDocumentMediaType(String mediaType) {
  if (_isAnthropicTextualDocumentMediaType(mediaType)) {
    return 'text/plain';
  }

  return mediaType;
}

bool _isAnthropicTextualDocumentMediaType(String mediaType) {
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

Map<String, Object?>? _extractAnthropicPromptPartCacheControl(
  ProviderPromptPartOptions? providerOptions, {
  required String path,
}) {
  final options = resolveProviderPromptPartOptions<AnthropicPromptPartOptions>(
    providerOptions,
    parameterName: path,
    expectedTypeName: 'AnthropicPromptPartOptions',
    usageContext: 'Anthropic prompt parts',
  );
  final cacheControl = options?.cacheControl;
  if (cacheControl == null) {
    return null;
  }

  return _normalizeAnthropicCacheControl(
    cacheControl.toJson(),
    path: '$path.cacheControl',
  );
}

Map<String, Object?> _normalizeAnthropicCacheControl(
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
