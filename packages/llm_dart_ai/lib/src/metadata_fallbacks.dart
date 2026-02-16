import 'package:llm_dart_core/llm_dart_core.dart';

import 'types.dart';

int _fallbackIdCounter = 0;

String _generateFallbackId(DateTime startedAtUtc) {
  final n = _fallbackIdCounter++;
  return 'local_${startedAtUtc.microsecondsSinceEpoch}_$n';
}

LLMResponseMetadataPart responseMetadataWithDefaults(
  LLMResponseMetadataPart? metadata,
  DateTime startedAtUtc, {
  String? defaultModelId,
}) {
  final meta = metadata;

  final id = (meta?.id == null || meta!.id!.trim().isEmpty)
      ? _generateFallbackId(startedAtUtc)
      : meta.id!;

  final timestamp = meta?.timestamp ?? startedAtUtc;
  final modelId = (meta?.modelId == null || meta!.modelId!.trim().isEmpty)
      ? defaultModelId
      : meta.modelId;

  if (meta != null &&
      id == meta.id &&
      timestamp == meta.timestamp &&
      modelId == meta.modelId) {
    return meta;
  }

  return LLMResponseMetadataPart(
    id: id,
    timestamp: timestamp,
    modelId: modelId,
    headers: meta?.headers,
    body: meta?.body,
    status: meta?.status,
    systemFingerprint: meta?.systemFingerprint,
    providerMetadata: meta?.providerMetadata,
    raw: meta?.raw,
  );
}

LLMRequestMetadataPart? requestMetadataWithInclude(
  LLMRequestMetadataPart? metadata,
  IncludeOptions include,
) {
  final meta = metadata;
  if (meta == null) return null;
  if (include.requestBody) return meta;
  if (meta.body == null) return meta;
  return const LLMRequestMetadataPart(body: null);
}

LLMResponseMetadataPart? responseMetadataWithInclude(
  LLMResponseMetadataPart? metadata,
  IncludeOptions include,
) {
  final meta = metadata;
  if (meta == null) return null;
  if (include.responseBody) return meta;
  if (meta.body == null) return meta;

  return LLMResponseMetadataPart(
    id: meta.id,
    timestamp: meta.timestamp,
    modelId: meta.modelId,
    headers: meta.headers,
    body: null,
    status: meta.status,
    systemFingerprint: meta.systemFingerprint,
    providerMetadata: meta.providerMetadata,
    raw: meta.raw,
  );
}

Stream<LLMStreamPart> streamPartsWithInclude(
  Stream<LLMStreamPart> upstream,
  IncludeOptions include,
) async* {
  await for (final part in upstream) {
    switch (part) {
      case LLMRequestMetadataPart(:final body):
        if (include.requestBody || body == null) {
          yield part;
        } else {
          yield const LLMRequestMetadataPart(body: null);
        }
      case LLMResponseMetadataPart():
        yield responseMetadataWithInclude(part, include) ?? part;
      default:
        yield part;
    }
  }
}

LLMResponseMetadataPart? responseMetadataWithTimestampFallback(
  LLMResponseMetadataPart? metadata,
  DateTime startedAtUtc,
) {
  if (metadata == null) return null;
  return responseMetadataWithDefaults(metadata, startedAtUtc);
}
