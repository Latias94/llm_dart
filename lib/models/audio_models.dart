/// Audio-related models for Text-to-Speech (TTS) and Speech-to-Text (STT) functionality
library;

import 'package:llm_dart_provider/llm_dart_provider.dart'
    show ProviderInvocationOptions, ProviderMetadata;

import 'usage_models.dart';

part 'audio_models_events.dart';
part 'audio_models_metadata.dart';
part 'audio_models_primitives.dart';
part 'audio_models_stt.dart';
part 'audio_models_tts.dart';

ProviderMetadata? _providerMetadataFromJson(Map<String, dynamic> json) {
  final raw = json['provider_metadata'] ?? json['providerMetadata'];
  if (raw is! Map) {
    return null;
  }

  return ProviderMetadata(
    raw.map((key, value) => MapEntry(key.toString(), value as Object?)),
  );
}
