part of 'capability.dart';

/// Enumeration of LLM capabilities that providers can support
enum LLMCapability {
  /// Basic chat functionality
  chat,

  /// Streaming chat responses
  streaming,

  /// Vector embeddings generation
  embedding,

  /// Text-to-speech conversion
  textToSpeech,

  /// Streaming text-to-speech conversion
  streamingTextToSpeech,

  /// Speech-to-text conversion
  speechToText,

  /// Real-time audio processing
  realtimeAudio,

  /// Model listing
  modelListing,

  /// Function/tool calling
  toolCalling,

  /// Reasoning/thinking capabilities
  reasoning,

  /// Vision/image understanding capabilities
  vision,

  /// Text completion (non-chat)
  completion,

  /// Image generation capabilities
  imageGeneration,

  /// File management capabilities
  fileManagement,

  /// Content moderation capabilities
  moderation,

  /// Live search capabilities (real-time web search)
  liveSearch,
}

/// Audio features that providers can support
enum AudioFeature {
  /// Basic text-to-speech conversion
  textToSpeech,

  /// Streaming text-to-speech conversion
  streamingTTS,

  /// Basic speech-to-text conversion
  speechToText,

  /// Real-time audio processing
  realtimeProcessing,

  /// Speaker diarization (identifying different speakers)
  speakerDiarization,

  /// Character-level timing information
  characterTiming,

  /// Audio event detection (laughter, applause, etc.)
  audioEventDetection,

  /// Voice cloning capabilities
  voiceCloning,

  /// Audio enhancement and noise reduction
  audioEnhancement,

  /// Multi-modal audio-visual processing
  multimodalAudio,
}

/// Provider capability declaration interface
abstract class ProviderCapabilities {
  /// Set of capabilities this provider supports
  Set<LLMCapability> get supportedCapabilities;

  /// Check if this provider supports a specific capability
  bool supports(LLMCapability capability) =>
      supportedCapabilities.contains(capability);
}

/// Basic LLM provider with just chat capability
abstract class BasicLLMProvider
    implements ChatCapability, ProviderCapabilities {}

/// LLM provider with chat and embedding capabilities
abstract class EmbeddingLLMProvider
    implements ChatCapability, EmbeddingCapability, ProviderCapabilities {}

/// LLM provider with voice capabilities
abstract class VoiceLLMProvider
    implements ChatCapability, AudioCapability, ProviderCapabilities {}

/// Full-featured LLM provider with all common capabilities
abstract class FullLLMProvider
    implements
        ChatCapability,
        EmbeddingCapability,
        ModelListingCapability,
        ProviderCapabilities {}
