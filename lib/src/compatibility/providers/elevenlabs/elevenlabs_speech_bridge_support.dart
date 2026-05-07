part of 'elevenlabs_audio_bridge_support.dart';

mixin _ElevenLabsSpeechBridgeSupport {
  ElevenLabsConfig get config;
  modern_community.ElevenLabs get modernProvider;

  bool canUseSpeechBridge(TTSRequest request) {
    return _isValidSpeechRatio(request.stability) &&
        _isValidSpeechRatio(request.similarityBoost) &&
        _isValidSpeechRatio(request.style) &&
        _isValidSpeechSeed(request.seed);
  }

  Future<TTSResponse> bridgeTextToSpeech(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    final model = modernProvider.speechModel(
      request.model ?? config.defaultTTSModel,
      settings: modern_community.ElevenLabsSpeechModelSettings(
        defaultVoiceId: config.voiceId,
        stability: config.stability,
        similarityBoost: config.similarityBoost,
        style: config.style,
        useSpeakerBoost: config.useSpeakerBoost,
      ),
    );

    final result = await model.generateSpeech(
      core.SpeechGenerationRequest(
        text: request.text,
        voice: request.voice,
        callOptions: core.CallOptions(
          timeout: config.timeout,
          cancellation: cancelToken,
          providerOptions: modern_community.ElevenLabsSpeechOptions(
            outputFormat: _mapLegacySpeechOutputFormat(
              request.format,
              sampleRate: request.sampleRate,
            ),
            languageCode: request.languageCode,
            speed: request.speed,
            seed: request.seed,
            previousText: request.previousText,
            nextText: request.nextText,
            previousRequestIds: _takeAtMostThree(request.previousRequestIds),
            nextRequestIds: _takeAtMostThree(request.nextRequestIds),
            textNormalization:
                _toModernTextNormalization(request.textNormalization),
            enableLogging: request.enableLogging,
            optimizeStreamingLatency: request.optimizeStreamingLatency,
            stability: request.stability,
            similarityBoost: request.similarityBoost,
            style: request.style,
            useSpeakerBoost: request.useSpeakerBoost,
          ),
        ),
      ),
    );

    final metadata = result.providerMetadata?.namespace('elevenlabs');

    return TTSResponse(
      audioData: result.audioBytes,
      contentType: result.mediaType,
      voice: request.voice,
      model: request.model,
      duration: null,
      sampleRate: null,
      usage: null,
      requestId: metadata?['requestId'] as String?,
    );
  }
}

bool _isValidSpeechRatio(double? value) {
  return value == null || (value >= 0 && value <= 1);
}

bool _isValidSpeechSeed(int? value) {
  return value == null || (value >= 0 && value <= 4294967295);
}

List<String> _takeAtMostThree(List<String>? values) {
  if (values == null || values.isEmpty) {
    return const [];
  }

  return values.take(3).toList(growable: false);
}

modern_community.ElevenLabsTextNormalization _toModernTextNormalization(
  TextNormalization normalization,
) {
  return switch (normalization) {
    TextNormalization.auto => modern_community.ElevenLabsTextNormalization.auto,
    TextNormalization.on => modern_community.ElevenLabsTextNormalization.on,
    TextNormalization.off => modern_community.ElevenLabsTextNormalization.off,
  };
}

String? _mapLegacySpeechOutputFormat(
  String? format, {
  required int? sampleRate,
}) {
  final normalized = format?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  return switch (normalized) {
    'mp3' || 'mp3_128' => 'mp3',
    'mp3_32' => 'mp3_32',
    'mp3_64' => 'mp3_64',
    'mp3_96' => 'mp3_96',
    'mp3_192' || 'mp3_44100_192' => 'mp3_44100_192',
    'mp3_44100_32' => 'mp3_44100_32',
    'mp3_44100_64' => 'mp3_44100_64',
    'mp3_44100_96' => 'mp3_44100_96',
    'mp3_44100_128' => 'mp3_44100_128',
    'pcm' || 'wav' => _mapLegacyPcmOutputFormat(sampleRate),
    'ulaw' || 'ulaw_8000' => 'ulaw_8000',
    'pcm_16000' || 'pcm_22050' || 'pcm_24000' || 'pcm_44100' => normalized,
    _ => format,
  };
}

String _mapLegacyPcmOutputFormat(int? sampleRate) {
  return switch (sampleRate) {
    16000 => 'pcm_16000',
    22050 => 'pcm_22050',
    24000 => 'pcm_24000',
    _ => 'pcm_44100',
  };
}
