import 'package:llm_dart_provider/llm_dart_provider.dart';

ProviderMetadata? anthropicProviderMetadata(
  Map<String, Object?> values,
) {
  final anthropicValues = <String, Object?>{};
  for (final entry in values.entries) {
    if (entry.value != null) {
      anthropicValues[entry.key] = entry.value;
    }
  }

  if (anthropicValues.isEmpty) {
    return null;
  }

  return ProviderMetadata.forNamespace('anthropic', anthropicValues);
}

Map<String, Object?> anthropicProviderMetadataValues(
  ProviderMetadata? metadata,
) {
  final values = metadata?.values['anthropic'];
  if (values is Map<String, Object?>) {
    return values;
  }

  if (values is Map) {
    return Map<String, Object?>.from(values);
  }

  return const {};
}

FinishReason mapAnthropicStopReason(String? rawReason) {
  switch (rawReason) {
    case 'pause_turn':
    case 'end_turn':
    case 'stop_sequence':
      return FinishReason.stop;
    case 'tool_use':
      return FinishReason.toolCalls;
    case 'max_tokens':
    case 'model_context_window_exceeded':
      return FinishReason.maxTokens;
    case 'refusal':
      return FinishReason.contentFilter;
    default:
      return FinishReason.other;
  }
}

UsageStats? decodeAnthropicUsage(Map<String, Object?>? usage) {
  if (usage == null) {
    return null;
  }

  final inputTokens = _asInt(usage['input_tokens']);
  final outputTokens = _asInt(usage['output_tokens']);
  return UsageStats(
    inputTokens: inputTokens,
    outputTokens: outputTokens,
    totalTokens: (inputTokens ?? 0) + (outputTokens ?? 0),
  );
}

Map<String, Object?>? decodeAnthropicContainerMetadata(
  Map<String, Object?>? container,
) {
  if (container == null) {
    return null;
  }

  return {
    if (_asString(container['id']) != null) 'id': _asString(container['id']),
    if (_asString(container['expires_at']) != null)
      'expiresAt': _asString(container['expires_at']),
    if (container['skills'] != null)
      'skills': normalizeJsonValue(container['skills']),
  };
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
