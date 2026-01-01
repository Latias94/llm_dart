import 'dart:typed_data';

import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_core/core/capability.dart';
import 'package:llm_dart_core/core/cancellation.dart';
import 'package:llm_dart_core/core/llm_error.dart';
import 'package:llm_dart_core/models/audio_models.dart';

import 'client.dart';
import 'config.dart';

class Word {
  final String text;
  final double start;
  final double end;
  final String? type;
  final double? logprob;
  final String? speakerId;

  const Word({
    required this.text,
    required this.start,
    required this.end,
    this.type,
    this.logprob,
    this.speakerId,
  });

  factory Word.fromJson(Map<String, dynamic> json) => Word(
        text: json['text'] as String,
        start: (json['start'] as num?)?.toDouble() ?? 0.0,
        end: (json['end'] as num?)?.toDouble() ?? 0.0,
        type: json['type'] as String?,
        logprob: (json['logprob'] as num?)?.toDouble(),
        speakerId: json['speaker_id'] as String?,
      );
}

class ElevenLabsTTSResponse {
  final Uint8List audioData;
  final String? contentType;

  const ElevenLabsTTSResponse({required this.audioData, this.contentType});
}

class ElevenLabsSTTResponse {
  final String text;
  final String? languageCode;
  final double? languageProbability;
  final List<Word>? words;
  final Map<String, dynamic>? additionalFormats;

  const ElevenLabsSTTResponse({
    required this.text,
    this.languageCode,
    this.languageProbability,
    this.words,
    this.additionalFormats,
  });

  factory ElevenLabsSTTResponse.fromJson(Map<String, dynamic> json) {
    final wordsJson = json['words'] as List<dynamic>?;
    final words = wordsJson
        ?.map((w) => Word.fromJson(w as Map<String, dynamic>))
        .toList();

    return ElevenLabsSTTResponse(
      text: json['text'] as String? ?? '',
      languageCode: json['language_code'] as String?,
      languageProbability: (json['language_probability'] as num?)?.toDouble(),
      words: words,
      additionalFormats: json['additional_formats'] as Map<String, dynamic>?,
    );
  }
}

class ElevenLabsAudio
    implements
        TextToSpeechCapability,
        StreamingTextToSpeechCapability,
        VoiceListingCapability,
        SpeechToTextCapability,
        TranscriptionLanguageListingCapability {
  final ElevenLabsClient client;
  final ElevenLabsConfig config;

  ElevenLabsAudio(this.client, this.config);

  @override
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    CancelToken? cancelToken,
  }) async {
    final response = await _textToSpeechInternal(
      request.text,
      voiceId: request.voice,
      model: request.model,
      languageCode: request.languageCode,
      seed: request.seed,
      previousText: request.previousText,
      nextText: request.nextText,
      previousRequestIds: request.previousRequestIds,
      nextRequestIds: request.nextRequestIds,
      textNormalization: request.textNormalization.name,
      enableLogging: request.enableLogging,
      optimizeStreamingLatency: request.optimizeStreamingLatency,
      outputFormat: _resolveOutputFormat(request),
      cancelToken: cancelToken,
    );

    return TTSResponse(
      audioData: response.audioData,
      contentType: response.contentType,
      voice: request.voice,
      model: request.model,
      duration: null,
      sampleRate: null,
      usage: null,
    );
  }

  @override
  Stream<AudioStreamEvent> textToSpeechStream(
    TTSRequest request, {
    CancelToken? cancelToken,
  }) async* {
    if (config.apiKey.isEmpty) {
      throw const AuthError('Missing ElevenLabs API key');
    }

    final effectiveVoiceId = request.voice ?? config.defaultVoiceId;
    final effectiveModel = request.model ?? config.defaultTTSModel;
    final outputFormat = _resolveOutputFormat(request);

    final requestBody = <String, dynamic>{
      'text': request.text,
      'model_id': effectiveModel,
      'voice_settings': {
        ...config.voiceSettings,
        if (request.stability != null) 'stability': request.stability,
        if (request.similarityBoost != null)
          'similarity_boost': request.similarityBoost,
        if (request.style != null) 'style': request.style,
        if (request.useSpeakerBoost != null)
          'use_speaker_boost': request.useSpeakerBoost,
      },
      if (request.languageCode != null) 'language_code': request.languageCode,
      if (request.seed != null) 'seed': request.seed,
      if (request.previousText != null) 'previous_text': request.previousText,
      if (request.nextText != null) 'next_text': request.nextText,
      if (request.previousRequestIds != null &&
          request.previousRequestIds!.isNotEmpty)
        'previous_request_ids': request.previousRequestIds!.take(3).toList(),
      if (request.nextRequestIds != null && request.nextRequestIds!.isNotEmpty)
        'next_request_ids': request.nextRequestIds!.take(3).toList(),
      'apply_text_normalization': request.textNormalization.name,
    };

    final queryParams = <String, String>{
      'output_format': outputFormat,
      'enable_logging': request.enableLogging.toString(),
      if (request.optimizeStreamingLatency != null)
        'optimize_streaming_latency':
            request.optimizeStreamingLatency.toString(),
    };

    final response = await client.postStream(
      'text-to-speech/$effectiveVoiceId/stream',
      requestBody,
      queryParams: queryParams,
      cancelToken: cancelToken,
    );

    final contentType = response.headers.value('content-type');
    yield AudioMetadataEvent(
      contentType: contentType,
      sampleRate: _inferSampleRateFromOutputFormat(outputFormat),
    );

    final body = response.data;
    if (body == null) return;

    List<int>? previous;
    await for (final chunk in body.stream) {
      if (previous != null && previous.isNotEmpty) {
        yield AudioDataEvent(data: previous);
      }
      previous = chunk;
    }

    if (previous != null) {
      yield AudioDataEvent(data: previous, isFinal: true);
    }
  }

  @override
  Future<List<VoiceInfo>> getVoices() async {
    final rawVoices = await _getVoicesRaw();

    return rawVoices.map((voice) {
      return VoiceInfo(
        id: voice['voice_id'] as String? ?? '',
        name: voice['name'] as String? ?? '',
        description: voice['description'] as String?,
        category: voice['category'] as String?,
        gender: voice['labels']?['gender'] as String?,
        accent: voice['labels']?['accent'] as String?,
        previewUrl: voice['preview_url'] as String?,
      );
    }).toList();
  }

  List<String> getSupportedAudioFormats() {
    return config.supportedAudioFormats;
  }

  @override
  Future<STTResponse> speechToText(
    STTRequest request, {
    CancelToken? cancelToken,
  }) async {
    late ElevenLabsSTTResponse response;

    if (request.audioData != null) {
      response = await _speechToTextInternal(
        Uint8List.fromList(request.audioData!),
        model: request.model,
        languageCode: request.language,
        tagAudioEvents: request.tagAudioEvents,
        numSpeakers: request.numSpeakers,
        timestampsGranularity: request.timestampGranularity.name,
        diarize: request.diarize,
        fileFormat: request.format,
        enableLogging: request.enableLogging,
        cancelToken: cancelToken,
      );
    } else if (request.filePath != null) {
      response = await _speechToTextFromFileInternal(
        request.filePath!,
        model: request.model,
        languageCode: request.language,
        tagAudioEvents: request.tagAudioEvents,
        numSpeakers: request.numSpeakers,
        timestampsGranularity: request.timestampGranularity.name,
        diarize: request.diarize,
        fileFormat: request.format,
        enableLogging: request.enableLogging,
        cancelToken: cancelToken,
      );
    } else {
      throw const InvalidRequestError(
          'Either audioData or filePath must be provided');
    }

    return STTResponse(
      text: response.text,
      language: response.languageCode,
      confidence: response.languageProbability,
      words: response.words
          ?.map((w) => WordTiming(
                word: w.text,
                start: w.start,
                end: w.end,
                confidence: null,
              ))
          .toList(),
      model: request.model,
      duration: null,
      usage: null,
      additionalFormats: response.additionalFormats,
    );
  }

  @override
  Future<List<LanguageInfo>> getSupportedLanguages() async {
    return const [
      LanguageInfo(code: 'en', name: 'English', supportsRealtime: true),
      LanguageInfo(code: 'es', name: 'Spanish', supportsRealtime: true),
      LanguageInfo(code: 'fr', name: 'French', supportsRealtime: true),
      LanguageInfo(code: 'de', name: 'German', supportsRealtime: true),
      LanguageInfo(code: 'it', name: 'Italian', supportsRealtime: true),
      LanguageInfo(code: 'pt', name: 'Portuguese', supportsRealtime: true),
      LanguageInfo(code: 'pl', name: 'Polish', supportsRealtime: true),
      LanguageInfo(code: 'tr', name: 'Turkish', supportsRealtime: true),
      LanguageInfo(code: 'ru', name: 'Russian', supportsRealtime: true),
      LanguageInfo(code: 'nl', name: 'Dutch', supportsRealtime: true),
      LanguageInfo(code: 'cs', name: 'Czech', supportsRealtime: true),
      LanguageInfo(code: 'ar', name: 'Arabic', supportsRealtime: true),
      LanguageInfo(code: 'zh', name: 'Chinese', supportsRealtime: true),
      LanguageInfo(code: 'ja', name: 'Japanese', supportsRealtime: true),
      LanguageInfo(code: 'hi', name: 'Hindi', supportsRealtime: true),
      LanguageInfo(code: 'ko', name: 'Korean', supportsRealtime: true),
    ];
  }

  Future<ElevenLabsTTSResponse> _textToSpeechInternal(
    String text, {
    String? voiceId,
    String? model,
    String? languageCode,
    int? seed,
    String? previousText,
    String? nextText,
    List<String>? previousRequestIds,
    List<String>? nextRequestIds,
    String? textNormalization,
    bool? enableLogging,
    int? optimizeStreamingLatency,
    required String outputFormat,
    CancelToken? cancelToken,
  }) async {
    if (config.apiKey.isEmpty) {
      throw const AuthError('Missing ElevenLabs API key');
    }

    final effectiveVoiceId = voiceId ?? config.defaultVoiceId;
    final effectiveModel = model ?? config.defaultTTSModel;

    client.logger.info(
      'Converting text to speech with voice: $effectiveVoiceId, model: $effectiveModel',
    );

    try {
      final requestBody = <String, dynamic>{
        'text': text,
        'model_id': effectiveModel,
        'voice_settings': config.voiceSettings,
      };

      if (languageCode != null) requestBody['language_code'] = languageCode;
      if (seed != null) requestBody['seed'] = seed;
      if (previousText != null) requestBody['previous_text'] = previousText;
      if (nextText != null) requestBody['next_text'] = nextText;
      if (previousRequestIds != null && previousRequestIds.isNotEmpty) {
        requestBody['previous_request_ids'] =
            previousRequestIds.take(3).toList();
      }
      if (nextRequestIds != null && nextRequestIds.isNotEmpty) {
        requestBody['next_request_ids'] = nextRequestIds.take(3).toList();
      }
      if (textNormalization != null) {
        requestBody['apply_text_normalization'] = textNormalization;
      }

      final queryParams = <String, String>{
        'output_format': outputFormat,
      };
      if (enableLogging != null) {
        queryParams['enable_logging'] = enableLogging.toString();
      }
      if (optimizeStreamingLatency != null) {
        queryParams['optimize_streaming_latency'] =
            optimizeStreamingLatency.toString();
      }

      final audioData = await client.postBinary(
        'text-to-speech/$effectiveVoiceId',
        requestBody,
        queryParams: queryParams,
        cancelToken: cancelToken,
      );

      return ElevenLabsTTSResponse(
        audioData: audioData,
        contentType: _inferContentTypeFromOutputFormat(outputFormat),
      );
    } catch (e) {
      if (e is LLMError) rethrow;
      throw GenericError('Unexpected error during text-to-speech: $e');
    }
  }

  Future<ElevenLabsSTTResponse> _speechToTextInternal(
    Uint8List audioData, {
    String? model,
    String? languageCode,
    bool? tagAudioEvents,
    int? numSpeakers,
    String? timestampsGranularity,
    bool? diarize,
    String? fileFormat,
    bool? enableLogging,
    CancelToken? cancelToken,
  }) async {
    if (config.apiKey.isEmpty) {
      throw const AuthError('Missing ElevenLabs API key');
    }

    final effectiveModel = model ?? config.defaultSTTModel;

    client.logger.info('Converting speech to text with model: $effectiveModel');

    try {
      final formDataMap = <String, dynamic>{
        'file': MultipartFile.fromBytes(
          audioData,
          filename: 'audio.wav',
          contentType: DioMediaType('audio', 'wav'),
        ),
        'model_id': effectiveModel,
      };

      if (languageCode != null) formDataMap['language_code'] = languageCode;
      if (tagAudioEvents != null) {
        formDataMap['tag_audio_events'] = tagAudioEvents.toString();
      }
      if (numSpeakers != null) {
        formDataMap['num_speakers'] = numSpeakers.toString();
      }
      if (timestampsGranularity != null) {
        formDataMap['timestamps_granularity'] = timestampsGranularity;
      }
      if (diarize != null) formDataMap['diarize'] = diarize.toString();
      if (fileFormat != null) formDataMap['file_format'] = fileFormat;

      final formData = FormData.fromMap(formDataMap);

      final queryParams = <String, String>{};
      if (enableLogging != null) {
        queryParams['enable_logging'] = enableLogging.toString();
      }

      final responseData = await client.postFormData(
        'speech-to-text',
        formData,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
        cancelToken: cancelToken,
      );

      return ElevenLabsSTTResponse.fromJson(responseData);
    } catch (e) {
      if (e is LLMError) rethrow;
      throw GenericError('Unexpected error during speech-to-text: $e');
    }
  }

  Future<ElevenLabsSTTResponse> _speechToTextFromFileInternal(
    String filePath, {
    String? model,
    String? languageCode,
    bool? tagAudioEvents,
    int? numSpeakers,
    String? timestampsGranularity,
    bool? diarize,
    String? fileFormat,
    bool? enableLogging,
    CancelToken? cancelToken,
  }) async {
    if (config.apiKey.isEmpty) {
      throw const AuthError('Missing ElevenLabs API key');
    }

    final effectiveModel = model ?? config.defaultSTTModel;

    client.logger.info(
      'Converting speech file to text: $filePath, model: $effectiveModel',
    );

    try {
      final formDataMap = <String, dynamic>{
        'file': await MultipartFile.fromFile(filePath),
        'model_id': effectiveModel,
      };

      if (languageCode != null) formDataMap['language_code'] = languageCode;
      if (tagAudioEvents != null) {
        formDataMap['tag_audio_events'] = tagAudioEvents.toString();
      }
      if (numSpeakers != null) {
        formDataMap['num_speakers'] = numSpeakers.toString();
      }
      if (timestampsGranularity != null) {
        formDataMap['timestamps_granularity'] = timestampsGranularity;
      }
      if (diarize != null) formDataMap['diarize'] = diarize.toString();
      if (fileFormat != null) formDataMap['file_format'] = fileFormat;

      final formData = FormData.fromMap(formDataMap);

      final queryParams = <String, String>{};
      if (enableLogging != null) {
        queryParams['enable_logging'] = enableLogging.toString();
      }

      final responseData = await client.postFormData(
        'speech-to-text',
        formData,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
        cancelToken: cancelToken,
      );

      return ElevenLabsSTTResponse.fromJson(responseData);
    } catch (e) {
      if (e is LLMError) rethrow;
      throw GenericError(
          'Unexpected error during speech-to-text from file: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getVoicesRaw() async {
    final responseData = await client.getJson('voices');
    final voices = responseData['voices'] as List<dynamic>? ?? [];
    return voices.cast<Map<String, dynamic>>();
  }
}

String _resolveOutputFormat(TTSRequest request) {
  final raw = request.format;
  if (raw != null && raw.isNotEmpty) {
    // Support passing ElevenLabs-native output_format directly.
    if (raw.contains('_') || raw.toLowerCase().startsWith('ulaw')) {
      return raw;
    }

    final lower = raw.toLowerCase();
    if (lower == 'mp3') {
      final quality = request.quality?.toLowerCase();
      if (quality == 'high' || quality == 'ultra') return 'mp3_44100_192';
      return 'mp3_44100_128';
    }
    if (lower == 'pcm') {
      final sr = request.sampleRate;
      return switch (sr) {
        16000 => 'pcm_16000',
        22050 => 'pcm_22050',
        24000 => 'pcm_24000',
        44100 => 'pcm_44100',
        _ => 'pcm_16000',
      };
    }
  }

  return 'mp3_44100_128';
}

int? _inferSampleRateFromOutputFormat(String outputFormat) {
  final parts = outputFormat.split('_');
  if (parts.length < 2) return null;
  final rate = int.tryParse(parts[1]);
  return rate;
}

String? _inferContentTypeFromOutputFormat(String outputFormat) {
  if (outputFormat.startsWith('mp3')) return 'audio/mpeg';
  if (outputFormat.startsWith('pcm')) return 'audio/wav';
  if (outputFormat.startsWith('ulaw')) return 'audio/basic';
  return null;
}
