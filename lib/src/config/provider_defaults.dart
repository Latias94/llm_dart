/// Centralized provider default configurations
///
/// This file contains legacy root factory endpoint/model defaults.
///
/// Capability declarations live on providers and factories, while
/// OpenAI-compatible generic endpoint profiles live in `OpenAICompatibleConfigs`.
class ProviderDefaults {
  // Core OpenAI
  static const String openaiBaseUrl = 'https://api.openai.com/v1/';
  static const String openaiDefaultModel = 'gpt-4o';

  // Anthropic
  static const String anthropicBaseUrl = 'https://api.anthropic.com/v1/';
  static const String anthropicDefaultModel = 'claude-sonnet-4-20250514';

  // Google (Gemini)
  static const String googleBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/';
  static const String googleDefaultModel = 'gemini-1.5-flash';

  // DeepSeek
  static const String deepseekBaseUrl = 'https://api.deepseek.com/v1/';
  static const String deepseekDefaultModel = 'deepseek-chat';

  // Groq
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1/';
  static const String groqDefaultModel = 'llama-3.3-70b-versatile';

  // xAI
  static const String xaiBaseUrl = 'https://api.x.ai/v1/';
  static const String xaiDefaultModel = 'grok-3';

  // Phind
  static const String phindBaseUrl = 'https://api.phind.com/v1/';
  static const String phindDefaultModel = 'Phind-70B';

  // ElevenLabs
  static const String elevenLabsBaseUrl = 'https://api.elevenlabs.io/v1/';
  static const String elevenLabsDefaultVoiceId = 'JBFqnCBsd6RMkjVDRZzb';
  static const String elevenLabsDefaultTTSModel = 'eleven_multilingual_v2';
  static const String elevenLabsDefaultSTTModel = 'scribe_v1';

  // ElevenLabs supported audio formats
  static const List<String> elevenLabsSupportedAudioFormats = [
    'mp3_44100_128',
    'mp3_44100_192',
    'pcm_16000',
    'pcm_22050',
    'pcm_24000',
    'pcm_44100',
    'ulaw_8000',
  ];

  // Ollama
  static const String ollamaBaseUrl = 'http://localhost:11434/';
  static const String ollamaDefaultModel = 'llama3.2';

  /// Get default configuration for a provider
  static Map<String, dynamic> getDefaults(String providerId) {
    switch (providerId) {
      case 'openai':
        return {
          'baseUrl': openaiBaseUrl,
          'model': openaiDefaultModel,
        };
      case 'anthropic':
        return {
          'baseUrl': anthropicBaseUrl,
          'model': anthropicDefaultModel,
        };
      case 'google':
        return {
          'baseUrl': googleBaseUrl,
          'model': googleDefaultModel,
        };
      case 'deepseek':
        return {
          'baseUrl': deepseekBaseUrl,
          'model': deepseekDefaultModel,
        };
      case 'groq':
        return {
          'baseUrl': groqBaseUrl,
          'model': groqDefaultModel,
        };
      case 'xai':
        return {
          'baseUrl': xaiBaseUrl,
          'model': xaiDefaultModel,
        };
      case 'phind':
        return {
          'baseUrl': phindBaseUrl,
          'model': phindDefaultModel,
        };
      case 'elevenlabs':
        return {
          'baseUrl': elevenLabsBaseUrl,
          'model': elevenLabsDefaultTTSModel,
          'voiceId': elevenLabsDefaultVoiceId,
          'ttsModel': elevenLabsDefaultTTSModel,
          'sttModel': elevenLabsDefaultSTTModel,
          'supportedAudioFormats': elevenLabsSupportedAudioFormats,
        };
      case 'ollama':
        return {
          'baseUrl': ollamaBaseUrl,
          'model': ollamaDefaultModel,
        };
      default:
        throw ArgumentError('Unknown provider: $providerId');
    }
  }
}
