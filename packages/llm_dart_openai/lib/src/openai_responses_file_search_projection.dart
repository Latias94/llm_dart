import 'package:llm_dart_provider/llm_dart_provider.dart';

const openAIResponsesFileSearchToolName = 'file_search';

final class OpenAIResponsesFileSearchProjection {
  final String toolCallId;
  final List<String> queries;
  final List<Map<String, Object?>>? results;
  final ProviderMetadata? providerMetadata;

  const OpenAIResponsesFileSearchProjection({
    required this.toolCallId,
    required this.queries,
    required this.results,
    required this.providerMetadata,
  });

  Map<String, Object?> get output => {
        'queries': queries,
        'results': results,
      };

  ToolCallContent toToolCall() {
    return ToolCallContent(
      toolCallId: toolCallId,
      toolName: openAIResponsesFileSearchToolName,
      input: const <String, Object?>{},
      providerExecuted: true,
    );
  }

  ToolResultContent toToolResult() {
    return ToolResultContent(
      toolCallId: toolCallId,
      toolName: openAIResponsesFileSearchToolName,
      output: output,
    );
  }
}

OpenAIResponsesFileSearchProjection? projectOpenAIResponsesFileSearchCall(
  Map<String, Object?> item, {
  String? responseId,
  String? serviceTier,
  int? outputIndex,
}) {
  final toolCallId = _asString(item['id']);
  if (toolCallId == null) {
    return null;
  }

  final queries = List<String>.unmodifiable([
    for (final query in _asList(item['queries']))
      if (query is String) query,
  ]);
  final results = _projectResults(item['results']);

  return OpenAIResponsesFileSearchProjection(
    toolCallId: toolCallId,
    queries: queries,
    results: results,
    providerMetadata: openAIResponsesFileSearchMetadata(
      item,
      responseId: responseId,
      serviceTier: serviceTier,
      outputIndex: outputIndex,
      queryCount: queries.length,
      resultCount: results?.length,
    ),
  );
}

ProviderMetadata? openAIResponsesFileSearchMetadata(
  Map<String, Object?> item, {
  required String? responseId,
  required String? serviceTier,
  required int? outputIndex,
  required int queryCount,
  required int? resultCount,
}) {
  return _providerMetadata({
    'responseId': responseId,
    'itemId': _asString(item['id']),
    'itemType': _asString(item['type']),
    'status': _asString(item['status']),
    'phase': _asString(item['phase']),
    'outputIndex': outputIndex,
    'serviceTier': serviceTier,
    'queryCount': queryCount,
    'resultCount': resultCount,
  });
}

List<Map<String, Object?>>? _projectResults(Object? value) {
  if (value == null) {
    return null;
  }

  final results = <Map<String, Object?>>[];
  for (final rawResult in _asList(value)) {
    final result = _asMap(rawResult);
    if (result == null) {
      continue;
    }

    results.add({
      'attributes': _asMap(result['attributes']) ?? const <String, Object?>{},
      'fileId': _asString(result['file_id']),
      'filename': _asString(result['filename']),
      'score': result['score'],
      'text': _asString(result['text']),
    });
  }

  return List<Map<String, Object?>>.unmodifiable(results);
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

Map<String, Object?>? _asMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return Map<String, Object?>.from(value);
  }

  return null;
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

String? _asString(Object? value) {
  return value is String ? value : null;
}
