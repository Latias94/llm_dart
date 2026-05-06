import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

ProviderMetadata? googleProviderMetadata(Map<String, Object?> values) {
  return ProviderMetadata.forNamespace('google', values);
}

ProviderMetadata? mergeProviderMetadata(
  ProviderMetadata? left,
  ProviderMetadata? right,
) {
  return ProviderMetadata.mergeNullable(left, right);
}

UsageStats? decodeGoogleUsage(Map<String, Object?>? usage) {
  if (usage == null) {
    return null;
  }

  final inputTokens = asInt(usage['promptTokenCount']);
  final textOutputTokens = asInt(usage['candidatesTokenCount']) ?? 0;
  final reasoningTokens = asInt(usage['thoughtsTokenCount']) ?? 0;
  final totalTokens = asInt(usage['totalTokenCount']) ??
      (inputTokens ?? 0) + textOutputTokens + reasoningTokens;

  return UsageStats(
    inputTokens: inputTokens,
    outputTokens: textOutputTokens + reasoningTokens,
    totalTokens: totalTokens,
    reasoningTokens: reasoningTokens == 0 ? null : reasoningTokens,
  );
}

FinishReason mapGoogleFinishReason(
  String? rawReason, {
  required bool hasClientToolCalls,
}) {
  switch (rawReason) {
    case 'STOP':
      return hasClientToolCalls ? FinishReason.toolCalls : FinishReason.stop;
    case 'MAX_TOKENS':
      return FinishReason.maxTokens;
    case 'IMAGE_SAFETY':
    case 'RECITATION':
    case 'SAFETY':
    case 'BLOCKLIST':
    case 'PROHIBITED_CONTENT':
    case 'SPII':
      return FinishReason.contentFilter;
    case 'MALFORMED_FUNCTION_CALL':
      return FinishReason.error;
    case 'FINISH_REASON_UNSPECIFIED':
    case 'OTHER':
    default:
      return FinishReason.other;
  }
}

Object? normalizeJsonValue(Object? value) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }

  if (value is Map<String, Object?>) {
    return value.map(
      (key, nestedValue) => MapEntry(key, normalizeJsonValue(nestedValue)),
    );
  }

  if (value is Map) {
    final normalized = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw UnsupportedError(
          'Expected a string key in a Google JSON payload.',
        );
      }

      normalized[entry.key as String] = normalizeJsonValue(entry.value);
    }
    return normalized;
  }

  if (value is List) {
    return [
      for (final item in value) normalizeJsonValue(item),
    ];
  }

  throw UnsupportedError(
    'Expected a JSON-safe Google payload but received ${value.runtimeType}.',
  );
}

List<SourceReference> extractGroundingSources(
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
      final uri = asString(web['uri']);
      if (uri != null) {
        sources.add(
          SourceReference(
            kind: SourceReferenceKind.url,
            sourceId: uri,
            uri: Uri.tryParse(uri),
            title: asString(web['title']),
            providerMetadata: googleProviderMetadata({
              'chunkType': 'web',
            }),
          ),
        );
      }
      continue;
    }

    if (image != null) {
      final sourceUri = asString(image['sourceUri']);
      if (sourceUri != null) {
        sources.add(
          SourceReference(
            kind: SourceReferenceKind.url,
            sourceId: sourceUri,
            uri: Uri.tryParse(sourceUri),
            title: asString(image['title']),
            providerMetadata: googleProviderMetadata({
              'chunkType': 'image',
              'imageUri': asString(image['imageUri']),
              'domain': asString(image['domain']),
            }),
          ),
        );
      }
      continue;
    }

    if (retrievedContext != null) {
      final uri = asString(retrievedContext['uri']);
      final fileSearchStore = asString(retrievedContext['fileSearchStore']);
      if (uri != null &&
          (uri.startsWith('http://') || uri.startsWith('https://'))) {
        sources.add(
          SourceReference(
            kind: SourceReferenceKind.url,
            sourceId: uri,
            uri: Uri.tryParse(uri),
            title: asString(retrievedContext['title']),
            providerMetadata: googleProviderMetadata({
              'chunkType': 'retrievedContext',
              'text': asString(retrievedContext['text']),
            }),
          ),
        );
        continue;
      }

      if (uri != null || fileSearchStore != null) {
        final sourceId = uri ?? fileSearchStore!;
        final segments = sourceId.split('/');
        final filename = segments.isEmpty ? null : segments.last;
        sources.add(
          SourceReference(
            kind: SourceReferenceKind.document,
            sourceId: sourceId,
            title: asString(retrievedContext['title']) ?? 'Unknown Document',
            filename: filename,
            mediaType: inferDocumentMediaType(filename),
            providerMetadata: googleProviderMetadata({
              'chunkType': 'retrievedContext',
              'uri': uri,
              'fileSearchStore': fileSearchStore,
              'text': asString(retrievedContext['text']),
            }),
          ),
        );
      }
      continue;
    }

    if (maps != null) {
      final uri = asString(maps['uri']);
      if (uri != null) {
        sources.add(
          SourceReference(
            kind: SourceReferenceKind.url,
            sourceId: uri,
            uri: Uri.tryParse(uri),
            title: asString(maps['title']),
            providerMetadata: googleProviderMetadata({
              'chunkType': 'maps',
              'text': asString(maps['text']),
              'placeId': asString(maps['placeId']),
            }),
          ),
        );
      }
    }
  }

  return sources;
}

String inferDocumentMediaType(String? filename) {
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

bool isGemini3Model(String modelId) {
  return modelId.toLowerCase().contains('gemini-3');
}

Map<String, Object?>? asMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return Map<String, Object?>.from(value);
  }

  return null;
}

List<Object?> asList(Object? value) {
  if (value is List<Object?>) {
    return value;
  }

  if (value is List) {
    return List<Object?>.from(value);
  }

  return const [];
}

String? asString(Object? value) {
  return value is String ? value : null;
}

int? asInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return null;
}

List<int>? decodeBase64(String? value) {
  if (value == null) {
    return null;
  }

  return base64Decode(value);
}
