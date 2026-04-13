part of 'capability.dart';

/// Google-specific TTS capability interface.
abstract class GoogleTTSCapability {
  /// Generate speech from text using Google's native TTS.
  Future<GoogleTTSResponse> generateSpeech(GoogleTTSRequest request);

  /// Generate speech with streaming output.
  Stream<GoogleTTSStreamEvent> generateSpeechStream(GoogleTTSRequest request);

  /// Get available voices for Google TTS.
  Future<List<GoogleVoiceInfo>> getAvailableVoices();

  /// Get supported languages for Google TTS.
  Future<List<String>> getSupportedLanguages();

  /// Get predefined Google TTS voices.
  static List<GoogleVoiceInfo> getPredefinedVoices() => [
        const GoogleVoiceInfo(name: 'Zephyr', description: 'Bright'),
        const GoogleVoiceInfo(name: 'Puck', description: 'Upbeat'),
        const GoogleVoiceInfo(name: 'Charon', description: 'Informative'),
        const GoogleVoiceInfo(name: 'Kore', description: 'Firm'),
        const GoogleVoiceInfo(name: 'Fenrir', description: 'Excitable'),
        const GoogleVoiceInfo(name: 'Leda', description: 'Youthful'),
        const GoogleVoiceInfo(name: 'Orus', description: 'Firm'),
        const GoogleVoiceInfo(name: 'Aoede', description: 'Breezy'),
        const GoogleVoiceInfo(name: 'Callirrhoe', description: 'Easy-going'),
        const GoogleVoiceInfo(name: 'Autonoe', description: 'Bright'),
        const GoogleVoiceInfo(name: 'Enceladus', description: 'Breathy'),
        const GoogleVoiceInfo(name: 'Iapetus', description: 'Clear'),
        const GoogleVoiceInfo(name: 'Umbriel', description: 'Easy-going'),
        const GoogleVoiceInfo(name: 'Algieba', description: 'Smooth'),
        const GoogleVoiceInfo(name: 'Despina', description: 'Smooth'),
        const GoogleVoiceInfo(name: 'Erinome', description: 'Clear'),
        const GoogleVoiceInfo(name: 'Algenib', description: 'Gravelly'),
        const GoogleVoiceInfo(name: 'Rasalgethi', description: 'Informative'),
        const GoogleVoiceInfo(name: 'Laomedeia', description: 'Upbeat'),
        const GoogleVoiceInfo(name: 'Achernar', description: 'Soft'),
        const GoogleVoiceInfo(name: 'Alnilam', description: 'Firm'),
        const GoogleVoiceInfo(name: 'Schedar', description: 'Even'),
        const GoogleVoiceInfo(name: 'Gacrux', description: 'Mature'),
        const GoogleVoiceInfo(name: 'Pulcherrima', description: 'Forward'),
        const GoogleVoiceInfo(name: 'Achird', description: 'Friendly'),
        const GoogleVoiceInfo(name: 'Zubenelgenubi', description: 'Casual'),
        const GoogleVoiceInfo(name: 'Vindemiatrix', description: 'Gentle'),
        const GoogleVoiceInfo(name: 'Sadachbia', description: 'Lively'),
        const GoogleVoiceInfo(name: 'Sadaltager', description: 'Knowledgeable'),
        const GoogleVoiceInfo(name: 'Sulafat', description: 'Warm'),
      ];

  /// Get supported languages for Google TTS.
  static List<String> getSupportedLanguageCodes() => [
        'ar-EG',
        'de-DE',
        'en-US',
        'es-US',
        'fr-FR',
        'hi-IN',
        'id-ID',
        'it-IT',
        'ja-JP',
        'ko-KR',
        'pt-BR',
        'ru-RU',
        'nl-NL',
        'pl-PL',
        'th-TH',
        'tr-TR',
        'vi-VN',
        'ro-RO',
        'uk-UA',
        'bn-BD',
        'en-IN',
        'mr-IN',
        'ta-IN',
        'te-IN',
      ];
}
