import 'package:llm_dart_community/llm_dart_community.dart' as modern_community;
import 'package:llm_dart_core/llm_dart_core.dart' as core;

import '../../../../models/audio_models.dart';
import '../../../../providers/elevenlabs/config.dart';

/// Bridge-local request shaping and response normalization for ElevenLabs.
///
/// This keeps modern-community bridge constraints and codec translation out of
/// the compatibility shell so the shell can stay focused on bridge-vs-fallback
/// orchestration.
final class ElevenLabsAudioBridgeSupport {
  final ElevenLabsConfig config;
  final modern_community.ElevenLabs modernProvider;

  const ElevenLabsAudioBridgeSupport({
    required this.config,
    required this.modernProvider,
  });

  bool canUseSpeechBridge(TTSRequest request) {
    return _isValidSpeechRatio(request.stability) &&
        _isValidSpeechRatio(request.similarityBoost) &&
        _isValidSpeechRatio(request.style) &&
        _isValidSpeechSeed(request.seed);
  }

  bool canUseTranscriptionBridge(STTRequest request) {
    if (request.audioData == null) {
      return false;
    }

    if (request.timestampGranularity == TimestampGranularity.segment) {
      return false;
    }

    final numSpeakers = request.numSpeakers;
    if (numSpeakers != null && (numSpeakers < 1 || numSpeakers > 32)) {
      return false;
    }

    return true;
  }

  Future<TTSResponse> bridgeTextToSpeech(
    TTSRequest request, {
    core.TransportCancellation? cancelToken,
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

  Future<STTResponse> bridgeSpeechToText(
    STTRequest request, {
    core.TransportCancellation? cancelToken,
  }) async {
    final model = modernProvider.transcriptionModel(
      request.model ?? config.defaultSTTModel,
    );

    final result = await model.transcribe(
      core.TranscriptionRequest(
        audioBytes: request.audioData!,
        mediaType: _legacyAudioMediaType(request.format),
        callOptions: core.CallOptions(
          timeout: config.timeout,
          cancellation: cancelToken,
          providerOptions: modern_community.ElevenLabsTranscriptionOptions(
            languageCode: request.language,
            tagAudioEvents: request.tagAudioEvents,
            numSpeakers: request.numSpeakers,
            timestampGranularity:
                _toModernTimestampGranularity(request.timestampGranularity),
            diarize: request.diarize,
            fileFormat: _toModernTranscriptionFileFormat(request.format),
            enableLogging: request.enableLogging,
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
      languageProbability: languageProbability,
      additionalFormats: _asStringDynamicMap(metadata?['additionalFormats']),
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

modern_community.ElevenLabsTranscriptionTimestampGranularity?
    _toModernTimestampGranularity(
  TimestampGranularity granularity,
) {
  return switch (granularity) {
    TimestampGranularity.none =>
      modern_community.ElevenLabsTranscriptionTimestampGranularity.none,
    TimestampGranularity.word =>
      modern_community.ElevenLabsTranscriptionTimestampGranularity.word,
    TimestampGranularity.character =>
      modern_community.ElevenLabsTranscriptionTimestampGranularity.character,
    TimestampGranularity.segment => null,
  };
}

modern_community.ElevenLabsTranscriptionFileFormat?
    _toModernTranscriptionFileFormat(String? format) {
  final normalized = format?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  return switch (normalized) {
    'pcm_s16le_16' =>
      modern_community.ElevenLabsTranscriptionFileFormat.pcmS16le16,
    _ => modern_community.ElevenLabsTranscriptionFileFormat.other,
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

Map<String, dynamic>? _asStringDynamicMap(Object? value) {
  if (value is! Map) {
    return null;
  }

  return value.map(
    (key, nestedValue) => MapEntry(key as String, nestedValue),
  );
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
