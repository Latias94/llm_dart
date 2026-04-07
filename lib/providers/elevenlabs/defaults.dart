/// Provider-owned defaults for the compatibility-era ElevenLabs surface.
abstract final class ElevenLabsDefaults {
  static const String baseUrl = 'https://api.elevenlabs.io/v1/';
  static const String defaultVoiceId = 'JBFqnCBsd6RMkjVDRZzb';
  static const String defaultTtsModel = 'eleven_multilingual_v2';
  static const String defaultSttModel = 'scribe_v1';

  static const List<String> supportedAudioFormats = [
    'mp3_44100_128',
    'mp3_44100_192',
    'pcm_16000',
    'pcm_22050',
    'pcm_24000',
    'pcm_44100',
    'ulaw_8000',
  ];
}
