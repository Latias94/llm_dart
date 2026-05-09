import '../../../../core/capability.dart';
import '../../../../core/llm_error.dart';
import '../../../../models/audio_models.dart';
import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../providers/elevenlabs/client.dart' show ElevenLabsClient;
import '../../../../providers/elevenlabs/config.dart';
import 'elevenlabs_audio_compat.dart' show ElevenLabsAudio;
import 'elevenlabs_models_compat.dart' show ElevenLabsModels;
import 'shell_support.dart';

/// Compatibility-first root ElevenLabs provider shell.
///
/// New shared-capability mainlines should prefer the package-owned modern
/// surfaces in `llm_dart_elevenlabs` where possible. This root provider remains
/// the migration-era adapter that preserves legacy audio capability interfaces,
/// fallback routing, and residual provider-shaped APIs such as voice catalogs,
/// realtime flows, and account/model helpers.
class ElevenLabsProvider implements ChatCapability, AudioCapability {
  static const ProviderError _unsupportedChatError = ProviderError(
    'ElevenLabs does not support chat functionality',
  );

  final ElevenLabsConfig config;
  final ElevenLabsCompatShellSupport _compatShell;

  ElevenLabsProvider(this.config)
      : _compatShell = ElevenLabsCompatShellSupport(config: config);

  ElevenLabsClient get client => _compatShell.client;
  ElevenLabsAudio get audio => _compatShell.audio;
  ElevenLabsModels get models => _compatShell.models;

  @override
  Set<AudioFeature> get supportedFeatures => _compatShell.supportedFeatures;

  @override
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    return _compatShell.textToSpeech(request, cancelToken: cancelToken);
  }

  @override
  Stream<AudioStreamEvent> textToSpeechStream(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) {
    return _compatShell.textToSpeechStream(request, cancelToken: cancelToken);
  }

  @override
  Future<List<VoiceInfo>> getVoices() async {
    return _compatShell.getVoices();
  }

  @override
  Future<STTResponse> speechToText(
    STTRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    return _compatShell.speechToText(request, cancelToken: cancelToken);
  }

  @override
  Future<List<LanguageInfo>> getSupportedLanguages() async {
    return _compatShell.getSupportedLanguages();
  }

  @override
  Future<RealtimeAudioSession> startRealtimeSession(
    RealtimeAudioConfig config,
  ) async {
    return _compatShell.startRealtimeSession(config);
  }

  @override
  List<String> getSupportedAudioFormats() {
    return _compatShell.getSupportedAudioFormats();
  }

  @override
  Future<List<int>> speech(
    String text, {
    TransportCancellation? cancelToken,
  }) async {
    final response = await _compatShell.textToSpeech(
      TTSRequest(text: text),
      cancelToken: cancelToken,
    );
    return response.audioData;
  }

  @override
  Stream<List<int>> speechStream(String text) async* {
    await for (final event
        in _compatShell.textToSpeechStream(TTSRequest(text: text))) {
      if (event is AudioDataEvent) {
        yield event.data;
      }
    }
  }

  @override
  Future<String> transcribe(List<int> audio) async {
    final response =
        await _compatShell.speechToText(STTRequest.fromAudio(audio));
    return response.text;
  }

  @override
  Future<String> transcribeFile(String filePath) async {
    final response =
        await _compatShell.speechToText(STTRequest.fromFile(filePath));
    return response.text;
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) async {
    throw _unsupportedChatError;
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    TransportCancellation? cancelToken,
  }) async {
    return chatWithTools(messages, null, cancelToken: cancelToken);
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async {
    return null;
  }

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    throw _unsupportedChatError;
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) async* {
    yield ErrorEvent(_unsupportedChatError);
  }

  String get providerName => 'ElevenLabs';

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
    return ElevenLabsProvider(
      config.copyWith(
        apiKey: apiKey,
        baseUrl: baseUrl,
        voiceId: voiceId,
        model: model,
        timeout: timeout,
        stability: stability,
        similarityBoost: similarityBoost,
        style: style,
        useSpeakerBoost: useSpeakerBoost,
      ),
    );
  }

  bool supportsCapability(Type capability) {
    if (capability == AudioCapability) return true;
    if (capability == ChatCapability) return false;
    return false;
  }

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

  Future<List<Map<String, dynamic>>> getModels() async {
    return _compatShell.getModels();
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    return _compatShell.getUserInfo();
  }

  String describeProvider() {
    return 'ElevenLabsProvider(voice: ${config.defaultVoiceId})';
  }

  @override
  String toString() => describeProvider();
}
