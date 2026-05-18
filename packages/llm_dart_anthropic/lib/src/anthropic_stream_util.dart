import 'package:llm_dart_provider/llm_dart_provider.dart';

Map<String, Object?>? anthropicStreamAsMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return Map<String, Object?>.from(value);
  }

  return null;
}

List<Object?> anthropicStreamAsList(Object? value) {
  if (value is List<Object?>) {
    return value;
  }

  if (value is List) {
    return List<Object?>.from(value);
  }

  return const [];
}

String? anthropicStreamAsString(Object? value) {
  return value is String ? value : null;
}

int? anthropicStreamAsInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return null;
}

Map<String, Object?>? mergeAnthropicStreamObjects(
  Map<String, Object?>? left,
  Map<String, Object?>? right,
) {
  if (left == null && right == null) {
    return null;
  }

  return {
    ...?left,
    ...?right,
  };
}

ProviderMetadata? anthropicStreamProviderMetadata(
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

Map<String, Object?> anthropicStreamProviderMetadataValues(
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
