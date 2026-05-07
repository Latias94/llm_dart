part of 'elevenlabs_audio_support.dart';

final class _ElevenLabsAudioRequestSupport {
  const _ElevenLabsAudioRequestSupport();

  Map<String, dynamic> buildTextToSpeechRequestBody(
    TTSRequest request, {
    required ElevenLabsConfig config,
    required String effectiveModel,
  }) {
    final requestBody = <String, dynamic>{
      'text': request.text,
      'model_id': effectiveModel,
      'voice_settings': config.voiceSettings,
      'apply_text_normalization': request.textNormalization.name,
    };

    if (request.languageCode != null) {
      requestBody['language_code'] = request.languageCode;
    }
    if (request.seed != null) {
      requestBody['seed'] = request.seed;
    }
    if (request.previousText != null) {
      requestBody['previous_text'] = request.previousText;
    }
    if (request.nextText != null) {
      requestBody['next_text'] = request.nextText;
    }
    if (request.previousRequestIds != null &&
        request.previousRequestIds!.isNotEmpty) {
      requestBody['previous_request_ids'] =
          request.previousRequestIds!.take(3).toList();
    }
    if (request.nextRequestIds != null && request.nextRequestIds!.isNotEmpty) {
      requestBody['next_request_ids'] =
          request.nextRequestIds!.take(3).toList();
    }

    return requestBody;
  }

  Map<String, String> buildTextToSpeechQueryParams(TTSRequest request) {
    final queryParams = <String, String>{
      'output_format': 'mp3_44100_128',
      'enable_logging': request.enableLogging.toString(),
    };
    if (request.optimizeStreamingLatency != null) {
      queryParams['optimize_streaming_latency'] =
          request.optimizeStreamingLatency.toString();
    }
    return queryParams;
  }

  Map<String, String>? buildSpeechToTextQueryParams(STTRequest request) {
    if (!request.enableLogging) {
      return const {'enable_logging': 'false'};
    }
    return null;
  }
}
