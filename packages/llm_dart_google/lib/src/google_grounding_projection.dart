import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_shared.dart';

List<SourceReference> projectGoogleGroundingSources(
  Map<String, Object?>? groundingMetadata,
) {
  if (groundingMetadata == null) {
    return const [];
  }

  final sources = <SourceReference>[];
  for (final rawChunk in asList(groundingMetadata['groundingChunks'])) {
    final chunk = asMap(rawChunk);
    if (chunk == null) {
      continue;
    }

    final web = asMap(chunk['web']);
    final image = asMap(chunk['image']);
    final retrievedContext = asMap(chunk['retrievedContext']);
    final maps = asMap(chunk['maps']);

    if (web != null) {
      if (_projectGoogleWebGroundingSource(web) case final source?) {
        sources.add(source);
      }
      continue;
    }

    if (image != null) {
      if (_projectGoogleImageGroundingSource(image) case final source?) {
        sources.add(source);
      }
      continue;
    }

    if (retrievedContext != null) {
      if (_projectGoogleRetrievedContextSource(retrievedContext)
          case final source?) {
        sources.add(source);
      }
      continue;
    }

    if (maps != null) {
      if (_projectGoogleMapsGroundingSource(maps) case final source?) {
        sources.add(source);
      }
    }
  }

  return sources;
}

Iterable<SourceContentPart> projectGoogleGroundingContentParts(
  Map<String, Object?>? groundingMetadata,
) sync* {
  for (final source in projectGoogleGroundingSources(groundingMetadata)) {
    yield SourceContentPart(source);
  }
}

Iterable<SourceEvent> emitGoogleGroundingSourceEvents(
  Map<String, Object?>? groundingMetadata, {
  required Set<String> emittedSourceKeys,
}) sync* {
  for (final source in projectGoogleGroundingSources(groundingMetadata)) {
    if (emittedSourceKeys.add(googleGroundingSourceKey(source))) {
      yield SourceEvent(source);
    }
  }
}

String googleGroundingSourceKey(SourceReference source) {
  return '${source.kind}:${source.sourceId}';
}

SourceReference? _projectGoogleWebGroundingSource(
  Map<String, Object?> web,
) {
  final uri = asString(web['uri']);
  if (uri == null) {
    return null;
  }

  return SourceReference(
    kind: SourceReferenceKind.url,
    sourceId: uri,
    uri: Uri.tryParse(uri),
    title: asString(web['title']),
    providerMetadata: googleProviderMetadata({
      'chunkType': 'web',
    }),
  );
}

SourceReference? _projectGoogleImageGroundingSource(
  Map<String, Object?> image,
) {
  final sourceUri = asString(image['sourceUri']);
  if (sourceUri == null) {
    return null;
  }

  return SourceReference(
    kind: SourceReferenceKind.url,
    sourceId: sourceUri,
    uri: Uri.tryParse(sourceUri),
    title: asString(image['title']),
    providerMetadata: googleProviderMetadata({
      'chunkType': 'image',
      'imageUri': asString(image['imageUri']),
      'domain': asString(image['domain']),
    }),
  );
}

SourceReference? _projectGoogleRetrievedContextSource(
  Map<String, Object?> retrievedContext,
) {
  final uri = asString(retrievedContext['uri']);
  final fileSearchStore = asString(retrievedContext['fileSearchStore']);
  if (uri != null &&
      (uri.startsWith('http://') || uri.startsWith('https://'))) {
    return SourceReference(
      kind: SourceReferenceKind.url,
      sourceId: uri,
      uri: Uri.tryParse(uri),
      title: asString(retrievedContext['title']),
      providerMetadata: googleProviderMetadata({
        'chunkType': 'retrievedContext',
        'text': asString(retrievedContext['text']),
      }),
    );
  }

  if (uri == null && fileSearchStore == null) {
    return null;
  }

  final sourceId = uri ?? fileSearchStore!;
  final segments = sourceId.split('/');
  final filename = segments.isEmpty ? null : segments.last;
  return SourceReference(
    kind: SourceReferenceKind.document,
    sourceId: sourceId,
    title: asString(retrievedContext['title']) ?? 'Unknown Document',
    filename: filename,
    mediaType: _inferGoogleDocumentMediaType(filename),
    providerMetadata: googleProviderMetadata({
      'chunkType': 'retrievedContext',
      'uri': uri,
      'fileSearchStore': fileSearchStore,
      'text': asString(retrievedContext['text']),
    }),
  );
}

SourceReference? _projectGoogleMapsGroundingSource(
  Map<String, Object?> maps,
) {
  final uri = asString(maps['uri']);
  if (uri == null) {
    return null;
  }

  return SourceReference(
    kind: SourceReferenceKind.url,
    sourceId: uri,
    uri: Uri.tryParse(uri),
    title: asString(maps['title']),
    providerMetadata: googleProviderMetadata({
      'chunkType': 'maps',
      'text': asString(maps['text']),
      'placeId': asString(maps['placeId']),
    }),
  );
}

String _inferGoogleDocumentMediaType(String? filename) {
  if (filename == null) {
    return 'application/octet-stream';
  }

  final lower = filename.toLowerCase();
  if (lower.endsWith('.pdf')) {
    return 'application/pdf';
  }

  if (lower.endsWith('.txt')) {
    return 'text/plain';
  }

  if (lower.endsWith('.md') || lower.endsWith('.markdown')) {
    return 'text/markdown';
  }

  if (lower.endsWith('.docx')) {
    return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
  }

  if (lower.endsWith('.doc')) {
    return 'application/msword';
  }

  return 'application/octet-stream';
}
