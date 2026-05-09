import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart'
    as modern_elevenlabs;
import 'package:llm_dart_transport/llm_dart_transport.dart'
    show DioTransportClient;

import '../../../../core/capability.dart';
import '../../../../models/audio_models.dart';
import '../../../../providers/elevenlabs/client.dart';
import '../../../../providers/elevenlabs/config.dart';
import '../compat_provider_support.dart' show executeCompatBridge;
import 'elevenlabs_audio_compat.dart';
import 'elevenlabs_audio_bridge_support.dart';
import 'elevenlabs_models_compat.dart';

/// Root-compatibility glue for the ElevenLabs provider shell.
///
/// This keeps modern-model bridge setup and request-shaping helpers out of the
/// root provider implementation file so that file can stay focused on shell
/// orchestration and residual provider-specific fallback paths.
final class ElevenLabsCompatShellSupport {
  final ElevenLabsConfig config;
  final ElevenLabsClient client;
  final ElevenLabsAudio audio;
  final ElevenLabsModels models;
  final modern_elevenlabs.ElevenLabs modernProvider;
  final ElevenLabsAudioBridgeSupport bridgeSupport;

  ElevenLabsCompatShellSupport._({
    required this.config,
    required this.client,
    required this.audio,
    required this.models,
    required this.modernProvider,
    required this.bridgeSupport,
  });

  factory ElevenLabsCompatShellSupport({
    required ElevenLabsConfig config,
  }) {
    final client = ElevenLabsClient(config);
    final modernProvider = modern_elevenlabs.ElevenLabs(
      apiKey: config.apiKey,
      baseUrl: config.baseUrl,
      transport: DioTransportClient(dio: client.dio),
    );
    return ElevenLabsCompatShellSupport._(
      config: config,
      client: client,
      audio: ElevenLabsAudio(client, config),
      models: ElevenLabsModels(client, config),
      modernProvider: modernProvider,
      bridgeSupport: ElevenLabsAudioBridgeSupport(
        config: config,
        modernProvider: modernProvider,
      ),
    );
  }

  Set<AudioFeature> get supportedFeatures => audio.supportedFeatures;

  bool canUseSpeechBridge(TTSRequest request) =>
      bridgeSupport.canUseSpeechBridge(request);

  bool canUseTranscriptionBridge(STTRequest request) =>
      bridgeSupport.canUseTranscriptionBridge(request);

  Future<TTSResponse> bridgeTextToSpeech(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) {
    return bridgeSupport.bridgeTextToSpeech(
      request,
      cancelToken: cancelToken,
    );
  }

  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    return executeCompatBridge(
      canUseBridge: canUseSpeechBridge(request),
      bridge: () => bridgeTextToSpeech(
        request,
        cancelToken: cancelToken,
      ),
      fallback: () => audio.textToSpeech(
        request,
        cancelToken: cancelToken,
      ),
    );
  }

  Stream<AudioStreamEvent> textToSpeechStream(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) {
    return audio.textToSpeechStream(request, cancelToken: cancelToken);
  }

  Future<List<VoiceInfo>> getVoices() {
    return audio.getVoices();
  }

  Future<STTResponse> bridgeSpeechToText(
    STTRequest request, {
    TransportCancellation? cancelToken,
  }) {
    return bridgeSupport.bridgeSpeechToText(
      request,
      cancelToken: cancelToken,
    );
  }

  Future<STTResponse> speechToText(
    STTRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    return executeCompatBridge(
      canUseBridge: canUseTranscriptionBridge(request),
      bridge: () => bridgeSpeechToText(
        request,
        cancelToken: cancelToken,
      ),
      fallback: () => audio.speechToText(
        request,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<List<LanguageInfo>> getSupportedLanguages() {
    return audio.getSupportedLanguages();
  }

  Future<RealtimeAudioSession> startRealtimeSession(
    RealtimeAudioConfig config,
  ) {
    return audio.startRealtimeSession(config);
  }

  List<String> getSupportedAudioFormats() {
    return audio.getSupportedAudioFormats();
  }

  Future<List<Map<String, dynamic>>> getModels() {
    return models.getModels();
  }

  Future<Map<String, dynamic>> getUserInfo() {
    return models.getUserInfo();
  }
}
