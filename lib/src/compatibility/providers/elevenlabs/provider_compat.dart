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

part 'provider_compat_audio_shortcuts.dart';
part 'provider_compat_chat_support.dart';
part 'provider_compat_info_support.dart';

/// Compatibility-first root ElevenLabs provider shell.
///
/// New shared-capability mainlines should prefer the package-owned modern
/// surfaces in `llm_dart_community` where possible. This root provider remains
/// the migration-era adapter that preserves legacy audio capability interfaces,
/// fallback routing, and residual provider-shaped APIs such as voice catalogs,
/// realtime flows, and account/model helpers.
class ElevenLabsProvider implements ChatCapability, AudioCapability {
  final ElevenLabsConfig config;
  final ElevenLabsCompatShellSupport _compatShell;
  final _ElevenLabsUnsupportedChatSupport _chatSupport =
      const _ElevenLabsUnsupportedChatSupport();
  late final _ElevenLabsProviderAudioShortcuts _audioShortcuts =
      _ElevenLabsProviderAudioShortcuts(_compatShell);
  late final _ElevenLabsProviderInfoSupport _providerInfo =
      _ElevenLabsProviderInfoSupport(config: config);

  ElevenLabsProvider(this.config)
      : _compatShell = ElevenLabsCompatShellSupport(config: config);

  String get providerName => _providerInfo.providerName;

  ElevenLabsClient get client => _compatShell.client;
  ElevenLabsAudio get audio => _compatShell.audio;
  ElevenLabsModels get models => _compatShell.models;

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) async {
    return _chatSupport.chatWithTools(
      messages,
      tools,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    TransportCancellation? cancelToken,
  }) async {
    return _chatSupport.chat(messages, cancelToken: cancelToken);
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async {
    return _chatSupport.memoryContents();
  }

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    return _chatSupport.summarizeHistory(messages);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) async* {
    yield* _chatSupport.chatStream(
      messages,
      tools: tools,
      cancelToken: cancelToken,
    );
  }

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
  Future<STTResponse> translateAudio(
    AudioTranslationRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    return _compatShell.translateAudio(request, cancelToken: cancelToken);
  }

  @override
  Future<List<LanguageInfo>> getSupportedLanguages() async {
    return _compatShell.getSupportedLanguages();
  }

  @override
  Future<RealtimeAudioSession> startRealtimeSession(
      RealtimeAudioConfig config) async {
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
    return _audioShortcuts.speech(text, cancelToken: cancelToken);
  }

  @override
  Stream<List<int>> speechStream(String text) async* {
    yield* _audioShortcuts.speechStream(text);
  }

  @override
  Future<String> transcribe(List<int> audio) async {
    return _audioShortcuts.transcribe(audio);
  }

  @override
  Future<String> transcribeFile(String filePath) async {
    return _audioShortcuts.transcribeFile(filePath);
  }

  @override
  Future<String> translate(List<int> audio) async {
    return _audioShortcuts.translate(audio);
  }

  @override
  Future<String> translateFile(String filePath) async {
    return _audioShortcuts.translateFile(filePath);
  }

  Future<List<Map<String, dynamic>>> getModels() async {
    return _compatShell.getModels();
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    return _compatShell.getUserInfo();
  }

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
    return _providerInfo.copyWith(
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
  }

  bool supportsCapability(Type capability) {
    return _providerInfo.supportsCapability(capability);
  }

  Map<String, dynamic> get info => _providerInfo.info;

  @override
  String toString() => _providerInfo.describeProvider();
}
