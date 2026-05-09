import '../../../../core/llm_error.dart';
import 'client.dart';
import '../../../../providers/google/config.dart';
import 'google_tts_capability.dart';
import 'google_tts_models.dart';
import 'google_tts_stream_support.dart';

export 'google_tts_capability.dart';
export 'google_tts_models.dart';
export 'google_tts_stream_support.dart';

/// Google TTS implementation.
///
/// This class implements Google's native text-to-speech capabilities
/// using the Gemini API with audio output modality.
class GoogleTTS implements GoogleTTSCapability {
  final GoogleClient _client;
  final GoogleConfig _config;
  static const _streamSupport = GoogleTTSStreamSupport();
  static const _defaultTTSModel = 'gemini-2.5-flash-preview-tts';

  GoogleTTS(this._client, this._config);

  @override
  Future<GoogleTTSResponse> generateSpeech(GoogleTTSRequest request) async {
    try {
      final requestBody = request.toJson();
      final model = _resolveModel(request);

      final response = await _client.post(
        _generateContentEndpoint(model),
        data: requestBody,
      );

      return GoogleTTSResponse.fromApiResponse(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw GenericError('Google TTS generation failed: $e');
    }
  }

  @override
  Stream<GoogleTTSStreamEvent> generateSpeechStream(
    GoogleTTSRequest request,
  ) async* {
    final requestBody = request.toJson();
    final model = _resolveModel(request);
    final endpoint = _streamGenerateContentEndpoint(model);

    yield* _streamSupport.generateSpeechStream(
      client: _client,
      endpoint: endpoint,
      requestBody: requestBody,
    );
  }

  @override
  Future<List<GoogleVoiceInfo>> getAvailableVoices() async {
    return GoogleTTSCapability.getPredefinedVoices();
  }

  @override
  Future<List<String>> getSupportedLanguages() async {
    return GoogleTTSCapability.getSupportedLanguageCodes();
  }

  /// Check if the current model supports TTS.
  bool get supportsTTS {
    return _supportsTTS(_config.model);
  }

  /// Get the default TTS model.
  String get defaultTTSModel => _defaultTTSModel;

  /// Create a simple TTS request.
  GoogleTTSRequest createSimpleRequest({
    required String text,
    String voiceName = 'Kore',
    String? model,
  }) {
    return GoogleTTSRequest.singleSpeaker(
      text: text,
      voiceName: voiceName,
      model: model ?? _defaultTTSModel,
    );
  }

  /// Create a multi-speaker TTS request.
  GoogleTTSRequest createMultiSpeakerRequest({
    required String text,
    required Map<String, String> speakerVoices,
    String? model,
  }) {
    final speakers = speakerVoices.entries
        .map(
          (entry) => GoogleSpeakerVoiceConfig(
            speaker: entry.key,
            voiceConfig: GoogleVoiceConfig.prebuilt(entry.value),
          ),
        )
        .toList();

    return GoogleTTSRequest.multiSpeaker(
      text: text,
      speakers: speakers,
      model: model ?? _defaultTTSModel,
    );
  }

  String _resolveModel(GoogleTTSRequest request) {
    return request.model ?? _config.model;
  }

  String _generateContentEndpoint(String model) {
    return 'models/$model:generateContent';
  }

  String _streamGenerateContentEndpoint(String model) {
    return 'models/$model:streamGenerateContent';
  }

  bool _supportsTTS(String model) {
    return model.contains('tts') || model.contains('gemini-2.5');
  }
}
