part of 'elevenlabs_audio_bridge_support.dart';

final class _ElevenLabsSpeechBridgeSupport {
  final ElevenLabsConfig config;
  final modern_community.ElevenLabs modernProvider;

  const _ElevenLabsSpeechBridgeSupport({
    required this.config,
    required this.modernProvider,
  });

  bool canUseSpeechBridge(TTSRequest request) {
    final options = _resolveElevenLabsSpeechOptions(request.providerOptions);
    return _isValidSpeechRatio(options?.stability ?? request.stability) &&
        _isValidSpeechRatio(
          options?.similarityBoost ?? request.similarityBoost,
        ) &&
        _isValidSpeechRatio(options?.style ?? request.style) &&
        _isValidSpeechSeed(options?.seed ?? request.seed);
  }

  Future<TTSResponse> bridgeTextToSpeech(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    final options = _resolveElevenLabsSpeechOptions(request.providerOptions);
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
            outputFormat: options?.outputFormat ??
                _mapLegacySpeechOutputFormat(
                  request.format,
                  sampleRate: request.sampleRate,
                ),
            languageCode: options?.languageCode ?? request.languageCode,
            speed: options?.speed ?? request.speed,
            pronunciationDictionaryLocators:
                options?.pronunciationDictionaryLocators ?? const [],
            seed: options?.seed ?? request.seed,
            previousText: options?.previousText ?? request.previousText,
            nextText: options?.nextText ?? request.nextText,
            previousRequestIds: _resolveRequestIds(
              options?.previousRequestIds,
              request.previousRequestIds,
            ),
            nextRequestIds: _resolveRequestIds(
              options?.nextRequestIds,
              request.nextRequestIds,
            ),
            textNormalization: options?.textNormalization ??
                _toModernTextNormalization(request.textNormalization),
            applyLanguageTextNormalization:
                options?.applyLanguageTextNormalization,
            enableLogging: options?.enableLogging ?? request.enableLogging,
            optimizeStreamingLatency: options?.optimizeStreamingLatency ??
                request.optimizeStreamingLatency,
            stability: options?.stability ?? request.stability,
            similarityBoost:
                options?.similarityBoost ?? request.similarityBoost,
            style: options?.style ?? request.style,
            useSpeakerBoost:
                options?.useSpeakerBoost ?? request.useSpeakerBoost,
          ),
        ),
      ),
    );

    return TTSResponse(
      audioData: result.audioBytes,
      contentType: result.mediaType,
      voice: request.voice,
      model: request.model,
      duration: null,
      sampleRate: null,
      usage: null,
      providerMetadata: result.providerMetadata,
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

List<String> _resolveRequestIds(
  List<String>? optionValues,
  List<String>? legacyValues,
) {
  if (optionValues != null && optionValues.isNotEmpty) {
    return optionValues.take(3).toList(growable: false);
  }
  return _takeAtMostThree(legacyValues);
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
