import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

SourceReference? decodeOpenAIResponsesSourceAnnotation(
  Map<String, Object?>? annotation,
) {
  if (annotation == null) {
    return null;
  }

  final type = _asString(annotation['type']);
  if (type == 'url_citation') {
    final url = _asString(annotation['url']);
    if (url == null) {
      return null;
    }

    return SourceReference(
      kind: SourceReferenceKind.url,
      sourceId: url,
      uri: Uri.tryParse(url),
      title: _asString(annotation['title']),
      providerMetadata: _providerMetadata({
        'annotationType': type,
        'startIndex': _asInt(annotation['start_index']),
        'endIndex': _asInt(annotation['end_index']),
      }),
    );
  }

  if (type == 'file_citation') {
    final sourceId =
        _asString(annotation['file_id']) ?? _asString(annotation['filename']);
    if (sourceId == null) {
      return null;
    }

    return SourceReference(
      kind: SourceReferenceKind.document,
      sourceId: sourceId,
      title: _asString(annotation['filename']),
      filename: _asString(annotation['filename']),
      mediaType: 'text/plain',
      providerMetadata: _providerMetadata({
        'annotationType': type,
        'fileId': _asString(annotation['file_id']),
        'index': _asInt(annotation['index']),
      }),
    );
  }

  if (type == 'container_file_citation') {
    final sourceId =
        _asString(annotation['file_id']) ?? _asString(annotation['filename']);
    if (sourceId == null) {
      return null;
    }

    return SourceReference(
      kind: SourceReferenceKind.document,
      sourceId: sourceId,
      title: _asString(annotation['filename']),
      filename: _asString(annotation['filename']),
      mediaType: 'text/plain',
      providerMetadata: _providerMetadata({
        'annotationType': type,
        'fileId': _asString(annotation['file_id']),
        'containerId': _asString(annotation['container_id']),
      }),
    );
  }

  if (type == 'file_path') {
    final sourceId = _asString(annotation['file_id']);
    if (sourceId == null) {
      return null;
    }

    return SourceReference(
      kind: SourceReferenceKind.document,
      sourceId: sourceId,
      title: sourceId,
      filename: sourceId,
      mediaType: 'application/octet-stream',
      providerMetadata: _providerMetadata({
        'annotationType': type,
        'fileId': sourceId,
        'index': _asInt(annotation['index']),
      }),
    );
  }

  return null;
}

SourceEvent? decodeOpenAIResponsesSourceEvent(
  Map<String, Object?>? annotation, {
  required Set<String> emittedAnnotationKeys,
}) {
  final annotationKey = openAIResponsesAnnotationKey(annotation);
  if (annotationKey == null || !emittedAnnotationKeys.add(annotationKey)) {
    return null;
  }

  final source = decodeOpenAIResponsesSourceAnnotation(annotation);
  if (source == null) {
    return null;
  }

  return SourceEvent(source);
}

String? openAIResponsesAnnotationKey(Map<String, Object?>? annotation) {
  if (annotation == null) {
    return null;
  }

  final type = _asString(annotation['type']);
  if (type == null) {
    return null;
  }

  return switch (type) {
    'url_citation' =>
      'url:${_asString(annotation['url'])}:${_asInt(annotation['start_index'])}:${_asInt(annotation['end_index'])}',
    'file_citation' =>
      'file:${_asString(annotation['file_id'])}:${_asString(annotation['filename'])}:${_asInt(annotation['index'])}',
    'container_file_citation' =>
      'container:${_asString(annotation['container_id'])}:${_asString(annotation['file_id'])}:${_asString(annotation['filename'])}',
    'file_path' =>
      'file_path:${_asString(annotation['file_id'])}:${_asInt(annotation['index'])}',
    _ => jsonEncode(annotation),
  };
}

ProviderMetadata? _providerMetadata(Map<String, Object?> values) {
  final openaiValues = <String, Object?>{};
  for (final entry in values.entries) {
    if (entry.value != null) {
      openaiValues[entry.key] = entry.value;
    }
  }

  if (openaiValues.isEmpty) {
    return null;
  }

  return ProviderMetadata.forNamespace('openai', openaiValues);
}

String? _asString(Object? value) {
  return value is String ? value : null;
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return null;
}
