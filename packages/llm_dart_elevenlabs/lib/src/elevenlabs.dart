import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'elevenlabs_options.dart';
import 'elevenlabs_shared.dart';
import 'elevenlabs_speech_model.dart';
import 'elevenlabs_transcription_model.dart';
import 'elevenlabs_voice_catalog.dart';

/// Creates an ElevenLabs provider facade for speech, transcription, and voices.
ElevenLabs elevenLabs({
  required String apiKey,
  TransportClient? transport,
  String? baseUrl,
}) {
  return ElevenLabs(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
  );
}

/// Package-owned ElevenLabs namespace for dedicated provider surfaces.
final class ElevenLabs {
  static const String defaultBaseUrl = elevenLabsDefaultBaseUrl;

  final String apiKey;
  final String baseUrl;
  final TransportClient transport;

  ElevenLabs({
    required this.apiKey,
    TransportClient? transport,
    String? baseUrl,
  })  : baseUrl = normalizeElevenLabsBaseUrl(baseUrl),
        transport = transport ?? DioTransportClient();

  ElevenLabsSpeechModel speechModel(
    String modelId, {
    ElevenLabsSpeechModelSettings settings =
        const ElevenLabsSpeechModelSettings(),
  }) {
    return ElevenLabsSpeechModel(
      apiKey: apiKey,
      modelId: modelId,
      transport: transport,
      baseUrl: baseUrl,
      settings: settings,
    );
  }

  ElevenLabsTranscriptionModel transcriptionModel(
    String modelId, {
    ElevenLabsTranscriptionModelSettings settings =
        const ElevenLabsTranscriptionModelSettings(),
  }) {
    return ElevenLabsTranscriptionModel(
      apiKey: apiKey,
      modelId: modelId,
      transport: transport,
      baseUrl: baseUrl,
      settings: settings,
    );
  }

  ElevenLabsVoiceCatalogClient voices({
    ElevenLabsVoiceCatalogSettings settings =
        const ElevenLabsVoiceCatalogSettings(),
  }) {
    return ElevenLabsVoiceCatalogClient(
      apiKey: apiKey,
      transport: transport,
      baseUrl: baseUrl,
      settings: settings,
    );
  }
}
