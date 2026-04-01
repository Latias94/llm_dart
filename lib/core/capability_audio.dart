part of 'capability.dart';

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

  /// Translate audio to English text
  Future<STTResponse> translateAudio(
    AudioTranslationRequest request, {
    TransportCancellation? cancelToken,
  }) {
    throw UnsupportedError('Audio translation not supported by this provider');
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

  /// Simple audio translation (convenience method)
  Future<String> translate(List<int> audio) async {
    final response =
        await translateAudio(AudioTranslationRequest.fromAudio(audio));
    return response.text;
  }

  /// Simple file translation (convenience method)
  Future<String> translateFile(String filePath) async {
    final response =
        await translateAudio(AudioTranslationRequest.fromFile(filePath));
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

  @override
  Future<String> translate(List<int> audio) async {
    final response =
        await translateAudio(AudioTranslationRequest.fromAudio(audio));
    return response.text;
  }

  @override
  Future<String> translateFile(String filePath) async {
    final response =
        await translateAudio(AudioTranslationRequest.fromFile(filePath));
    return response.text;
  }
}

/// Configuration for real-time audio sessions
class RealtimeAudioConfig {
  /// Audio input format
  final String? inputFormat;

  /// Audio output format
  final String? outputFormat;

  /// Sample rate for audio processing
  final int? sampleRate;

  /// Enable voice activity detection
  final bool enableVAD;

  /// Enable echo cancellation
  final bool enableEchoCancellation;

  /// Enable noise suppression
  final bool enableNoiseSuppression;

  /// Session timeout in seconds
  final int? timeoutSeconds;

  /// Custom session parameters
  final Map<String, dynamic>? customParams;

  const RealtimeAudioConfig({
    this.inputFormat,
    this.outputFormat,
    this.sampleRate,
    this.enableVAD = true,
    this.enableEchoCancellation = true,
    this.enableNoiseSuppression = true,
    this.timeoutSeconds,
    this.customParams,
  });

  Map<String, dynamic> toJson() => {
        if (inputFormat != null) 'input_format': inputFormat,
        if (outputFormat != null) 'output_format': outputFormat,
        if (sampleRate != null) 'sample_rate': sampleRate,
        'enable_vad': enableVAD,
        'enable_echo_cancellation': enableEchoCancellation,
        'enable_noise_suppression': enableNoiseSuppression,
        if (timeoutSeconds != null) 'timeout_seconds': timeoutSeconds,
        if (customParams != null) 'custom_params': customParams,
      };

  factory RealtimeAudioConfig.fromJson(Map<String, dynamic> json) =>
      RealtimeAudioConfig(
        inputFormat: json['input_format'] as String?,
        outputFormat: json['output_format'] as String?,
        sampleRate: json['sample_rate'] as int?,
        enableVAD: json['enable_vad'] as bool? ?? true,
        enableEchoCancellation:
            json['enable_echo_cancellation'] as bool? ?? true,
        enableNoiseSuppression:
            json['enable_noise_suppression'] as bool? ?? true,
        timeoutSeconds: json['timeout_seconds'] as int?,
        customParams: json['custom_params'] as Map<String, dynamic>?,
      );
}

/// A stateful real-time audio session
abstract class RealtimeAudioSession {
  /// Send audio data to the session
  void sendAudio(List<int> audioData);

  /// Receive events from the session
  Stream<RealtimeAudioEvent> get events;

  /// Close the session gracefully
  Future<void> close();

  /// Check if the session is still active
  bool get isActive;

  /// Session ID for tracking
  String get sessionId;
}

/// Events from real-time audio sessions
abstract class RealtimeAudioEvent {
  /// Timestamp of the event
  final DateTime timestamp;

  const RealtimeAudioEvent({required this.timestamp});
}

/// Real-time transcription event
class RealtimeTranscriptionEvent extends RealtimeAudioEvent {
  /// Transcribed text
  final String text;

  /// Whether this is a final transcription
  final bool isFinal;

  /// Confidence score
  final double? confidence;

  const RealtimeTranscriptionEvent({
    required super.timestamp,
    required this.text,
    required this.isFinal,
    this.confidence,
  });
}

/// Real-time audio response event
class RealtimeAudioResponseEvent extends RealtimeAudioEvent {
  /// Audio response data
  final List<int> audioData;

  /// Whether this is the final chunk
  final bool isFinal;

  const RealtimeAudioResponseEvent({
    required super.timestamp,
    required this.audioData,
    required this.isFinal,
  });
}

/// Real-time session status event
class RealtimeSessionStatusEvent extends RealtimeAudioEvent {
  /// Session status
  final String status;

  /// Additional status information
  final Map<String, dynamic>? details;

  const RealtimeSessionStatusEvent({
    required super.timestamp,
    required this.status,
    this.details,
  });
}

/// Real-time error event
class RealtimeErrorEvent extends RealtimeAudioEvent {
  /// Error message
  final String message;

  /// Error code
  final String? code;

  const RealtimeErrorEvent({
    required super.timestamp,
    required this.message,
    this.code,
  });
}

/// Google-specific TTS capability interface
abstract class GoogleTTSCapability {
  /// Generate speech from text using Google's native TTS
  Future<GoogleTTSResponse> generateSpeech(GoogleTTSRequest request);

  /// Generate speech with streaming output
  Stream<GoogleTTSStreamEvent> generateSpeechStream(GoogleTTSRequest request);

  /// Get available voices for Google TTS
  Future<List<GoogleVoiceInfo>> getAvailableVoices();

  /// Get supported languages for Google TTS
  Future<List<String>> getSupportedLanguages();

  /// Get predefined Google TTS voices
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

  /// Get supported languages for Google TTS
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
