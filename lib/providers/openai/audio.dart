import 'package:dio/dio.dart';

import '../../core/chat_provider.dart';
import '../../core/llm_error.dart';
import '../../models/audio_models.dart';
import 'client.dart';
import 'config.dart';

/// OpenAI Audio capabilities implementation
///
/// This module handles both text-to-speech and speech-to-text functionality
/// for OpenAI providers.
class OpenAIAudio implements TextToSpeechCapability, SpeechToTextCapability {
  final OpenAIClient client;
  final OpenAIConfig config;

  OpenAIAudio(this.client, this.config);

  // TextToSpeechCapability implementation

  @override
  Future<TTSResponse> textToSpeech(TTSRequest request) async {
    final requestBody = <String, dynamic>{
      'model': request.model ?? 'tts-1',
      'input': request.text,
      'voice': request.voice ?? 'alloy',
      if (request.format != null) 'response_format': request.format,
      if (request.speed != null) 'speed': request.speed,
    };

    final audioData = await client.postRaw('audio/speech', requestBody);

    return TTSResponse(
      audioData: audioData,
      contentType: 'audio/mpeg', // Default for OpenAI
      voice: request.voice,
      model: request.model,
      duration: null, // OpenAI doesn't provide duration
      sampleRate: null, // OpenAI doesn't provide sample rate
      usage: null,
    );
  }

  @override
  Future<List<int>> speech(String text) async {
    final response = await textToSpeech(TTSRequest(text: text));
    return response.audioData;
  }

  @override
  Future<List<VoiceInfo>> getVoices() async {
    // OpenAI has predefined voices
    return const [
      VoiceInfo(id: 'alloy', name: 'Alloy', description: 'Neutral voice'),
      VoiceInfo(id: 'echo', name: 'Echo', description: 'Male voice'),
      VoiceInfo(id: 'fable', name: 'Fable', description: 'British accent'),
      VoiceInfo(id: 'onyx', name: 'Onyx', description: 'Deep male voice'),
      VoiceInfo(id: 'nova', name: 'Nova', description: 'Female voice'),
      VoiceInfo(
        id: 'shimmer',
        name: 'Shimmer',
        description: 'Soft female voice',
      ),
    ];
  }

  @override
  List<String> getSupportedAudioFormats() {
    return ['mp3', 'opus', 'aac', 'flac'];
  }

  // SpeechToTextCapability implementation

  @override
  Future<STTResponse> speechToText(STTRequest request) async {
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
    } else {
      throw const InvalidRequestError(
        'Either audioData or filePath must be provided',
      );
    }

    formData.fields.add(MapEntry('model', request.model ?? 'whisper-1'));
    if (request.language != null) {
      formData.fields.add(MapEntry('language', request.language!));
    }
    if (request.includeWordTiming) {
      formData.fields.add(MapEntry('timestamp_granularities[]', 'word'));
    }
    if (request.temperature != null) {
      formData.fields.add(
        MapEntry('temperature', request.temperature.toString()),
      );
    }

    final responseData =
        await client.postForm('audio/transcriptions', formData);

    // Parse word timing if available
    List<WordTiming>? words;
    if (request.includeWordTiming && responseData['words'] != null) {
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
  Future<String> transcribe(List<int> audio) async {
    final response = await speechToText(STTRequest.fromAudio(audio));
    return response.text;
  }

  @override
  Future<String> transcribeFile(String filePath) async {
    final response = await speechToText(STTRequest.fromFile(filePath));
    return response.text;
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
}
