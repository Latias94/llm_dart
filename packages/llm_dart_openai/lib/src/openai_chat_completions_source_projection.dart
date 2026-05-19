import 'package:llm_dart_provider/llm_dart_provider.dart';

List<SourceContentPart> decodeOpenAIChatCompletionsTopLevelSources(
  Map<String, Object?> response, {
  required ProviderMetadata? Function(Map<String, Object?> values)
      providerMetadata,
}) {
  final citations = _asList(response['citations']);
  if (citations.isEmpty) {
    return const [];
  }

  final sources = <SourceContentPart>[];
  for (var index = 0; index < citations.length; index++) {
    final rawCitation = citations[index];
    final url = _asString(rawCitation);
    if (url == null || url.isEmpty) {
      continue;
    }

    sources.add(
      SourceContentPart(
        SourceReference(
          kind: SourceReferenceKind.url,
          sourceId: url,
          uri: Uri.tryParse(url),
          title: url,
          providerMetadata: providerMetadata({
            'citationIndex': index,
          }),
        ),
      ),
    );
  }

  return sources;
}

Iterable<SourceEvent> decodeOpenAIChatCompletionsChunkSources(
  Map<String, Object?> chunk, {
  required String? responseId,
  required Set<String> emittedSourceIds,
  required ProviderMetadata? Function(Map<String, Object?> values)
      providerMetadata,
}) sync* {
  final citations = _asList(chunk['citations']);
  if (citations.isEmpty) {
    return;
  }

  for (var index = 0; index < citations.length; index++) {
    final rawCitation = citations[index];
    final url = _asString(rawCitation);
    if (url == null || url.isEmpty || !emittedSourceIds.add(url)) {
      continue;
    }

    yield SourceEvent(
      SourceReference(
        kind: SourceReferenceKind.url,
        sourceId: url,
        uri: Uri.tryParse(url),
        title: url,
        providerMetadata: providerMetadata({
          'responseId': responseId,
          'citationIndex': index,
        }),
      ),
    );
  }
}

List<Object?> _asList(Object? value) {
  if (value is List<Object?>) {
    return value;
  }

  if (value is List) {
    return List<Object?>.from(value);
  }

  return const [];
}

String? _asString(Object? value) => value is String ? value : null;
