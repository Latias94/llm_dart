import 'dart:convert';

import 'package:dio/dio.dart' hide CancelToken;

import 'package:llm_dart_core/llm_dart_core.dart';
import 'client.dart';
import 'config.dart';
import '../defaults.dart';

/// OpenAI Audio capabilities implementation
///
/// This module handles text-to-speech, speech-to-text, and audio translation
/// functionality for OpenAI providers.
class OpenAIAudio
    implements
        TextToSpeechCapability,
        TextToSpeechCallOptionsCapability,
        VoiceListingCapability,
        SpeechToTextCapability,
        SpeechToTextCallOptionsCapability,
        AudioTranslationCapability,
        AudioTranslationCallOptionsCapability,
        TranscriptionLanguageListingCapability {
  final OpenAIClient client;
  final OpenAIConfig config;

  OpenAIAudio(this.client, this.config);

  Map<String, dynamic> _buildProviderMetadata(
    String endpoint, {
    required String capability,
    required String model,
  }) {
    final payload = <String, dynamic>{
      'model': model,
      'endpoint': endpoint,
    };
    return {
      config.providerId: payload,
      '${config.providerId}.$capability': payload,
    };
  }

  @override
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    CancelToken? cancelToken,
  }) async {
    return textToSpeechWithCallOptions(
      request,
      callOptions: const LLMCallOptions(),
      cancelToken: cancelToken,
    );
  }

  @override
  Future<TTSResponse> textToSpeechWithCallOptions(
    TTSRequest request, {
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async {
    // Basic validation - let the provider handle specific limits
    if (request.text.isEmpty) {
      throw const InvalidRequestError('Text input cannot be empty');
    }

    final modelUsed = request.model ?? openaiDefaultTTSModel;
    var requestBody = <String, dynamic>{
      'model': modelUsed,
      'input': request.text,
      'voice': request.voice ?? openaiDefaultVoice,
      if (request.format != null) 'response_format': request.format,
      if (request.speed != null) 'speed': request.speed,
    };

    requestBody = callOptions.mergeIntoRequestBody(requestBody);

    final audioData = await client.postRawWithHeaders(
      'audio/speech',
      requestBody,
      headers: callOptions.headers,
      cancelToken: cancelToken,
    );

    // Determine content type based on format
    String contentType = 'audio/mpeg'; // Default for mp3
    if (request.format != null) {
      switch (request.format!.toLowerCase()) {
        case 'mp3':
          contentType = 'audio/mpeg';
          break;
        case 'opus':
          contentType = 'audio/opus';
          break;
        case 'aac':
          contentType = 'audio/aac';
          break;
        case 'flac':
          contentType = 'audio/flac';
          break;
        case 'wav':
          contentType = 'audio/wav';
          break;
        case 'pcm':
          contentType = 'audio/pcm';
          break;
        default:
          contentType = 'audio/mpeg';
      }
    }

    return TTSResponse(
      audioData: audioData,
      contentType: contentType,
      voice: request.voice,
      model: modelUsed,
      duration: null, // OpenAI doesn't provide duration
      sampleRate: null, // OpenAI doesn't provide sample rate
      usage: null,
      providerMetadata: _buildProviderMetadata(
        'audio/speech',
        capability: 'speech',
        model: modelUsed,
      ),
    );
  }

  @override
  Future<List<VoiceInfo>> getVoices() async {
    // OpenAI has predefined voices
    // Reference: https://platform.openai.com/docs/guides/text-to-speech/voice-options
    return const [
      VoiceInfo(id: 'alloy', name: 'Alloy', description: 'Neutral voice'),
      VoiceInfo(id: 'ash', name: 'Ash', description: 'Expressive voice'),
      VoiceInfo(id: 'ballad', name: 'Ballad', description: 'Melodic voice'),
      VoiceInfo(id: 'coral', name: 'Coral', description: 'Warm voice'),
      VoiceInfo(id: 'echo', name: 'Echo', description: 'Male voice'),
      VoiceInfo(id: 'fable', name: 'Fable', description: 'British accent'),
      VoiceInfo(id: 'nova', name: 'Nova', description: 'Female voice'),
      VoiceInfo(id: 'onyx', name: 'Onyx', description: 'Deep male voice'),
      VoiceInfo(id: 'sage', name: 'Sage', description: 'Wise voice'),
      VoiceInfo(
        id: 'shimmer',
        name: 'Shimmer',
        description: 'Soft female voice',
      ),
      VoiceInfo(id: 'verse', name: 'Verse', description: 'Poetic voice'),
    ];
  }

  @override
  Future<STTResponse> speechToText(
    STTRequest request, {
    CancelToken? cancelToken,
  }) async {
    return speechToTextWithCallOptions(
      request,
      callOptions: const LLMCallOptions(),
      cancelToken: cancelToken,
    );
  }

  @override
  Future<STTResponse> speechToTextWithCallOptions(
    STTRequest request, {
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async {
    // Basic validation - let the provider handle specific limits
    if (request.audioData == null && request.filePath == null) {
      throw const InvalidRequestError(
        'Either audioData or filePath must be provided',
      );
    }

    final modelUsed = request.model ?? openaiDefaultSTTModel;
    final baseFields = <String, dynamic>{
      'model': modelUsed,
      if (request.language != null) 'language': request.language,
      if (request.prompt != null) 'prompt': request.prompt,
      if (request.responseFormat != null) 'response_format': request.responseFormat,
      if (request.temperature != null) 'temperature': request.temperature,
    };

    final derivedGranularities = <String>[];
    if (request.includeWordTiming ||
        request.timestampGranularity == TimestampGranularity.word) {
      derivedGranularities.add('word');
    }
    if (request.timestampGranularity == TimestampGranularity.segment) {
      derivedGranularities.add('segment');
    }

    final formData = await _buildSttFormData(
      audioData: request.audioData,
      filePath: request.filePath,
      filename: 'audio.${request.format ?? 'wav'}',
      fields: baseFields,
      derivedTimestampGranularities: derivedGranularities,
      callOptions: callOptions,
    );

    final responseData = await client.postFormWithHeaders(
      'audio/transcriptions',
      formData,
      headers: callOptions.headers,
      cancelToken: cancelToken,
    );

    // Parse word timing if available
    List<WordTiming>? words;
    if ((request.includeWordTiming ||
            request.timestampGranularity == TimestampGranularity.word) &&
        responseData['words'] != null) {
      final wordsData = responseData['words'] as List;
      words = wordsData.map((w) {
        final wordMap = w as Map<String, dynamic>;
        return WordTiming(
          word: wordMap['word'] as String,
          start: (wordMap['start'] as num).toDouble(),
          end: (wordMap['end'] as num).toDouble(),
          confidence: null, // OpenAI doesn't provide word-level confidence
        );
      }).toList();
    }

    return STTResponse(
      text: responseData['text'] as String,
      language: responseData['language'] as String?,
      confidence: null, // OpenAI doesn't provide overall confidence
      words: words,
      model: modelUsed,
      duration: responseData['duration'] as double?,
      usage: null,
      providerMetadata: _buildProviderMetadata(
        'audio/transcriptions',
        capability: 'transcription',
        model: modelUsed,
      ),
    );
  }

  @override
  Future<List<LanguageInfo>> getSupportedLanguages() async {
    // OpenAI Whisper supports many languages
    return const [
      LanguageInfo(code: 'en', name: 'English'),
      LanguageInfo(code: 'zh', name: 'Chinese'),
      LanguageInfo(code: 'de', name: 'German'),
      LanguageInfo(code: 'es', name: 'Spanish'),
      LanguageInfo(code: 'ru', name: 'Russian'),
      LanguageInfo(code: 'ko', name: 'Korean'),
      LanguageInfo(code: 'fr', name: 'French'),
      LanguageInfo(code: 'ja', name: 'Japanese'),
      LanguageInfo(code: 'pt', name: 'Portuguese'),
      LanguageInfo(code: 'tr', name: 'Turkish'),
      LanguageInfo(code: 'pl', name: 'Polish'),
      LanguageInfo(code: 'ca', name: 'Catalan'),
      LanguageInfo(code: 'nl', name: 'Dutch'),
      LanguageInfo(code: 'ar', name: 'Arabic'),
      LanguageInfo(code: 'sv', name: 'Swedish'),
      LanguageInfo(code: 'it', name: 'Italian'),
      LanguageInfo(code: 'id', name: 'Indonesian'),
      LanguageInfo(code: 'hi', name: 'Hindi'),
      LanguageInfo(code: 'fi', name: 'Finnish'),
      LanguageInfo(code: 'vi', name: 'Vietnamese'),
      LanguageInfo(code: 'he', name: 'Hebrew'),
      LanguageInfo(code: 'uk', name: 'Ukrainian'),
      LanguageInfo(code: 'el', name: 'Greek'),
      LanguageInfo(code: 'ms', name: 'Malay'),
      LanguageInfo(code: 'cs', name: 'Czech'),
      LanguageInfo(code: 'ro', name: 'Romanian'),
      LanguageInfo(code: 'da', name: 'Danish'),
      LanguageInfo(code: 'hu', name: 'Hungarian'),
      LanguageInfo(code: 'ta', name: 'Tamil'),
      LanguageInfo(code: 'no', name: 'Norwegian'),
      LanguageInfo(code: 'th', name: 'Thai'),
      LanguageInfo(code: 'ur', name: 'Urdu'),
      LanguageInfo(code: 'hr', name: 'Croatian'),
      LanguageInfo(code: 'bg', name: 'Bulgarian'),
      LanguageInfo(code: 'lt', name: 'Lithuanian'),
      LanguageInfo(code: 'la', name: 'Latin'),
      LanguageInfo(code: 'mi', name: 'Maori'),
      LanguageInfo(code: 'ml', name: 'Malayalam'),
      LanguageInfo(code: 'cy', name: 'Welsh'),
      LanguageInfo(code: 'sk', name: 'Slovak'),
      LanguageInfo(code: 'te', name: 'Telugu'),
      LanguageInfo(code: 'fa', name: 'Persian'),
      LanguageInfo(code: 'lv', name: 'Latvian'),
      LanguageInfo(code: 'bn', name: 'Bengali'),
      LanguageInfo(code: 'sr', name: 'Serbian'),
      LanguageInfo(code: 'az', name: 'Azerbaijani'),
      LanguageInfo(code: 'sl', name: 'Slovenian'),
      LanguageInfo(code: 'kn', name: 'Kannada'),
      LanguageInfo(code: 'et', name: 'Estonian'),
      LanguageInfo(code: 'mk', name: 'Macedonian'),
      LanguageInfo(code: 'br', name: 'Breton'),
      LanguageInfo(code: 'eu', name: 'Basque'),
      LanguageInfo(code: 'is', name: 'Icelandic'),
      LanguageInfo(code: 'hy', name: 'Armenian'),
      LanguageInfo(code: 'ne', name: 'Nepali'),
      LanguageInfo(code: 'mn', name: 'Mongolian'),
      LanguageInfo(code: 'bs', name: 'Bosnian'),
      LanguageInfo(code: 'kk', name: 'Kazakh'),
      LanguageInfo(code: 'sq', name: 'Albanian'),
      LanguageInfo(code: 'sw', name: 'Swahili'),
      LanguageInfo(code: 'gl', name: 'Galician'),
      LanguageInfo(code: 'mr', name: 'Marathi'),
      LanguageInfo(code: 'pa', name: 'Punjabi'),
      LanguageInfo(code: 'si', name: 'Sinhala'),
      LanguageInfo(code: 'km', name: 'Khmer'),
      LanguageInfo(code: 'sn', name: 'Shona'),
      LanguageInfo(code: 'yo', name: 'Yoruba'),
      LanguageInfo(code: 'so', name: 'Somali'),
      LanguageInfo(code: 'af', name: 'Afrikaans'),
      LanguageInfo(code: 'oc', name: 'Occitan'),
      LanguageInfo(code: 'ka', name: 'Georgian'),
      LanguageInfo(code: 'be', name: 'Belarusian'),
      LanguageInfo(code: 'tg', name: 'Tajik'),
      LanguageInfo(code: 'sd', name: 'Sindhi'),
      LanguageInfo(code: 'gu', name: 'Gujarati'),
      LanguageInfo(code: 'am', name: 'Amharic'),
      LanguageInfo(code: 'yi', name: 'Yiddish'),
      LanguageInfo(code: 'lo', name: 'Lao'),
      LanguageInfo(code: 'uz', name: 'Uzbek'),
      LanguageInfo(code: 'fo', name: 'Faroese'),
      LanguageInfo(code: 'ht', name: 'Haitian Creole'),
      LanguageInfo(code: 'ps', name: 'Pashto'),
      LanguageInfo(code: 'tk', name: 'Turkmen'),
      LanguageInfo(code: 'nn', name: 'Nynorsk'),
      LanguageInfo(code: 'mt', name: 'Maltese'),
      LanguageInfo(code: 'sa', name: 'Sanskrit'),
      LanguageInfo(code: 'lb', name: 'Luxembourgish'),
      LanguageInfo(code: 'my', name: 'Myanmar'),
      LanguageInfo(code: 'bo', name: 'Tibetan'),
      LanguageInfo(code: 'tl', name: 'Tagalog'),
      LanguageInfo(code: 'mg', name: 'Malagasy'),
      LanguageInfo(code: 'as', name: 'Assamese'),
      LanguageInfo(code: 'tt', name: 'Tatar'),
      LanguageInfo(code: 'haw', name: 'Hawaiian'),
      LanguageInfo(code: 'ln', name: 'Lingala'),
      LanguageInfo(code: 'ha', name: 'Hausa'),
      LanguageInfo(code: 'ba', name: 'Bashkir'),
      LanguageInfo(code: 'jw', name: 'Javanese'),
      LanguageInfo(code: 'su', name: 'Sundanese'),
    ];
  }

  @override
  Future<STTResponse> translateAudio(
    AudioTranslationRequest request, {
    CancelToken? cancelToken,
  }) async {
    return translateAudioWithCallOptions(
      request,
      callOptions: const LLMCallOptions(),
      cancelToken: cancelToken,
    );
  }

  @override
  Future<STTResponse> translateAudioWithCallOptions(
    AudioTranslationRequest request, {
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async {
    if (request.audioData == null && request.filePath == null) {
      throw const InvalidRequestError(
        'Either audioData or filePath must be provided',
      );
    }

    final modelUsed = request.model ?? openaiDefaultSTTModel;
    final baseFields = <String, dynamic>{
      'model': modelUsed,
      if (request.prompt != null) 'prompt': request.prompt,
      if (request.responseFormat != null) 'response_format': request.responseFormat,
      if (request.temperature != null) 'temperature': request.temperature,
    };

    final formData = await _buildSttFormData(
      audioData: request.audioData,
      filePath: request.filePath,
      filename: 'audio.${request.format ?? 'wav'}',
      fields: baseFields,
      derivedTimestampGranularities: const <String>[],
      callOptions: callOptions,
    );

    final responseData = await client.postFormWithHeaders(
      'audio/translations',
      formData,
      headers: callOptions.headers,
      cancelToken: cancelToken,
    );

    return STTResponse(
      text: responseData['text'] as String,
      language: 'en',
      confidence: null,
      words: null,
      model: modelUsed,
      duration: responseData['duration'] as double?,
      usage: null,
      providerMetadata: _buildProviderMetadata(
        'audio/translations',
        capability: 'translation',
        model: modelUsed,
      ),
    );
  }

  Future<FormData> _buildSttFormData({
    required List<int>? audioData,
    required String? filePath,
    required String filename,
    required Map<String, dynamic> fields,
    required List<String> derivedTimestampGranularities,
    required LLMCallOptions callOptions,
  }) async {
    final mergedFields = callOptions.mergeIntoRequestBody(fields);

    // Allow overrides via callOptions.body:
    // - `timestamp_granularities[]`: list of strings (preferred)
    // - `timestamp_granularities`: list of strings (fallback)
    List<String> granularities = derivedTimestampGranularities;
    final raw1 = mergedFields.remove('timestamp_granularities[]');
    final raw2 = mergedFields.remove('timestamp_granularities');
    final fromOverride = raw1 ?? raw2;
    if (fromOverride is List) {
      final items =
          fromOverride.whereType<Object>().map((e) => e.toString()).toList();
      if (items.isNotEmpty) granularities = items;
    }

    final formData = FormData();

    if (audioData != null) {
      formData.files.add(
        MapEntry(
          'file',
          MultipartFile.fromBytes(audioData, filename: filename),
        ),
      );
    } else if (filePath != null) {
      formData.files.add(
        MapEntry('file', await MultipartFile.fromFile(filePath)),
      );
    }

    for (final entry in mergedFields.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value == null) continue;
      if (value is String || value is num || value is bool) {
        formData.fields.add(MapEntry(key, value.toString()));
      } else {
        formData.fields.add(MapEntry(key, jsonEncode(value)));
      }
    }

    for (final granularity in granularities) {
      formData.fields.add(MapEntry('timestamp_granularities[]', granularity));
    }

    return formData;
  }
}
