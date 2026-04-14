import 'dart:typed_data';

import 'package:llm_dart_transport/dio.dart';

import '../../../../models/audio_models.dart';
import '../../../../providers/elevenlabs/config.dart';

/// Provider-local request and response shaping for ElevenLabs audio compatibility.
final class ElevenLabsAudioSupport {
  const ElevenLabsAudioSupport();

  static const List<LanguageInfo> supportedLanguages = [
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

  Map<String, dynamic> buildTextToSpeechRequestBody(
    TTSRequest request, {
    required ElevenLabsConfig config,
    required String effectiveModel,
  }) {
    final requestBody = <String, dynamic>{
      'text': request.text,
      'model_id': effectiveModel,
      'voice_settings': config.voiceSettings,
      'apply_text_normalization': request.textNormalization.name,
    };

    if (request.languageCode != null) {
      requestBody['language_code'] = request.languageCode;
    }
    if (request.seed != null) {
      requestBody['seed'] = request.seed;
    }
    if (request.previousText != null) {
      requestBody['previous_text'] = request.previousText;
    }
    if (request.nextText != null) {
      requestBody['next_text'] = request.nextText;
    }
    if (request.previousRequestIds != null &&
        request.previousRequestIds!.isNotEmpty) {
      requestBody['previous_request_ids'] =
          request.previousRequestIds!.take(3).toList();
    }
    if (request.nextRequestIds != null && request.nextRequestIds!.isNotEmpty) {
      requestBody['next_request_ids'] =
          request.nextRequestIds!.take(3).toList();
    }

    return requestBody;
  }

  Map<String, String> buildTextToSpeechQueryParams(TTSRequest request) {
    final queryParams = <String, String>{
      'output_format': 'mp3_44100_128',
      'enable_logging': request.enableLogging.toString(),
    };
    if (request.optimizeStreamingLatency != null) {
      queryParams['optimize_streaming_latency'] =
          request.optimizeStreamingLatency.toString();
    }
    return queryParams;
  }

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

  Map<String, String>? buildSpeechToTextQueryParams(STTRequest request) {
    if (!request.enableLogging) {
      return const {'enable_logging': 'false'};
    }
    return null;
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
      languageProbability: languageProbability,
      additionalFormats:
          responseData['additional_formats'] as Map<String, dynamic>?,
    );
  }

  List<VoiceInfo> mapVoices(List<Map<String, dynamic>> rawVoices) {
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
    }).toList(growable: false);
  }

  Map<String, dynamic> _buildSpeechToTextFieldMap({
    required STTRequest request,
    required String effectiveModel,
    required MultipartFile file,
  }) {
    final fields = <String, dynamic>{
      'file': file,
      'model_id': effectiveModel,
      'tag_audio_events': request.tagAudioEvents.toString(),
      'timestamps_granularity': request.timestampGranularity.name,
      'diarize': request.diarize.toString(),
    };

    if (request.language != null) {
      fields['language_code'] = request.language;
    }
    if (request.numSpeakers != null) {
      fields['num_speakers'] = request.numSpeakers.toString();
    }
    if (request.format != null) {
      fields['file_format'] = request.format;
    }

    return fields;
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
