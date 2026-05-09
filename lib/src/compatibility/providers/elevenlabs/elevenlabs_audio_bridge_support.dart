import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart'
    as modern_elevenlabs;
import 'package:llm_dart_provider/llm_dart_provider.dart' as core;
import 'package:llm_dart_transport/llm_dart_transport.dart'
    show TransportCancellation;

import '../../../../models/audio_models.dart';
import '../../../../providers/elevenlabs/config.dart';
import 'elevenlabs_option_support.dart';

/// Bridge-local request shaping and response normalization for ElevenLabs.
///
/// This keeps dedicated-package bridge constraints and codec translation out of
/// the compatibility shell so the shell can stay focused on bridge-vs-fallback
/// orchestration.
final class ElevenLabsAudioBridgeSupport {
  final ElevenLabsConfig config;
  final modern_elevenlabs.ElevenLabs modernProvider;
  final _ElevenLabsSpeechBridgeSupport _speechSupport;
  final _ElevenLabsTranscriptionBridgeSupport _transcriptionSupport;

  ElevenLabsAudioBridgeSupport({
    required this.config,
    required this.modernProvider,
  })  : _speechSupport = _ElevenLabsSpeechBridgeSupport(
          config: config,
          modernProvider: modernProvider,
        ),
        _transcriptionSupport = _ElevenLabsTranscriptionBridgeSupport(
          config: config,
          modernProvider: modernProvider,
        );

  bool canUseSpeechBridge(TTSRequest request) {
    return _speechSupport.canUseSpeechBridge(request);
  }

  Future<TTSResponse> bridgeTextToSpeech(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) {
    return _speechSupport.bridgeTextToSpeech(
      request,
      cancelToken: cancelToken,
    );
  }

  bool canUseTranscriptionBridge(STTRequest request) {
    return _transcriptionSupport.canUseTranscriptionBridge(request);
  }

  Future<STTResponse> bridgeSpeechToText(
    STTRequest request, {
    TransportCancellation? cancelToken,
  }) {
    return _transcriptionSupport.bridgeSpeechToText(
      request,
      cancelToken: cancelToken,
    );
  }
}

final class _ElevenLabsSpeechBridgeSupport {
  final ElevenLabsConfig config;
  final modern_elevenlabs.ElevenLabs modernProvider;

  const _ElevenLabsSpeechBridgeSupport({
    required this.config,
    required this.modernProvider,
  });

  bool canUseSpeechBridge(TTSRequest request) {
    final options = resolveElevenLabsSpeechOptions(request.providerOptions);
    return _isValidSpeechRatio(options?.stability) &&
        _isValidSpeechRatio(options?.similarityBoost) &&
        _isValidSpeechRatio(options?.style) &&
        _isValidSpeechSeed(options?.seed);
  }

  Future<TTSResponse> bridgeTextToSpeech(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    final options = resolveElevenLabsSpeechOptions(request.providerOptions);
    final model = modernProvider.speechModel(
      request.model ?? config.defaultTTSModel,
      settings: modern_elevenlabs.ElevenLabsSpeechModelSettings(
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
          providerOptions: modern_elevenlabs.ElevenLabsSpeechOptions(
            outputFormat: options?.outputFormat ??
                _mapLegacySpeechOutputFormat(
                  request.format,
                  sampleRate: request.sampleRate,
                ),
            languageCode: options?.languageCode ?? request.languageCode,
            speed: options?.speed ?? request.speed,
            pronunciationDictionaryLocators:
                options?.pronunciationDictionaryLocators ?? const [],
            seed: options?.seed,
            previousText: options?.previousText,
            nextText: options?.nextText,
            previousRequestIds: _takeAtMostThree(
              options?.previousRequestIds,
            ),
            nextRequestIds: _takeAtMostThree(options?.nextRequestIds),
            textNormalization: options?.textNormalization,
            applyLanguageTextNormalization:
                options?.applyLanguageTextNormalization,
            enableLogging: options?.enableLogging,
            optimizeStreamingLatency: options?.optimizeStreamingLatency,
            stability: options?.stability,
            similarityBoost: options?.similarityBoost,
            style: options?.style,
            useSpeakerBoost: options?.useSpeakerBoost,
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

final class _ElevenLabsTranscriptionBridgeSupport {
  final ElevenLabsConfig config;
  final modern_elevenlabs.ElevenLabs modernProvider;

  const _ElevenLabsTranscriptionBridgeSupport({
    required this.config,
    required this.modernProvider,
  });

  bool canUseTranscriptionBridge(STTRequest request) {
    final options = resolveElevenLabsTranscriptionOptions(
      request.providerOptions,
    );
    if (request.audioData == null) {
      return false;
    }

    if (request.timestampGranularity == TimestampGranularity.segment &&
        options?.timestampGranularity == null) {
      return false;
    }

    final numSpeakers = options?.numSpeakers;
    if (numSpeakers != null && (numSpeakers < 1 || numSpeakers > 32)) {
      return false;
    }

    return true;
  }

  Future<STTResponse> bridgeSpeechToText(
    STTRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    final options = resolveElevenLabsTranscriptionOptions(
      request.providerOptions,
    );
    final model = modernProvider.transcriptionModel(
      request.model ?? config.defaultSTTModel,
    );

    final result = await model.transcribe(
      core.TranscriptionRequest(
        audioBytes: request.audioData!,
        mediaType: _resolveTranscriptionMediaType(request, options),
        callOptions: core.CallOptions(
          timeout: config.timeout,
          cancellation: cancelToken,
          providerOptions: modern_elevenlabs.ElevenLabsTranscriptionOptions(
            languageCode: options?.languageCode ?? request.language,
            tagAudioEvents: options?.tagAudioEvents,
            numSpeakers: options?.numSpeakers,
            timestampGranularity: options?.timestampGranularity ??
                _toModernTimestampGranularity(request.timestampGranularity),
            diarize: options?.diarize,
            fileFormat: options?.fileFormat ??
                _toModernTranscriptionFileFormat(request.format),
            enableLogging: options?.enableLogging,
          ),
        ),
      ),
    );

    final metadata = result.providerMetadata?.namespace('elevenlabs');
    final languageProbability = _asDouble(metadata?['languageProbability']);

    return STTResponse(
      text: result.text,
      language: metadata?['languageCode'] as String?,
      confidence: languageProbability,
      words: _decodeLegacyWordTimings(metadata?['words']),
      model: request.model,
      duration: null,
      usage: null,
      providerMetadata: result.providerMetadata,
    );
  }
}

String _resolveTranscriptionMediaType(
  STTRequest request,
  modern_elevenlabs.ElevenLabsTranscriptionOptions? options,
) {
  return switch (options?.fileFormat) {
    modern_elevenlabs.ElevenLabsTranscriptionFileFormat.pcmS16le16 =>
      'audio/pcm',
    modern_elevenlabs.ElevenLabsTranscriptionFileFormat.other ||
    null =>
      _legacyAudioMediaType(request.format),
  };
}

modern_elevenlabs.ElevenLabsTranscriptionTimestampGranularity?
    _toModernTimestampGranularity(
  TimestampGranularity granularity,
) {
  return switch (granularity) {
    TimestampGranularity.none =>
      modern_elevenlabs.ElevenLabsTranscriptionTimestampGranularity.none,
    TimestampGranularity.word =>
      modern_elevenlabs.ElevenLabsTranscriptionTimestampGranularity.word,
    TimestampGranularity.character =>
      modern_elevenlabs.ElevenLabsTranscriptionTimestampGranularity.character,
    TimestampGranularity.segment => null,
  };
}

modern_elevenlabs.ElevenLabsTranscriptionFileFormat?
    _toModernTranscriptionFileFormat(String? format) {
  final normalized = format?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  return switch (normalized) {
    'pcm_s16le_16' =>
      modern_elevenlabs.ElevenLabsTranscriptionFileFormat.pcmS16le16,
    _ => modern_elevenlabs.ElevenLabsTranscriptionFileFormat.other,
  };
}

String _legacyAudioMediaType(String? format) {
  final normalized = format?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return 'audio/wav';
  }

  if (normalized.contains('/')) {
    return normalized;
  }

  return switch (normalized) {
    'mp3' => 'audio/mpeg',
    'wav' => 'audio/wav',
    'webm' => 'audio/webm',
    'mp4' => 'audio/mp4',
    'm4a' => 'audio/m4a',
    'ogg' => 'audio/ogg',
    'flac' => 'audio/flac',
    'pcm' || 'pcm_s16le_16' => 'audio/pcm',
    _ => 'audio/$normalized',
  };
}

double? _asDouble(Object? value) {
  return switch (value) {
    num() => value.toDouble(),
    _ => null,
  };
}

List<WordTiming>? _decodeLegacyWordTimings(Object? value) {
  if (value is! List) {
    return null;
  }

  final words = <WordTiming>[];
  for (final item in value) {
    if (item is! Map) {
      continue;
    }

    final text = item['text'];
    final start = item['start'];
    final end = item['end'];
    if (text is! String || start is! num || end is! num) {
      continue;
    }

    words.add(
      WordTiming(
        word: text,
        start: start.toDouble(),
        end: end.toDouble(),
        confidence: _asDouble(item['confidence']),
      ),
    );
  }

  return words.isEmpty ? null : words;
}
