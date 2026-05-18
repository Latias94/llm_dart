import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_metadata_support.dart';

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
  return anthropicProviderMetadata(values);
}

Map<String, Object?> anthropicResultProviderMetadataValues(
  ProviderMetadata? metadata,
) {
  return anthropicProviderMetadataValues(metadata);
}
