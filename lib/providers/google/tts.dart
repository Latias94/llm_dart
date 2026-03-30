import 'dart:convert';

import '../../core/capability.dart';
import '../../core/llm_error.dart';
import '../../models/google_tts_models.dart';
import 'client.dart';
import 'config.dart';

export '../../models/google_tts_models.dart';

/// Google TTS implementation.
///
/// This class implements Google's native text-to-speech capabilities
/// using the Gemini API with audio output modality.
class GoogleTTS implements GoogleTTSCapability {
  final GoogleClient _client;
  final GoogleConfig _config;

  GoogleTTS(this._client, this._config);

  @override
  Future<GoogleTTSResponse> generateSpeech(GoogleTTSRequest request) async {
    try {
      final requestBody = request.toJson();
      final model = request.model ?? _config.model;

      final response = await _client.post(
        'models/$model:generateContent',
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
    try {
      final requestBody = request.toJson();
      final model = request.model ?? _config.model;

      final stream = _client.postStream(
        'models/$model:streamGenerateContent',
        data: requestBody,
      );

      await for (final chunk in stream) {
        try {
          final data = chunk.data;
          if (data is Map<String, dynamic>) {
            final candidate = data['candidates']?[0];
            final content = candidate?['content'];
            final parts = content?['parts'];
            final inlineData = parts?[0]?['inlineData'];
            final audioData = inlineData?['data'] as String?;

            if (audioData != null) {
              yield GoogleTTSAudioDataEvent(data: base64.decode(audioData));
            }

            if (candidate?['finishReason'] != null) {
              final response = GoogleTTSResponse.fromApiResponse(data);
              yield GoogleTTSCompletionEvent(response);
            }
          }
        } catch (e) {
          yield GoogleTTSErrorEvent(
            message: 'Error processing stream chunk: $e',
          );
        }
      }
    } catch (e) {
      yield GoogleTTSErrorEvent(message: 'Google TTS streaming failed: $e');
    }
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
    final model = _config.model;
    return model.contains('tts') || model.contains('gemini-2.5');
  }

  /// Get the default TTS model.
  String get defaultTTSModel => 'gemini-2.5-flash-preview-tts';

  /// Create a simple TTS request.
  GoogleTTSRequest createSimpleRequest({
    required String text,
    String voiceName = 'Kore',
    String? model,
  }) {
    return GoogleTTSRequest.singleSpeaker(
      text: text,
      voiceName: voiceName,
      model: model ?? defaultTTSModel,
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
      model: model ?? defaultTTSModel,
    );
  }
}
