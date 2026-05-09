import 'package:llm_dart_provider/llm_dart_provider.dart' show ProviderMetadata;

ProviderMetadata? audioProviderMetadataFromJson(Map<String, dynamic> json) {
  final raw = json['provider_metadata'] ?? json['providerMetadata'];
  if (raw is! Map) {
    return null;
  }

  return ProviderMetadata(
    raw.map((key, value) => MapEntry(key.toString(), value as Object?)),
  );
}
