import 'dart:typed_data';

import 'package:llm_dart_community/llm_dart_community.dart' as modern_community;
import 'package:llm_dart_provider/llm_dart_provider.dart' show ProviderMetadata;
import 'package:llm_dart_transport/dio.dart';

import '../../../../models/audio_models.dart';
import '../../../../providers/elevenlabs/config.dart';
import 'elevenlabs_audio_catalog.dart';

part 'elevenlabs_audio_form_support.dart';
part 'elevenlabs_audio_request_support.dart';
part 'elevenlabs_audio_response_support.dart';

/// Provider-local request and response shaping for ElevenLabs audio compatibility.
final class ElevenLabsAudioSupport {
  static const supportedLanguages = ElevenLabsAudioCatalog.supportedLanguages;

  static const _requestSupport = _ElevenLabsAudioRequestSupport();
  static const _formSupport = _ElevenLabsAudioFormSupport();
  static const _responseSupport = _ElevenLabsAudioResponseSupport();

  const ElevenLabsAudioSupport();

  Map<String, dynamic> buildTextToSpeechRequestBody(
    TTSRequest request, {
    required ElevenLabsConfig config,
    required String effectiveModel,
  }) {
    return _requestSupport.buildTextToSpeechRequestBody(
      request,
      config: config,
      effectiveModel: effectiveModel,
    );
  }

  Map<String, String> buildTextToSpeechQueryParams(TTSRequest request) {
    return _requestSupport.buildTextToSpeechQueryParams(request);
  }

  TTSResponse buildTextToSpeechResponse(
    Uint8List audioData, {
    required TTSRequest request,
    String? contentType,
  }) {
    return _responseSupport.buildTextToSpeechResponse(
      audioData,
      request: request,
      contentType: contentType,
    );
  }

  Future<FormData> buildSpeechToTextFormDataFromBytes(
    List<int> audioData, {
    required STTRequest request,
    required String effectiveModel,
  }) async {
    return _formSupport.buildSpeechToTextFormDataFromBytes(
      audioData,
      request: request,
      effectiveModel: effectiveModel,
    );
  }

  Future<FormData> buildSpeechToTextFormDataFromFile(
    String filePath, {
    required STTRequest request,
    required String effectiveModel,
  }) async {
    return _formSupport.buildSpeechToTextFormDataFromFile(
      filePath,
      request: request,
      effectiveModel: effectiveModel,
    );
  }

  Future<FormData> buildSpeechToTextFormDataFromSourceUrl(
    String sourceUrl, {
    required STTRequest request,
    required String effectiveModel,
  }) async {
    return _formSupport.buildSpeechToTextFormDataFromSourceUrl(
      sourceUrl,
      request: request,
      effectiveModel: effectiveModel,
    );
  }

  Map<String, String>? buildSpeechToTextQueryParams(STTRequest request) {
    return _requestSupport.buildSpeechToTextQueryParams(request);
  }

  STTResponse parseSpeechToTextResponse(
    Map<String, dynamic> responseData, {
    required STTRequest request,
  }) {
    return _responseSupport.parseSpeechToTextResponse(
      responseData,
      request: request,
    );
  }

  List<VoiceInfo> mapVoices(List<Map<String, dynamic>> rawVoices) {
    return _responseSupport.mapVoices(rawVoices);
  }
}

modern_community.ElevenLabsSpeechOptions? _resolveElevenLabsSpeechOptions(
  Object? options,
) {
  if (options == null) {
    return null;
  }
  if (options is modern_community.ElevenLabsSpeechOptions) {
    return options;
  }
  throw ArgumentError.value(
    options,
    'providerOptions',
    'Expected ElevenLabsSpeechOptions for ElevenLabs speech requests.',
  );
}

modern_community.ElevenLabsTranscriptionOptions?
    _resolveElevenLabsTranscriptionOptions(Object? options) {
  if (options == null) {
    return null;
  }
  if (options is modern_community.ElevenLabsTranscriptionOptions) {
    return options;
  }
  throw ArgumentError.value(
    options,
    'providerOptions',
    'Expected ElevenLabsTranscriptionOptions for ElevenLabs transcription requests.',
  );
}
