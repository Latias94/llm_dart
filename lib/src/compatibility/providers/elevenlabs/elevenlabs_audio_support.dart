import 'dart:typed_data';

import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart'
    as modern_elevenlabs;
import 'package:llm_dart_provider/llm_dart_provider.dart' show ProviderMetadata;
import 'package:llm_dart_transport/dio.dart';

import '../../../../models/audio_models.dart';
import '../../../../providers/elevenlabs/config.dart';
import 'elevenlabs_audio_catalog.dart';
import 'elevenlabs_option_support.dart';

/// Provider-local request and response shaping for ElevenLabs audio compatibility.
final class ElevenLabsAudioSupport {
  static const supportedLanguages = ElevenLabsAudioCatalog.supportedLanguages;

  static const _requestSupport = _ElevenLabsAudioRequestSupport();
  static const _formSupport = _ElevenLabsAudioFormSupport();
  static const _responseSupport = _ElevenLabsAudioResponseSupport();

  const ElevenLabsAudioSupport();

  Map<String, dynamic> buildTextToSpeechRequestBody(
    TTSRequest request, {
    required ElevenLabsConfig config,
    required String effectiveModel,
  }) {
    return _requestSupport.buildTextToSpeechRequestBody(
      request,
      config: config,
      effectiveModel: effectiveModel,
    );
  }

  Map<String, String> buildTextToSpeechQueryParams(TTSRequest request) {
    return _requestSupport.buildTextToSpeechQueryParams(request);
  }

  TTSResponse buildTextToSpeechResponse(
    Uint8List audioData, {
    required TTSRequest request,
    String? contentType,
  }) {
    return _responseSupport.buildTextToSpeechResponse(
      audioData,
      request: request,
      contentType: contentType,
    );
  }

  Future<FormData> buildSpeechToTextFormDataFromBytes(
    List<int> audioData, {
    required STTRequest request,
    required String effectiveModel,
  }) async {
    return _formSupport.buildSpeechToTextFormDataFromBytes(
      audioData,
      request: request,
      effectiveModel: effectiveModel,
    );
  }

  Future<FormData> buildSpeechToTextFormDataFromFile(
    String filePath, {
    required STTRequest request,
    required String effectiveModel,
  }) async {
    return _formSupport.buildSpeechToTextFormDataFromFile(
      filePath,
      request: request,
      effectiveModel: effectiveModel,
    );
  }

  Future<FormData> buildSpeechToTextFormDataFromSourceUrl(
    String sourceUrl, {
    required STTRequest request,
    required String effectiveModel,
  }) async {
    return _formSupport.buildSpeechToTextFormDataFromSourceUrl(
      sourceUrl,
      request: request,
      effectiveModel: effectiveModel,
    );
  }

  Map<String, String>? buildSpeechToTextQueryParams(STTRequest request) {
    return _requestSupport.buildSpeechToTextQueryParams(request);
  }

  STTResponse parseSpeechToTextResponse(
    Map<String, dynamic> responseData, {
    required STTRequest request,
  }) {
    return _responseSupport.parseSpeechToTextResponse(
      responseData,
      request: request,
    );
  }

  List<VoiceInfo> mapVoices(List<Map<String, dynamic>> rawVoices) {
    return _responseSupport.mapVoices(rawVoices);
  }
}

final class _ElevenLabsAudioFormSupport {
  const _ElevenLabsAudioFormSupport();

  Future<FormData> buildSpeechToTextFormDataFromBytes(
    List<int> audioData, {
    required STTRequest request,
    required String effectiveModel,
  }) async {
    return FormData.fromMap(
      _buildSpeechToTextFieldMap(
        request: request,
        effectiveModel: effectiveModel,
        file: MultipartFile.fromBytes(
          Uint8List.fromList(audioData),
          filename: 'audio.wav',
          contentType: DioMediaType('audio', 'wav'),
        ),
      ),
    );
  }

  Future<FormData> buildSpeechToTextFormDataFromFile(
    String filePath, {
    required STTRequest request,
    required String effectiveModel,
  }) async {
    return FormData.fromMap(
      _buildSpeechToTextFieldMap(
        request: request,
        effectiveModel: effectiveModel,
        file: await MultipartFile.fromFile(filePath),
      ),
    );
  }

  Future<FormData> buildSpeechToTextFormDataFromSourceUrl(
    String sourceUrl, {
    required STTRequest request,
    required String effectiveModel,
  }) async {
    return FormData.fromMap(
      _buildSpeechToTextFieldMap(
        request: request,
        effectiveModel: effectiveModel,
        sourceUrl: sourceUrl,
      ),
    );
  }

  Map<String, dynamic> _buildSpeechToTextFieldMap({
    required STTRequest request,
    required String effectiveModel,
    MultipartFile? file,
    String? sourceUrl,
  }) {
    final options = resolveElevenLabsTranscriptionOptions(
      request.providerOptions,
    );
    final timestampGranularity = options?.timestampGranularity?.name ??
        request.timestampGranularity.name;
    final fields = <String, dynamic>{
      'model_id': effectiveModel,
      'timestamps_granularity': timestampGranularity,
    };
    final tagAudioEvents = options?.tagAudioEvents;
    if (tagAudioEvents != null) {
      fields['tag_audio_events'] = tagAudioEvents.toString();
    }
    final diarize = options?.diarize;
    if (diarize != null) {
      fields['diarize'] = diarize.toString();
    }

    if (file != null) {
      fields['file'] = file;
    }
    if (sourceUrl != null) {
      fields['source_url'] = sourceUrl;
    }

    final languageCode = options?.languageCode ?? request.language;
    if (languageCode != null) {
      fields['language_code'] = languageCode;
    }
    final numSpeakers = options?.numSpeakers;
    if (numSpeakers != null) {
      fields['num_speakers'] = numSpeakers.toString();
    }
    final fileFormat = options?.fileFormat?.value ?? request.format;
    if (fileFormat != null) {
      fields['file_format'] = fileFormat;
    }

    return fields;
  }
}

final class _ElevenLabsAudioRequestSupport {
  const _ElevenLabsAudioRequestSupport();

  Map<String, dynamic> buildTextToSpeechRequestBody(
    TTSRequest request, {
    required ElevenLabsConfig config,
    required String effectiveModel,
  }) {
    final options = resolveElevenLabsSpeechOptions(request.providerOptions);
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
    final options = resolveElevenLabsSpeechOptions(request.providerOptions);
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
    final options = resolveElevenLabsTranscriptionOptions(
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
    required modern_elevenlabs.ElevenLabsSpeechOptions? options,
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

final class _ElevenLabsAudioResponseSupport {
  const _ElevenLabsAudioResponseSupport();

  TTSResponse buildTextToSpeechResponse(
    Uint8List audioData, {
    required TTSRequest request,
    String? contentType,
  }) {
    return TTSResponse(
      audioData: audioData,
      contentType: contentType,
      voice: request.voice,
      model: request.model,
      duration: null,
      sampleRate: null,
      usage: null,
    );
  }

  STTResponse parseSpeechToTextResponse(
    Map<String, dynamic> responseData, {
    required STTRequest request,
  }) {
    final rawWords = responseData['words'] as List<dynamic>?;
    final words = rawWords
        ?.whereType<Map<String, dynamic>>()
        .map(_decodeWordTiming)
        .whereType<WordTiming>()
        .toList(growable: false);
    final normalizedText = words != null && words.isNotEmpty
        ? words.map((word) => word.word).join(' ')
        : responseData['text'] as String? ?? '';
    final languageProbability =
        (responseData['language_probability'] as num?)?.toDouble();

    return STTResponse(
      text: normalizedText,
      language: responseData['language_code'] as String?,
      confidence: languageProbability,
      words: words,
      model: request.model,
      duration: null,
      usage: null,
      providerMetadata: ProviderMetadata.forNamespace(
        'elevenlabs',
        {
          if (responseData['language_code'] != null)
            'languageCode': responseData['language_code'],
          if (languageProbability != null)
            'languageProbability': languageProbability,
          if (responseData['words'] != null) 'words': responseData['words'],
          if (responseData['additional_formats'] != null)
            'additionalFormats': responseData['additional_formats'],
        },
      ),
    );
  }

  List<VoiceInfo> mapVoices(List<Map<String, dynamic>> rawVoices) {
    return rawVoices.map((voice) {
      final labels = voice['labels'];
      final labelsMap = labels is Map ? labels : null;

      return VoiceInfo(
        id: voice['voice_id'] as String? ?? '',
        name: voice['name'] as String? ?? '',
        description: voice['description'] as String?,
        category: voice['category'] as String?,
        gender: labelsMap?['gender'] as String?,
        accent: labelsMap?['accent'] as String?,
        previewUrl: voice['preview_url'] as String?,
      );
    }).toList(growable: false);
  }

  WordTiming? _decodeWordTiming(Map<String, dynamic> word) {
    final text = word['text'];
    final start = word['start'];
    final end = word['end'];
    if (text is! String || start is! num || end is! num) {
      return null;
    }

    return WordTiming(
      word: text,
      start: start.toDouble(),
      end: end.toDouble(),
      confidence: (word['logprob'] as num?)?.toDouble(),
    );
  }
}
