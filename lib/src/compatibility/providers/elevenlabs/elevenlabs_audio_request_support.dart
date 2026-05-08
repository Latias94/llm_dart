part of 'elevenlabs_audio_support.dart';

final class _ElevenLabsAudioRequestSupport {
  const _ElevenLabsAudioRequestSupport();

  Map<String, dynamic> buildTextToSpeechRequestBody(
    TTSRequest request, {
    required ElevenLabsConfig config,
    required String effectiveModel,
  }) {
    final options = _resolveElevenLabsSpeechOptions(request.providerOptions);
    final voiceSettings = _buildVoiceSettings(
      request,
      config: config,
      options: options,
    );
    final requestBody = <String, dynamic>{
      'text': request.text,
      'model_id': effectiveModel,
      'voice_settings': voiceSettings,
    };
    final textNormalization = options?.textNormalization;
    if (textNormalization != null) {
      requestBody['apply_text_normalization'] = textNormalization.name;
    }

    final languageCode = options?.languageCode ?? request.languageCode;
    if (languageCode != null) {
      requestBody['language_code'] = languageCode;
    }
    final seed = options?.seed;
    if (seed != null) {
      requestBody['seed'] = seed;
    }
    final previousText = options?.previousText;
    if (previousText != null) {
      requestBody['previous_text'] = previousText;
    }
    final nextText = options?.nextText;
    if (nextText != null) {
      requestBody['next_text'] = nextText;
    }
    final previousRequestIds = options?.previousRequestIds;
    if (previousRequestIds != null && previousRequestIds.isNotEmpty) {
      requestBody['previous_request_ids'] =
          previousRequestIds.take(3).toList(growable: false);
    }
    final nextRequestIds = options?.nextRequestIds;
    if (nextRequestIds != null && nextRequestIds.isNotEmpty) {
      requestBody['next_request_ids'] =
          nextRequestIds.take(3).toList(growable: false);
    }

    return requestBody;
  }

  Map<String, String> buildTextToSpeechQueryParams(TTSRequest request) {
    final options = _resolveElevenLabsSpeechOptions(request.providerOptions);
    final outputFormat = options?.outputFormat ?? 'mp3_44100_128';
    final queryParams = <String, String>{
      'output_format': outputFormat,
    };
    final enableLogging = options?.enableLogging;
    if (enableLogging != null) {
      queryParams['enable_logging'] = enableLogging.toString();
    }
    final optimizeStreamingLatency = options?.optimizeStreamingLatency;
    if (optimizeStreamingLatency != null) {
      queryParams['optimize_streaming_latency'] =
          optimizeStreamingLatency.toString();
    }
    return queryParams;
  }

  Map<String, String>? buildSpeechToTextQueryParams(STTRequest request) {
    final options = _resolveElevenLabsTranscriptionOptions(
      request.providerOptions,
    );
    final enableLogging = options?.enableLogging;
    if (enableLogging != null) {
      return {'enable_logging': enableLogging.toString()};
    }
    return null;
  }

  Map<String, dynamic> _buildVoiceSettings(
    TTSRequest request, {
    required ElevenLabsConfig config,
    required modern_community.ElevenLabsSpeechOptions? options,
  }) {
    final settings = <String, dynamic>{...config.voiceSettings};
    _addRatio(settings, 'stability', options?.stability);
    _addRatio(
      settings,
      'similarity_boost',
      options?.similarityBoost,
    );
    _addRatio(settings, 'style', options?.style);
    final useSpeakerBoost = options?.useSpeakerBoost;
    if (useSpeakerBoost != null) {
      settings['use_speaker_boost'] = useSpeakerBoost;
    }
    final speed = options?.speed ?? request.speed;
    if (speed != null) {
      settings['speed'] = speed;
    }
    return settings;
  }

  void _addRatio(
    Map<String, dynamic> settings,
    String key,
    double? value,
  ) {
    if (value == null || value < 0 || value > 1) {
      return;
    }
    settings[key] = value;
  }
}
