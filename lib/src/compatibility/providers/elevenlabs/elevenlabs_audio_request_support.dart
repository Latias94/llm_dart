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
      'apply_text_normalization':
          (options?.textNormalization?.name ?? request.textNormalization.name),
    };

    final languageCode = options?.languageCode ?? request.languageCode;
    if (languageCode != null) {
      requestBody['language_code'] = languageCode;
    }
    final seed = options?.seed ?? request.seed;
    if (seed != null) {
      requestBody['seed'] = seed;
    }
    final previousText = options?.previousText ?? request.previousText;
    if (previousText != null) {
      requestBody['previous_text'] = previousText;
    }
    final nextText = options?.nextText ?? request.nextText;
    if (nextText != null) {
      requestBody['next_text'] = nextText;
    }
    final previousRequestIds = options?.previousRequestIds.isNotEmpty == true
        ? options!.previousRequestIds
        : request.previousRequestIds;
    if (previousRequestIds != null && previousRequestIds.isNotEmpty) {
      requestBody['previous_request_ids'] =
          previousRequestIds.take(3).toList(growable: false);
    }
    final nextRequestIds = options?.nextRequestIds.isNotEmpty == true
        ? options!.nextRequestIds
        : request.nextRequestIds;
    if (nextRequestIds != null && nextRequestIds.isNotEmpty) {
      requestBody['next_request_ids'] =
          nextRequestIds.take(3).toList(growable: false);
    }

    return requestBody;
  }

  Map<String, String> buildTextToSpeechQueryParams(TTSRequest request) {
    final options = _resolveElevenLabsSpeechOptions(request.providerOptions);
    final outputFormat = options?.outputFormat ?? 'mp3_44100_128';
    final enableLogging = options?.enableLogging ?? request.enableLogging;
    final optimizeStreamingLatency =
        options?.optimizeStreamingLatency ?? request.optimizeStreamingLatency;
    final queryParams = <String, String>{
      'output_format': outputFormat,
      'enable_logging': enableLogging.toString(),
    };
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
    final enableLogging = options?.enableLogging ?? request.enableLogging;
    if (!enableLogging) {
      return const {'enable_logging': 'false'};
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
    final speed = options?.speed;
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
