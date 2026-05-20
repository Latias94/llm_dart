import 'package:llm_dart_provider/llm_dart_provider.dart';

ProviderMetadata? openAIResponsesResponseMetadata(
  Map<String, Object?> response, {
  List<Object?> logprobs = const [],
}) {
  return openAIResponsesProviderMetadata({
    'status': _asString(response['status']),
    'serviceTier': _asString(response['service_tier']),
    if (logprobs.isNotEmpty) 'logprobs': List<Object?>.unmodifiable(logprobs),
  });
}

ProviderMetadata? openAIResponsesItemMetadata(
  Map<String, Object?> item, {
  Map<String, Object?> extra = const {},
}) {
  return openAIResponsesProviderMetadata({
    'itemId': _asString(item['id']),
    'itemType': _asString(item['type']),
    'status': _asString(item['status']),
    'phase': _asString(item['phase']),
    ...extra,
  });
}

ProviderMetadata? openAIResponsesStreamItemMetadata({
  required String? responseId,
  required String? serviceTier,
  required Map<String, Object?> chunk,
  required Map<String, Object?>? item,
}) {
  return openAIResponsesProviderMetadata({
    'responseId': responseId,
    'itemId': _asString(chunk['item_id']) ?? _asString(item?['id']),
    'itemType': _asString(item?['type']),
    'phase': _asString(item?['phase']),
    'outputIndex': _asInt(chunk['output_index']),
    'contentIndex': _asInt(chunk['content_index']),
    'summaryIndex': _asInt(chunk['summary_index']),
    'serviceTier': serviceTier,
    'logprobs': _jsonListOrNull(chunk['logprobs']),
  });
}

ProviderMetadata? openAIResponsesStreamTextPartMetadata({
  required String? responseId,
  required String? serviceTier,
  required Map<String, Object?> chunk,
  required Map<String, Object?> part,
}) {
  return openAIResponsesProviderMetadata({
    'responseId': responseId,
    'itemId': _asString(chunk['item_id']),
    'outputIndex': _asInt(chunk['output_index']),
    'contentIndex': _asInt(chunk['content_index']),
    'serviceTier': serviceTier,
    'annotations': _jsonListOrNull(part['annotations']),
    'logprobs': _jsonListOrNull(part['logprobs']),
  });
}

ProviderMetadata? openAIResponsesProviderMetadata(Map<String, Object?> values) {
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

List<Object?>? _jsonListOrNull(Object? value) {
  if (value is List<Object?>) {
    return value;
  }

  if (value is List) {
    return List<Object?>.from(value);
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
