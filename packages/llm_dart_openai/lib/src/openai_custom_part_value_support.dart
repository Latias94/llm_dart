part of 'openai_custom_part.dart';

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
  if (value == null || value.isEmpty) {
    return null;
  }

  return base64Decode(value);
}

String? openaiMetadataString(
  ProviderMetadata? providerMetadata,
  String key,
) {
  final openai = providerMetadata?.namespace('openai');
  return asString(openai?[key]);
}

int? openaiMetadataInt(
  ProviderMetadata? providerMetadata,
  String key,
) {
  final openai = providerMetadata?.namespace('openai');
  return asInt(openai?[key]);
}
