import '../../core/capability.dart';

/// Centralized provider default configurations
///
/// This file contains all default endpoints, models, and capabilities
/// for all supported providers to eliminate configuration duplication
/// and ensure consistency across the library.
class ProviderDefaults {
  // Core OpenAI
  static const String openaiBaseUrl = 'https://api.openai.com/v1/';
  static const String openaiDefaultModel = 'gpt-4o';

  // OpenAI Audio defaults
  static const String openaiDefaultTTSModel = 'tts-1';
  static const String openaiDefaultSTTModel = 'whisper-1';
  static const String openaiDefaultVoice = 'alloy';
  static const String openaiDefaultAudioFormat = 'mp3';

  // OpenAI supported voices
  // Reference: https://platform.openai.com/docs/guides/text-to-speech#voice-options
  static const List<String> openaiSupportedVoices = [
    'alloy', // Neutral voice
    'ash', // Expressive voice
    'ballad', // Melodic voice
    'coral', // Warm voice
    'echo', // Male voice
    'fable', // British accent
    'nova', // Female voice
    'onyx', // Deep male voice
    'sage', // Wise voice
    'shimmer', // Soft female voice
    'verse', // Poetic voice
  ];

  // OpenAI supported audio formats for TTS
  static const List<String> openaiSupportedTTSFormats = [
    'mp3',
    'opus',
    'aac',
    'flac',
    'wav',
    'pcm',
  ];

  // OpenAI supported audio formats for STT (input)
  static const List<String> openaiSupportedSTTFormats = [
    'flac',
    'm4a',
    'mp3',
    'mp4',
    'mpeg',
    'mpga',
    'oga',
    'ogg',
    'wav',
    'webm',
  ];

  // OpenAI supported image sizes
  static const List<String> openaiSupportedImageSizes = [
    '256x256', // DALL-E 2 only
    '512x512', // DALL-E 2 only
    '1024x1024', // Both DALL-E 2 and 3
    '1792x1024', // DALL-E 3 only (landscape)
    '1024x1792', // DALL-E 3 only (portrait)
  ];

  // OpenAI supported image formats
  static const List<String> openaiSupportedImageFormats = [
    'url', // Image URL (default)
    'b64_json', // Base64 encoded JSON
  ];

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

  // OpenAI-compatible providers
  static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1/';
  static const String openRouterDefaultModel = 'openai/gpt-4';

  static const String azureOpenAIApiVersion = '2024-02-15-preview';

  static const String githubCopilotBaseUrl =
      'https://api.githubcopilot.com/chat/completions';
  static const String githubCopilotDefaultModel = 'gpt-4';

  static const String togetherAIBaseUrl = 'https://api.together.xyz/v1/';
  static const String togetherAIDefaultModel = 'meta-llama/Llama-3-70b-chat-hf';

  /// Get default configuration for a provider
  static Map<String, dynamic> getDefaults(String providerId) {
    switch (providerId) {
      case 'openai':
        return {
          'baseUrl': openaiBaseUrl,
          'model': openaiDefaultModel,
          'ttsModel': openaiDefaultTTSModel,
          'sttModel': openaiDefaultSTTModel,
          'defaultVoice': openaiDefaultVoice,
          'defaultAudioFormat': openaiDefaultAudioFormat,
          'supportedVoices': openaiSupportedVoices,
          'supportedTTSFormats': openaiSupportedTTSFormats,
          'supportedSTTFormats': openaiSupportedSTTFormats,
          'supportedImageSizes': openaiSupportedImageSizes,
          'supportedImageFormats': openaiSupportedImageFormats,
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
      case 'openrouter':
        return {
          'baseUrl': openRouterBaseUrl,
          'model': openRouterDefaultModel,
        };
      case 'github-copilot':
        return {
          'baseUrl': githubCopilotBaseUrl,
          'model': githubCopilotDefaultModel,
        };
      case 'together-ai':
        return {
          'baseUrl': togetherAIBaseUrl,
          'model': togetherAIDefaultModel,
        };
      default:
        throw ArgumentError('Unknown provider: $providerId');
    }
  }

  /// Get supported capabilities for a provider
  static Set<LLMCapability> getCapabilities(String providerId) {
    switch (providerId) {
      case 'openai':
        return {
          LLMCapability.chat,
          LLMCapability.streaming,
          LLMCapability.embedding,
          LLMCapability.modelListing,
          LLMCapability.toolCalling,
          LLMCapability.reasoning,
          LLMCapability.vision,
          LLMCapability.textToSpeech,
          LLMCapability.speechToText,
          LLMCapability.imageGeneration,
        };
      case 'anthropic':
        return {
          LLMCapability.chat,
          LLMCapability.streaming,
          LLMCapability.toolCalling,
          LLMCapability.reasoning,
          LLMCapability.vision,
        };
      case 'google':
        return {
          LLMCapability.chat,
          LLMCapability.streaming,
          LLMCapability.toolCalling,
          LLMCapability.reasoning,
          LLMCapability.vision,
          LLMCapability.imageGeneration,
        };
      case 'deepseek':
        return {
          LLMCapability.chat,
          LLMCapability.streaming,
          LLMCapability.toolCalling,
          LLMCapability.reasoning,
        };
      case 'groq':
        return {
          LLMCapability.chat,
          LLMCapability.streaming,
          LLMCapability.toolCalling,
        };
      case 'xai':
        return {
          LLMCapability.chat,
          LLMCapability.streaming,
          LLMCapability.toolCalling,
          LLMCapability.reasoning,
          LLMCapability.embedding,
        };
      case 'phind':
        return {
          LLMCapability.chat,
          LLMCapability.streaming,
          LLMCapability.toolCalling,
        };
      case 'elevenlabs':
        return {
          LLMCapability.textToSpeech,
          LLMCapability.speechToText,
        };
      case 'ollama':
        return {
          LLMCapability.chat,
          LLMCapability.streaming,
          LLMCapability.embedding,
          LLMCapability.modelListing,
        };
      case 'openrouter':
        return {
          LLMCapability.chat,
          LLMCapability.streaming,
          LLMCapability.toolCalling,
          LLMCapability.vision,
        };
      case 'github-copilot':
        return {
          LLMCapability.chat,
          LLMCapability.streaming,
          LLMCapability.toolCalling,
        };
      case 'together-ai':
        return {
          LLMCapability.chat,
          LLMCapability.streaming,
          LLMCapability.toolCalling,
        };
      default:
        return <LLMCapability>{};
    }
  }
}
