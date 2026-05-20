import 'package:llm_dart_provider/llm_dart_provider.dart';

const openAIResponsesPartialImageCustomKind =
    'openai.image_generation_call.partial_image';
const openAIResponsesPartialImageItemType =
    'image_generation_call.partial_image';

final class OpenAIResponsesCustomOutputProjection {
  final String kind;
  final Object? data;
  final ProviderMetadata? providerMetadata;

  const OpenAIResponsesCustomOutputProjection({
    required this.kind,
    required this.data,
    required this.providerMetadata,
  });

  CustomContentPart toContentPart() {
    return CustomContentPart(
      kind: kind,
      data: data,
      providerMetadata: providerMetadata,
    );
  }

  CustomEvent toEvent() {
    return CustomEvent(
      kind: kind,
      data: data,
      providerMetadata: providerMetadata,
    );
  }
}

OpenAIResponsesCustomOutputProjection? projectOpenAIResponsesCustomOutputItem(
  Map<String, Object?> item, {
  String? itemType,
  ProviderMetadata? providerMetadata,
}) {
  final type = itemType ?? _asString(item['type']);
  final kind = openAIResponsesCustomOutputKind(type);
  if (kind == null) {
    return null;
  }

  return OpenAIResponsesCustomOutputProjection(
    kind: kind,
    data: item,
    providerMetadata: providerMetadata ??
        openAIResponsesCustomOutputItemMetadata(
          item,
          itemType: type,
        ),
  );
}

OpenAIResponsesCustomOutputProjection projectOpenAIResponsesPartialImageChunk({
  required Map<String, Object?> chunk,
  required String? responseId,
  required String? serviceTier,
}) {
  return OpenAIResponsesCustomOutputProjection(
    kind: openAIResponsesPartialImageCustomKind,
    data: {
      'item_id': _asString(chunk['item_id']),
      'output_index': _asInt(chunk['output_index']),
      'partial_image_b64': _asString(chunk['partial_image_b64']),
    },
    providerMetadata: _providerMetadata({
      'responseId': responseId,
      'itemId': _asString(chunk['item_id']),
      'itemType': openAIResponsesPartialImageItemType,
      'outputIndex': _asInt(chunk['output_index']),
      'serviceTier': serviceTier,
    }),
  );
}

String? openAIResponsesCustomOutputKind(String? itemType) {
  if (itemType == null || itemType == 'reasoning') {
    return null;
  }

  return 'openai.$itemType';
}

ProviderMetadata? openAIResponsesCustomOutputItemMetadata(
  Map<String, Object?> item, {
  required String? itemType,
}) {
  return _providerMetadata({
    'itemId': _asString(item['id']),
    'itemType': itemType ?? _asString(item['type']),
    'status': _asString(item['status']),
    'phase': _asString(item['phase']),
    if (itemType == 'compaction') 'encryptedContent': item['encrypted_content'],
  });
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
