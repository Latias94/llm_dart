import '../../core/capability.dart';
import '../../core/llm_error.dart';
import '../../models/chat_models.dart';
import '../../models/tool_models.dart';
import '../../models/audio_models.dart';
import '../../src/compatibility/providers/compat_provider_support.dart'
    show isCompatibilityError;
import '../../src/compatibility/providers/elevenlabs_compat_shell_support.dart';
import 'audio.dart';
import 'client.dart';
import 'config.dart';
import 'models.dart';

/// Compatibility-first root ElevenLabs provider shell.
///
/// New shared-capability mainlines should prefer the package-owned modern
/// surfaces in `llm_dart_community` where possible. This root provider remains
/// the migration-era adapter that preserves legacy audio capability interfaces,
/// fallback routing, and residual provider-shaped APIs such as voice catalogs,
/// realtime flows, and account/model helpers.
class ElevenLabsProvider implements ChatCapability, AudioCapability {
  final ElevenLabsConfig config;
  final ElevenLabsClient client;
  late final ElevenLabsAudio audio;
  late final ElevenLabsModels models;
  late final ElevenLabsCompatShellSupport _compatShell;

  ElevenLabsProvider(this.config) : client = ElevenLabsClient(config) {
    audio = ElevenLabsAudio(client, config);
    models = ElevenLabsModels(client, config);
    _compatShell = ElevenLabsCompatShellSupport(
      config: config,
      client: client,
    );
  }

  String get providerName => 'ElevenLabs';

  // ChatCapability implementation (not supported)
  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) async {
    throw const ProviderError('ElevenLabs does not support chat functionality');
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    TransportCancellation? cancelToken,
  }) async {
    return chatWithTools(messages, null, cancelToken: cancelToken);
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
    TransportCancellation? cancelToken,
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
    TransportCancellation? cancelToken,
  }) async {
    if (_compatShell.canUseSpeechBridge(request)) {
      try {
        return await _compatShell.bridgeTextToSpeech(
          request,
          cancelToken: cancelToken,
        );
      } catch (error) {
        if (!isCompatibilityError(error)) {
          rethrow;
        }
      }
    }

    return audio.textToSpeech(request, cancelToken: cancelToken);
  }

  @override
  Stream<AudioStreamEvent> textToSpeechStream(
    TTSRequest request, {
    TransportCancellation? cancelToken,
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
    TransportCancellation? cancelToken,
  }) async {
    if (_compatShell.canUseTranscriptionBridge(request)) {
      try {
        return await _compatShell.bridgeSpeechToText(
          request,
          cancelToken: cancelToken,
        );
      } catch (error) {
        if (!isCompatibilityError(error)) {
          rethrow;
        }
      }
    }

    return audio.speechToText(request, cancelToken: cancelToken);
  }

  @override
  Future<STTResponse> translateAudio(
    AudioTranslationRequest request, {
    TransportCancellation? cancelToken,
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
    // ElevenLabs doesn't support chat
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
