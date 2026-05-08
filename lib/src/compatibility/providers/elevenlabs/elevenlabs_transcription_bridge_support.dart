part of 'elevenlabs_audio_bridge_support.dart';

final class _ElevenLabsTranscriptionBridgeSupport {
  final ElevenLabsConfig config;
  final modern_community.ElevenLabs modernProvider;

  const _ElevenLabsTranscriptionBridgeSupport({
    required this.config,
    required this.modernProvider,
  });

  bool canUseTranscriptionBridge(STTRequest request) {
    final options = _resolveElevenLabsTranscriptionOptions(
      request.providerOptions,
    );
    if (request.audioData == null) {
      return false;
    }

    if (request.timestampGranularity == TimestampGranularity.segment &&
        options?.timestampGranularity == null) {
      return false;
    }

    final numSpeakers = options?.numSpeakers ?? request.numSpeakers;
    if (numSpeakers != null && (numSpeakers < 1 || numSpeakers > 32)) {
      return false;
    }

    return true;
  }

  Future<STTResponse> bridgeSpeechToText(
    STTRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    final options = _resolveElevenLabsTranscriptionOptions(
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
          providerOptions: modern_community.ElevenLabsTranscriptionOptions(
            languageCode: options?.languageCode ?? request.language,
            tagAudioEvents: options?.tagAudioEvents ?? request.tagAudioEvents,
            numSpeakers: options?.numSpeakers ?? request.numSpeakers,
            timestampGranularity: options?.timestampGranularity ??
                _toModernTimestampGranularity(request.timestampGranularity),
            diarize: options?.diarize ?? request.diarize,
            fileFormat: options?.fileFormat ??
                _toModernTranscriptionFileFormat(request.format),
            enableLogging: options?.enableLogging ?? request.enableLogging,
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
      providerMetadata: result.providerMetadata,
    );
  }
}

String _resolveTranscriptionMediaType(
  STTRequest request,
  modern_community.ElevenLabsTranscriptionOptions? options,
) {
  return switch (options?.fileFormat) {
    modern_community.ElevenLabsTranscriptionFileFormat.pcmS16le16 =>
      'audio/pcm',
    modern_community.ElevenLabsTranscriptionFileFormat.other ||
    null =>
      _legacyAudioMediaType(request.format),
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
