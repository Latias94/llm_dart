import 'package:llm_dart_core/llm_dart_core.dart';

import '../audio/elevenlabs_audio.dart';
import '../config/elevenlabs_config.dart';
import '../client/elevenlabs_client.dart';
import '../models/elevenlabs_models.dart';

/// ElevenLabs Provider implementation
///
/// This is the main provider class that implements audio capabilities
/// and delegates to specialized modules for different functionalities.
/// ElevenLabs specializes in text-to-speech and speech-to-text services.
class ElevenLabsProvider implements ChatCapability, AudioCapability {
  final ElevenLabsConfig config;
  final ElevenLabsClient client;
  late final ElevenLabsAudio audio;
  late final ElevenLabsModels models;

  ElevenLabsProvider(this.config) : client = ElevenLabsClient(config) {
    audio = ElevenLabsAudio(client, config);
    models = ElevenLabsModels(client, config);
  }

  String get providerName => 'ElevenLabs';

  // ChatCapability implementation (not supported)
  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    throw const ProviderError('ElevenLabs does not support chat functionality');
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async {
    return chatWithTools(
      messages,
      null,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    throw const ProviderError('ElevenLabs does not support chat functionality');
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) async* {
    yield ErrorEvent(
        const ProviderError('ElevenLabs does not support chat functionality'));
  }

  // AudioCapability implementation (delegated to audio module)

  @override
  Set<AudioFeature> get supportedFeatures => audio.supportedFeatures;

  @override
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    CancellationToken? cancelToken,
  }) async {
    return audio.textToSpeech(request, cancelToken: cancelToken);
  }

  @override
  Stream<AudioStreamEvent> textToSpeechStream(
    TTSRequest request, {
    CancellationToken? cancelToken,
  }) {
    return audio.textToSpeechStream(request, cancelToken: cancelToken);
  }

  @override
  Future<List<VoiceInfo>> getVoices() async {
    return audio.getVoices();
  }

  @override
  Future<STTResponse> speechToText(
    STTRequest request, {
    CancellationToken? cancelToken,
  }) async {
    return audio.speechToText(request, cancelToken: cancelToken);
  }

  @override
  Future<STTResponse> translateAudio(
    AudioTranslationRequest request, {
    CancellationToken? cancelToken,
  }) async {
    return audio.translateAudio(request, cancelToken: cancelToken);
  }

  @override
  Future<List<LanguageInfo>> getSupportedLanguages() async {
    return audio.getSupportedLanguages();
  }

  @override
  Future<RealtimeAudioSession> startRealtimeSession(
      RealtimeAudioConfig config) async {
    return audio.startRealtimeSession(config);
  }

  @override
  List<String> getSupportedAudioFormats() {
    return audio.getSupportedAudioFormats();
  }

  // AudioCapability convenience methods implementation
  @override
  Future<List<int>> speech(
    String text, {
    CancellationToken? cancelToken,
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
  Future<String> transcribe(List<int> audioData) async {
    final response = await speechToText(STTRequest.fromAudio(audioData));
    return response.text;
  }

  @override
  Future<String> transcribeFile(String filePath) async {
    final response = await speechToText(STTRequest.fromFile(filePath));
    return response.text;
  }

  @override
  Future<String> translate(List<int> audioData) async {
    final response =
        await translateAudio(AudioTranslationRequest.fromAudio(audioData));
    return response.text;
  }

  @override
  Future<String> translateFile(String filePath) async {
    final response =
        await translateAudio(AudioTranslationRequest.fromFile(filePath));
    return response.text;
  }

  /// Get available models
  Future<List<Map<String, dynamic>>> getModels() async {
    return models.getModels();
  }

  /// Get user subscription info
  Future<Map<String, dynamic>> getUserInfo() async {
    return models.getUserInfo();
  }

  /// Create a new provider with updated configuration
  ElevenLabsProvider copyWith({
    String? apiKey,
    String? baseUrl,
    String? voiceId,
    String? model,
    Duration? timeout,
    double? stability,
    double? similarityBoost,
    double? style,
    bool? useSpeakerBoost,
  }) {
    final newConfig = config.copyWith(
      apiKey: apiKey,
      baseUrl: baseUrl,
      voiceId: voiceId,
      model: model,
      timeout: timeout,
      stability: stability,
      similarityBoost: similarityBoost,
      style: style,
      useSpeakerBoost: useSpeakerBoost,
    );

    return ElevenLabsProvider(newConfig);
  }

  /// Check if the provider supports a specific capability
  bool supportsCapability(Type capability) {
    if (capability == AudioCapability) return true;
    // ElevenLabs does not support chat
    if (capability == ChatCapability) return false;
    return false;
  }

  /// Get provider information
  Map<String, dynamic> get info => {
        'provider': providerName,
        'baseUrl': config.baseUrl,
        'supportsChat': false,
        'supportsTextToSpeech': config.supportsTextToSpeech,
        'supportsSpeechToText': config.supportsSpeechToText,
        'supportsVoiceCloning': config.supportsVoiceCloning,
        'supportsRealTimeStreaming': config.supportsRealTimeStreaming,
        'defaultVoiceId': config.defaultVoiceId,
        'defaultTTSModel': config.defaultTTSModel,
        'defaultSTTModel': config.defaultSTTModel,
        'supportedAudioFormats': config.supportedAudioFormats,
      };

  @override
  String toString() => 'ElevenLabsProvider(voice: ${config.defaultVoiceId})';
}
