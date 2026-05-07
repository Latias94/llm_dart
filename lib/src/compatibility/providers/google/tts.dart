import 'dart:convert';

import '../../../../core/capability.dart';
import '../../../../core/llm_error.dart';
import '../../../../models/google_tts_models.dart';
import 'client.dart';
import '../../../../providers/google/config.dart';

export '../../../../models/google_tts_models.dart';

part 'google_tts_request_support.dart';
part 'google_tts_speech_support.dart';
part 'google_tts_stream_support.dart';

/// Google TTS implementation.
///
/// This class implements Google's native text-to-speech capabilities
/// using the Gemini API with audio output modality.
class GoogleTTS implements GoogleTTSCapability {
  final GoogleClient _client;
  final GoogleConfig _config;
  static const _requestSupport = _GoogleTTSRequestSupport();
  static const _speechSupport = _GoogleTTSSpeechSupport();
  static const _streamSupport = GoogleTTSStreamSupport();

  GoogleTTS(this._client, this._config);

  @override
  Future<GoogleTTSResponse> generateSpeech(GoogleTTSRequest request) async {
    return _speechSupport.generateSpeech(
      client: _client,
      config: _config,
      requestSupport: _requestSupport,
      request: request,
    );
  }

  @override
  Stream<GoogleTTSStreamEvent> generateSpeechStream(
    GoogleTTSRequest request,
  ) async* {
    final requestBody = request.toJson();
    final model = _requestSupport.resolveModel(request, _config);
    final endpoint = _requestSupport.streamGenerateContentEndpoint(model);

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
    return _requestSupport.supportsTTS(_config.model);
  }

  /// Get the default TTS model.
  String get defaultTTSModel => _requestSupport.defaultTTSModel;

  /// Create a simple TTS request.
  GoogleTTSRequest createSimpleRequest({
    required String text,
    String voiceName = 'Kore',
    String? model,
  }) {
    return _requestSupport.createSimpleRequest(
      text: text,
      voiceName: voiceName,
      model: model,
    );
  }

  /// Create a multi-speaker TTS request.
  GoogleTTSRequest createMultiSpeakerRequest({
    required String text,
    required Map<String, String> speakerVoices,
    String? model,
  }) {
    return _requestSupport.createMultiSpeakerRequest(
      text: text,
      speakerVoices: speakerVoices,
      model: model,
    );
  }
}
