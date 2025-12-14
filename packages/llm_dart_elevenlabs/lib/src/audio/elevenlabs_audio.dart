import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../client/elevenlabs_client.dart';
import '../config/elevenlabs_config.dart';

/// Word with timing information from ElevenLabs STT
class Word {
  final String text;
  final double start;
  final double end;
  final String? type; // 'word', 'spacing', 'punctuation'
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

/// ElevenLabs response for TTS
class ElevenLabsTTSResponse {
  final Uint8List audioData;
  final String? contentType;

  const ElevenLabsTTSResponse({required this.audioData, this.contentType});
}

/// ElevenLabs response for STT
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

/// ElevenLabs Audio capability implementation
///
/// This module handles all audio-related functionality for ElevenLabs providers,
/// including text-to-speech, speech-to-text, and streaming capabilities.
class ElevenLabsAudio extends BaseAudioCapability {
  final ElevenLabsClient client;
  final ElevenLabsConfig config;

  ElevenLabsAudio(this.client, this.config);

  // AudioCapability implementation

  @override
  Set<AudioFeature> get supportedFeatures => {
        AudioFeature.textToSpeech,
        AudioFeature.speechToText,
        AudioFeature.streamingTTS,
        AudioFeature.speakerDiarization,
        AudioFeature.characterTiming,
        AudioFeature.audioEventDetection,
        // ElevenLabs supports real-time processing
        if (config.supportsRealTimeStreaming) AudioFeature.realtimeProcessing,
        // ElevenLabs does not support audio translation
      };

  @override
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    CancellationToken? cancelToken,
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
      cancelToken: CancellationUtils.toDioCancelToken(cancelToken),
    );

    return TTSResponse(
      audioData: response.audioData,
      contentType: response.contentType,
      voice: request.voice,
      model: request.model,
      // ElevenLabs does not provide duration/sample rate in response
      duration: null,
      sampleRate: null,
      usage: null,
    );
  }

  @override
  Stream<AudioStreamEvent> textToSpeechStream(
    TTSRequest request, {
    CancellationToken? cancelToken,
  }) {
    // ElevenLabs supports streaming TTS
    // This is a simplified implementation - in practice, you would implement
    // the actual streaming API calls
    throw UnsupportedError('Streaming TTS implementation pending');
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

  @override
  List<String> getSupportedAudioFormats() {
    return config.supportedAudioFormats;
  }

  // SpeechToTextCapability implementation
  @override
  Future<STTResponse> speechToText(
    STTRequest request, {
    CancellationToken? cancelToken,
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
        cancelToken: CancellationUtils.toDioCancelToken(cancelToken),
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
        cancelToken: CancellationUtils.toDioCancelToken(cancelToken),
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
    // ElevenLabs supports multiple languages but does not provide a dynamic API
    // Return commonly supported languages
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

  /// Convert text to speech using ElevenLabs TTS (internal method)
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

      // Add optional parameters based on ElevenLabs API documentation
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

      // Build query parameters
      final queryParams = <String, String>{
        'output_format': 'mp3_44100_128',
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
        contentType: 'audio/mpeg',
      );
    } catch (e) {
      if (e is LLMError) rethrow;
      throw GenericError('Unexpected error during text-to-speech: $e');
    }
  }

  /// Convert speech to text using ElevenLabs STT (internal method)
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
      // Build form data with all supported parameters
      final formDataMap = <String, dynamic>{
        'file': MultipartFile.fromBytes(
          audioData,
          filename: 'audio.wav',
          contentType: DioMediaType('audio', 'wav'),
        ),
        'model_id': effectiveModel,
      };

      // Add optional parameters based on ElevenLabs API documentation
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

      // Build query parameters
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

      try {
        final sttResponse = ElevenLabsSTTResponse.fromJson(responseData);

        // Extract text from words if available, similar to original implementation
        if (sttResponse.words != null && sttResponse.words!.isNotEmpty) {
          final wordsText = sttResponse.words!.map((w) => w.text).join(' ');
          return ElevenLabsSTTResponse(
            text: wordsText,
            languageCode: sttResponse.languageCode,
            languageProbability: sttResponse.languageProbability,
            words: sttResponse.words,
            additionalFormats: sttResponse.additionalFormats,
          );
        }

        return sttResponse;
      } catch (e) {
        throw ResponseFormatError(
          'Failed to parse ElevenLabs STT response: $e',
          responseData.toString(),
        );
      }
    } catch (e) {
      if (e is LLMError) rethrow;
      throw GenericError('Unexpected error during speech-to-text: $e');
    }
  }

  /// Convert speech file to text using ElevenLabs STT (internal method)
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
      if (!HttpConfigUtils.isAdvancedHttpSupported) {
        throw const UnsupportedCapabilityError(
          'File-path based speech-to-text is not supported on this platform. '
          'On web, pass audio bytes via transcribe(audio) / STTRequest.fromAudio(...).',
        );
      }
      // Build form data with all supported parameters
      final formDataMap = <String, dynamic>{
        'file': await MultipartFile.fromFile(filePath),
        'model_id': effectiveModel,
      };

      // Add optional parameters based on ElevenLabs API documentation
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

      final responseData = await client.postFormData(
        'speech-to-text',
        formData,
        cancelToken: cancelToken,
      );

      try {
        final sttResponse = ElevenLabsSTTResponse.fromJson(responseData);

        // Extract text from words if available, similar to original implementation
        if (sttResponse.words != null && sttResponse.words!.isNotEmpty) {
          final wordsText = sttResponse.words!.map((w) => w.text).join(' ');
          return ElevenLabsSTTResponse(
            text: wordsText,
            languageCode: sttResponse.languageCode,
            languageProbability: sttResponse.languageProbability,
            words: sttResponse.words,
            additionalFormats: sttResponse.additionalFormats,
          );
        }

        return sttResponse;
      } catch (e) {
        throw ResponseFormatError(
          'Failed to parse ElevenLabs STT response: $e',
          responseData.toString(),
        );
      }
    } catch (e) {
      if (e is LLMError) rethrow;
      throw GenericError(
          'Unexpected error during speech-to-text from file: $e');
    }
  }

  /// Get available voices (internal method)
  Future<List<Map<String, dynamic>>> _getVoicesRaw() async {
    final responseData = await client.getJson('voices');
    final voices = responseData['voices'] as List<dynamic>? ?? [];
    return voices.cast<Map<String, dynamic>>();
  }

  @override
  Future<STTResponse> translateAudio(
    AudioTranslationRequest request, {
    CancellationToken? cancelToken,
  }) {
    // ElevenLabs does not support audio translation
    throw UnsupportedError('ElevenLabs does not support audio translation');
  }

  @override
  Future<RealtimeAudioSession> startRealtimeSession(
      RealtimeAudioConfig config) {
    // ElevenLabs supports real-time audio processing
    // This would need to be implemented based on their WebSocket API
    throw UnsupportedError('Real-time audio session implementation pending');
  }
}
