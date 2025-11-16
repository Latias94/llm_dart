import 'capability.dart';

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
          'model': elevenLabsDefaultTTSModel, // Use TTS model as default model
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
      // OpenAI-compatible providers
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
          LLMCapability.assistants,
          // Note: openaiResponses is added dynamically based on configuration
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
      // OpenAI-compatible providers
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

/// OpenAI-compatible provider configurations.
///
/// This helper was the original place where OpenAI-compatible provider
/// defaults were defined. New code should prefer the richer
/// `OpenAICompatibleProviderProfiles` from the `llm_dart_openai_compatible`
/// package, which includes model-level capability metadata.
@Deprecated(
  'Use OpenAICompatibleProviderProfiles in the '
  'llm_dart_openai_compatible package instead.',
)
class OpenAICompatibleDefaults {
  /// DeepSeek using OpenAI-compatible API
  static const Map<String, dynamic> deepseek = {
    'providerId': 'deepseek-openai',
    'displayName': 'DeepSeek (OpenAI-compatible)',
    'description': 'DeepSeek AI models using OpenAI-compatible interface',
    'baseUrl': ProviderDefaults.deepseekBaseUrl,
    'model': ProviderDefaults.deepseekDefaultModel,
    'capabilities': {
      LLMCapability.chat,
      LLMCapability.streaming,
      LLMCapability.toolCalling,
      LLMCapability.reasoning,
    },
  };

  /// Groq using OpenAI-compatible API
  static const Map<String, dynamic> groq = {
    'providerId': 'groq-openai',
    'displayName': 'Groq (OpenAI-compatible)',
    'description':
        'Groq AI models using OpenAI-compatible interface for ultra-fast inference',
    'baseUrl': ProviderDefaults.groqBaseUrl,
    'model': ProviderDefaults.groqDefaultModel,
    'capabilities': {
      LLMCapability.chat,
      LLMCapability.streaming,
      LLMCapability.toolCalling,
    },
  };

  /// xAI using OpenAI-compatible API
  static const Map<String, dynamic> xai = {
    'providerId': 'xai-openai',
    'displayName': 'xAI Grok (OpenAI-compatible)',
    'description': 'xAI Grok models using OpenAI-compatible interface',
    'baseUrl': ProviderDefaults.xaiBaseUrl,
    'model': ProviderDefaults.xaiDefaultModel,
    'capabilities': {
      LLMCapability.chat,
      LLMCapability.streaming,
      LLMCapability.toolCalling,
      LLMCapability.reasoning,
    },
  };

  /// Phind using OpenAI-compatible API
  static const Map<String, dynamic> phind = {
    'providerId': 'phind-openai',
    'displayName': 'Phind (OpenAI-compatible)',
    'description': 'Phind AI models using OpenAI-compatible interface',
    'baseUrl': ProviderDefaults.phindBaseUrl,
    'model': ProviderDefaults.phindDefaultModel,
    'capabilities': {
      LLMCapability.chat,
      LLMCapability.streaming,
      LLMCapability.toolCalling,
    },
  };

  /// OpenRouter configuration
  static const Map<String, dynamic> openRouter = {
    'providerId': 'openrouter',
    'displayName': 'OpenRouter',
    'description': 'OpenRouter unified API for multiple AI models',
    'baseUrl': ProviderDefaults.openRouterBaseUrl,
    'model': ProviderDefaults.openRouterDefaultModel,
    'capabilities': {
      LLMCapability.chat,
      LLMCapability.streaming,
      LLMCapability.toolCalling,
      LLMCapability.vision,
    },
  };

  /// GitHub Copilot configuration
  static const Map<String, dynamic> githubCopilot = {
    'providerId': 'github-copilot',
    'displayName': 'GitHub Copilot',
    'description': 'GitHub Copilot Chat API',
    'baseUrl': ProviderDefaults.githubCopilotBaseUrl,
    'model': ProviderDefaults.githubCopilotDefaultModel,
    'capabilities': {
      LLMCapability.chat,
      LLMCapability.streaming,
      LLMCapability.toolCalling,
    },
  };

  /// Together AI configuration
  static const Map<String, dynamic> togetherAI = {
    'providerId': 'together-ai',
    'displayName': 'Together AI',
    'description': 'Together AI platform for open source models',
    'baseUrl': ProviderDefaults.togetherAIBaseUrl,
    'model': ProviderDefaults.togetherAIDefaultModel,
    'capabilities': {
      LLMCapability.chat,
      LLMCapability.streaming,
      LLMCapability.toolCalling,
    },
  };

  /// Get all OpenAI-compatible configurations
  static List<Map<String, dynamic>> getAllConfigs() {
    return [
      deepseek,
      groq,
      xai,
      phind,
      openRouter,
      githubCopilot,
      togetherAI,
    ];
  }

  /// Get configuration by provider ID
  static Map<String, dynamic>? getConfig(String providerId) {
    switch (providerId) {
      case 'deepseek-openai':
        return deepseek;
      case 'groq-openai':
        return groq;
      case 'xai-openai':
        return xai;
      case 'phind-openai':
        return phind;
      case 'openrouter':
        return openRouter;
      case 'github-copilot':
        return githubCopilot;
      case 'together-ai':
        return togetherAI;
      default:
        return null;
    }
  }
}
