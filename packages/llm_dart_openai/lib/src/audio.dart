import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

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
        VoiceListingCapability,
        SpeechToTextCapability,
        AudioTranslationCapability,
        TranscriptionLanguageListingCapability {
  final OpenAIClient client;
  final OpenAIConfig config;

  OpenAIAudio(this.client, this.config);

  @override
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    CancelToken? cancelToken,
  }) async {
    // Basic validation - let the provider handle specific limits
    if (request.text.isEmpty) {
      throw const InvalidRequestError('Text input cannot be empty');
    }

    final requestBody = <String, dynamic>{
      'model': request.model ?? openaiDefaultTTSModel,
      'input': request.text,
      'voice': request.voice ?? openaiDefaultVoice,
      if (request.format != null) 'response_format': request.format,
      if (request.speed != null) 'speed': request.speed,
    };

    final audioData = await client.postRaw(
      'audio/speech',
      requestBody,
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
      model: request.model,
      duration: null, // OpenAI doesn't provide duration
      sampleRate: null, // OpenAI doesn't provide sample rate
      usage: null,
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
    // Basic validation - let the provider handle specific limits
    if (request.audioData == null && request.filePath == null) {
      throw const InvalidRequestError(
        'Either audioData or filePath must be provided',
      );
    }

    final formData = FormData();

    if (request.audioData != null) {
      formData.files.add(
        MapEntry(
          'file',
          MultipartFile.fromBytes(
            request.audioData!,
            filename: 'audio.${request.format ?? 'wav'}',
          ),
        ),
      );
    } else if (request.filePath != null) {
      formData.files.add(
        MapEntry('file', await MultipartFile.fromFile(request.filePath!)),
      );
    }

    formData.fields
        .add(MapEntry('model', request.model ?? openaiDefaultSTTModel));
    if (request.language != null) {
      formData.fields.add(MapEntry('language', request.language!));
    }
    if (request.prompt != null) {
      formData.fields.add(MapEntry('prompt', request.prompt!));
    }
    if (request.responseFormat != null) {
      formData.fields.add(MapEntry('response_format', request.responseFormat!));
    }
    if (request.temperature != null) {
      formData.fields.add(
        MapEntry('temperature', request.temperature.toString()),
      );
    }

    // Handle timestamp granularities
    // Reference: https://platform.openai.com/docs/api-reference/audio/createTranscription
    final granularities = <String>[];
    if (request.includeWordTiming ||
        request.timestampGranularity == TimestampGranularity.word) {
      granularities.add('word');
    }
    if (request.timestampGranularity == TimestampGranularity.segment) {
      granularities.add('segment');
    }

    // Add each granularity as a separate field
    for (final granularity in granularities) {
      formData.fields.add(MapEntry('timestamp_granularities[]', granularity));
    }

    final responseData = await client.postForm(
      'audio/transcriptions',
      formData,
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
      model: request.model,
      duration: responseData['duration'] as double?,
      usage: null,
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

  // Audio translation implementation (OpenAI specific)

  @override
  Future<STTResponse> translateAudio(
    AudioTranslationRequest request, {
    CancelToken? cancelToken,
  }) async {
    // Basic validation
    if (request.audioData == null && request.filePath == null) {
      throw const InvalidRequestError(
        'Either audioData or filePath must be provided',
      );
    }

    final formData = FormData();

    if (request.audioData != null) {
      formData.files.add(
        MapEntry(
          'file',
          MultipartFile.fromBytes(
            request.audioData!,
            filename: 'audio.${request.format ?? 'wav'}',
          ),
        ),
      );
    } else if (request.filePath != null) {
      formData.files.add(
        MapEntry('file', await MultipartFile.fromFile(request.filePath!)),
      );
    }

    formData.fields
        .add(MapEntry('model', request.model ?? openaiDefaultSTTModel));
    if (request.prompt != null) {
      formData.fields.add(MapEntry('prompt', request.prompt!));
    }
    if (request.responseFormat != null) {
      formData.fields.add(MapEntry('response_format', request.responseFormat!));
    }
    if (request.temperature != null) {
      formData.fields.add(
        MapEntry('temperature', request.temperature.toString()),
      );
    }

    final responseData = await client.postForm(
      'audio/translations',
      formData,
      cancelToken: cancelToken,
    );

    return STTResponse(
      text: responseData['text'] as String,
      language: 'en', // Translations are always to English
      confidence: null,
      words: null, // Translation doesn't provide word timing
      model: request.model,
      duration: responseData['duration'] as double?,
      usage: null,
    );
  }
}
