import '../../../../models/audio_models.dart';

/// Static ElevenLabs audio capability catalogs that do not belong inside the
/// request/response orchestration facade.
final class ElevenLabsAudioCatalog {
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

  const ElevenLabsAudioCatalog._();
}
