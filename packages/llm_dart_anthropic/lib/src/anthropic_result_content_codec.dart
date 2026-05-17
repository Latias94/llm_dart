import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_result_util.dart';

Iterable<ContentPart> decodeAnthropicResultTextParts(
  Map<String, Object?> part,
) sync* {
  yield TextContentPart(anthropicResultAsString(part['text']) ?? '');

  for (final rawCitation in anthropicResultAsList(part['citations'])) {
    final citation = anthropicResultAsMap(rawCitation);
    final source = decodeAnthropicResultCitationSource(citation);
    if (source != null) {
      yield SourceContentPart(source);
    }
  }
}

ReasoningContentPart decodeAnthropicResultThinkingPart(
  Map<String, Object?> part,
) {
  return ReasoningContentPart(
    anthropicResultAsString(part['thinking']) ?? '',
    providerMetadata: anthropicResultProviderMetadata({
      'signature': anthropicResultAsString(part['signature']),
    }),
  );
}

ReasoningContentPart decodeAnthropicResultRedactedThinkingPart(
  Map<String, Object?> part,
) {
  return ReasoningContentPart(
    '',
    providerMetadata: anthropicResultProviderMetadata({
      'redactedData': anthropicResultAsString(part['data']),
    }),
  );
}

TextContentPart decodeAnthropicResultCompactionPart(
  Map<String, Object?> part,
) {
  return TextContentPart(
    anthropicResultAsString(part['content']) ?? '',
    providerMetadata: anthropicResultProviderMetadata({
      'type': 'compaction',
    }),
  );
}

CustomContentPart? decodeAnthropicResultCustomPart(
  Map<String, Object?> part,
) {
  final type = anthropicResultAsString(part['type']);
  if (type == null) {
    return null;
  }

  return CustomContentPart(
    kind: 'anthropic.$type',
    data: part,
  );
}

SourceReference? decodeAnthropicResultCitationSource(
  Map<String, Object?>? citation,
) {
  if (citation == null) {
    return null;
  }

  final type = anthropicResultAsString(citation['type']);
  if (type == 'web_search_result_location') {
    final url = anthropicResultAsString(citation['url']);
    if (url == null) {
      return null;
    }

    return SourceReference(
      kind: SourceReferenceKind.url,
      sourceId: url,
      uri: Uri.tryParse(url),
      title: anthropicResultAsString(citation['title']),
      providerMetadata: anthropicResultProviderMetadata({
        'citationType': type,
        'citedText': anthropicResultAsString(citation['cited_text']),
        'encryptedIndex': anthropicResultAsString(citation['encrypted_index']),
      }),
    );
  }

  if (type == 'page_location' || type == 'char_location') {
    final documentIndex = anthropicResultAsInt(citation['document_index']);
    return SourceReference(
      kind: SourceReferenceKind.document,
      sourceId: 'document-${documentIndex ?? 0}',
      title: anthropicResultAsString(citation['document_title']),
      providerMetadata: anthropicResultProviderMetadata({
        'citationType': type,
        'citedText': anthropicResultAsString(citation['cited_text']),
        'documentIndex': documentIndex,
        'startPageNumber': anthropicResultAsInt(citation['start_page_number']),
        'endPageNumber': anthropicResultAsInt(citation['end_page_number']),
        'startCharIndex': anthropicResultAsInt(citation['start_char_index']),
        'endCharIndex': anthropicResultAsInt(citation['end_char_index']),
      }),
    );
  }

  return null;
}
