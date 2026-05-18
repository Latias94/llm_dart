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
