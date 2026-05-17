import 'package:llm_dart_provider/llm_dart_provider.dart';

Map<String, Object?>? anthropicResultAsMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return Map<String, Object?>.from(value);
  }

  return null;
}

List<Object?> anthropicResultAsList(Object? value) {
  if (value is List<Object?>) {
    return value;
  }

  if (value is List) {
    return List<Object?>.from(value);
  }

  return const [];
}

String? anthropicResultAsString(Object? value) {
  return value is String ? value : null;
}

int? anthropicResultAsInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return null;
}

ProviderMetadata? anthropicResultProviderMetadata(
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

  return ProviderMetadata({
    'anthropic': anthropicValues,
  });
}

Map<String, Object?> anthropicResultProviderMetadataValues(
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
