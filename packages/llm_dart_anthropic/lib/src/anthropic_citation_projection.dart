import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_metadata_support.dart';

Iterable<SourceReference> projectAnthropicCitationSources(
  Object? citations,
) sync* {
  if (citations is! List) {
    return;
  }

  for (final rawCitation in citations) {
    final source = projectAnthropicCitationSource(_asObjectMap(rawCitation));
    if (source != null) {
      yield source;
    }
  }
}

SourceReference? projectAnthropicCitationSource(
  Map<String, Object?>? citation,
) {
  if (citation == null) {
    return null;
  }

  final type = _asString(citation['type']);
  if (type == 'web_search_result_location') {
    final url = _asString(citation['url']);
    if (url == null) {
      return null;
    }

    return SourceReference(
      kind: SourceReferenceKind.url,
      sourceId: url,
      uri: Uri.tryParse(url),
      title: _asString(citation['title']),
      providerMetadata: anthropicProviderMetadata({
        'citationType': type,
        'citedText': _asString(citation['cited_text']),
        'encryptedIndex': _asString(citation['encrypted_index']),
      }),
    );
  }

  if (type == 'page_location' || type == 'char_location') {
    final documentIndex = _asInt(citation['document_index']);
    return SourceReference(
      kind: SourceReferenceKind.document,
      sourceId: 'document-${documentIndex ?? 0}',
      title: _asString(citation['document_title']),
      providerMetadata: anthropicProviderMetadata({
        'citationType': type,
        'citedText': _asString(citation['cited_text']),
        'documentIndex': documentIndex,
        'startPageNumber': _asInt(citation['start_page_number']),
        'endPageNumber': _asInt(citation['end_page_number']),
        'startCharIndex': _asInt(citation['start_char_index']),
        'endCharIndex': _asInt(citation['end_char_index']),
      }),
    );
  }

  return null;
}

Map<String, Object?>? _asObjectMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return Map<String, Object?>.from(value);
  }

  return null;
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
