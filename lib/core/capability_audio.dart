import '../models/audio_models.dart';
import 'cancellation.dart';
import 'capability_audio_realtime.dart';

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

/// Unified audio processing capability interface
abstract class AudioCapability {
  // === Feature Discovery ===

  /// Get all audio features supported by this provider
  Set<AudioFeature> get supportedFeatures;

  // === Audio Generation (Text-to-Speech) ===

  /// Convert text to speech with full configuration support
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) {
    throw UnsupportedError('Text-to-speech not supported by this provider');
  }

  /// Convert text to speech with streaming output
  Stream<AudioStreamEvent> textToSpeechStream(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) {
    throw UnsupportedError(
        'Streaming text-to-speech not supported by this provider');
  }

  /// Get available voices for this provider
  Future<List<VoiceInfo>> getVoices() {
    throw UnsupportedError('Voice listing not supported by this provider');
  }

  // === Audio Understanding (Speech-to-Text) ===

  /// Convert speech to text with full configuration support
  Future<STTResponse> speechToText(
    STTRequest request, {
    TransportCancellation? cancelToken,
  }) {
    throw UnsupportedError('Speech-to-text not supported by this provider');
  }

  /// Get supported languages for transcription and translation
  Future<List<LanguageInfo>> getSupportedLanguages() {
    throw UnsupportedError('Language listing not supported by this provider');
  }

  // === Real-time Audio Processing ===

  /// Create and start a real-time audio session
  Future<RealtimeAudioSession> startRealtimeSession(
      RealtimeAudioConfig config) {
    throw UnsupportedError('Real-time audio not supported by this provider');
  }

  // === Metadata ===

  /// Get supported input/output audio formats
  List<String> getSupportedAudioFormats() {
    return ['mp3', 'wav', 'ogg'];
  }

  // === Convenience Methods ===

  /// Simple text-to-speech conversion (convenience method)
  Future<List<int>> speech(
    String text, {
    TransportCancellation? cancelToken,
  }) async {
    final response = await textToSpeech(
      TTSRequest(text: text),
      cancelToken: cancelToken,
    );
    return response.audioData;
  }

  /// Simple streaming text-to-speech conversion (convenience method)
  Stream<List<int>> speechStream(String text) async* {
    await for (final event in textToSpeechStream(TTSRequest(text: text))) {
      if (event is AudioDataEvent) {
        yield event.data;
      }
    }
  }

  /// Simple audio transcription (convenience method)
  Future<String> transcribe(List<int> audio) async {
    final response = await speechToText(STTRequest.fromAudio(audio));
    return response.text;
  }

  /// Simple file transcription (convenience method)
  Future<String> transcribeFile(String filePath) async {
    final response = await speechToText(STTRequest.fromFile(filePath));
    return response.text;
  }
}

/// Base implementation of AudioCapability with convenience methods
abstract class BaseAudioCapability implements AudioCapability {
  @override
  Future<List<int>> speech(
    String text, {
    TransportCancellation? cancelToken,
  }) async {
    final response = await textToSpeech(
      TTSRequest(text: text),
      cancelToken: cancelToken,
    );
    return response.audioData;
  }

  @override
  Stream<List<int>> speechStream(String text) async* {
    await for (final event in textToSpeechStream(TTSRequest(text: text))) {
      if (event is AudioDataEvent) {
        yield event.data;
      }
    }
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
}
