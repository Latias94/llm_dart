part of 'tts.dart';

final class _GoogleTTSRequestSupport {
  const _GoogleTTSRequestSupport();

  String resolveModel(GoogleTTSRequest request, GoogleConfig config) {
    return request.model ?? config.model;
  }

  String generateContentEndpoint(String model) {
    return 'models/$model:generateContent';
  }

  String streamGenerateContentEndpoint(String model) {
    return 'models/$model:streamGenerateContent';
  }

  bool supportsTTS(String model) {
    return model.contains('tts') || model.contains('gemini-2.5');
  }

  String get defaultTTSModel => 'gemini-2.5-flash-preview-tts';

  GoogleTTSRequest createSimpleRequest({
    required String text,
    required String voiceName,
    String? model,
  }) {
    return GoogleTTSRequest.singleSpeaker(
      text: text,
      voiceName: voiceName,
      model: model ?? defaultTTSModel,
    );
  }

  GoogleTTSRequest createMultiSpeakerRequest({
    required String text,
    required Map<String, String> speakerVoices,
    String? model,
  }) {
    final speakers = speakerVoices.entries
        .map(
          (entry) => GoogleSpeakerVoiceConfig(
            speaker: entry.key,
            voiceConfig: GoogleVoiceConfig.prebuilt(entry.value),
          ),
        )
        .toList();

    return GoogleTTSRequest.multiSpeaker(
      text: text,
      speakers: speakers,
      model: model ?? defaultTTSModel,
    );
  }
}
