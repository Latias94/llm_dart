import 'package:llm_dart_transport/dio.dart';

import '../../../../core/llm_error.dart';
import '../../../../models/audio_models.dart';
import '../../../../providers/openai/config.dart';
import '../../../config/provider_defaults.dart';
import 'config_views.dart';
import 'openai_audio_translation_models.dart';

part 'openai_audio_form_support.dart';
part 'openai_audio_speech_support.dart';
part 'openai_audio_transcription_support.dart';
part 'openai_audio_translation_support.dart';

/// Request/response helpers for the OpenAI compatibility audio facade.
class OpenAIAudioSupport {
  final OpenAIConfig config;
  static const _speechSupport = _OpenAIAudioSpeechSupport();
  static const _transcriptionSupport = _OpenAIAudioTranscriptionSupport();
  static const _translationSupport = _OpenAIAudioTranslationSupport();

  OpenAIAudioSupport(this.config);

  ({Map<String, dynamic> body, String voice, String contentType})
      buildSpeechRequest(TTSRequest request) {
    return _speechSupport.buildSpeechRequest(request, config);
  }

  TTSResponse buildSpeechResponse({
    required TTSRequest request,
    required List<int> audioData,
    required String voice,
    required String contentType,
  }) {
    return _speechSupport.buildSpeechResponse(
      request: request,
      audioData: audioData,
      voice: voice,
      contentType: contentType,
    );
  }

  Future<FormData> buildTranscriptionFormData(STTRequest request) async {
    return _transcriptionSupport.buildTranscriptionFormData(request);
  }

  STTResponse buildTranscriptionResponse(
    STTRequest request,
    Map<String, dynamic> responseData,
  ) {
    return _transcriptionSupport.buildTranscriptionResponse(
      request,
      responseData,
    );
  }

  Future<FormData> buildTranslationFormData(
    AudioTranslationRequest request,
  ) async {
    return _translationSupport.buildTranslationFormData(request);
  }

  STTResponse buildTranslationResponse(
    AudioTranslationRequest request,
    Map<String, dynamic> responseData,
  ) {
    return _translationSupport.buildTranslationResponse(request, responseData);
  }
}
