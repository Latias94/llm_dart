import 'package:llm_dart_core/llm_dart_core.dart';

import 'types.dart';

/// Transcribe speech to text using a provider-agnostic capability.
Future<TranscribeResult> transcribe({
  required SpeechToTextCapability model,
  required STTRequest request,
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) async {
  final STTResponse response;

  if (callOptions.isEmpty) {
    response = await model.speechToText(request, cancelToken: cancelToken);
  } else {
    if (model is! SpeechToTextCallOptionsCapability) {
      throw const InvalidRequestError(
        'This model does not support call-level overrides (headers/body) for transcription. '
        'Implement `SpeechToTextCallOptionsCapability` (or use a provider that does).',
      );
    }

    response = await (model as SpeechToTextCallOptionsCapability)
        .speechToTextWithCallOptions(
      request,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  return TranscribeResult(rawResponse: response);
}

/// Convenience helper to transcribe from audio bytes.
Future<TranscribeResult> transcribeFromAudioBytes({
  required SpeechToTextCapability model,
  required List<int> audioData,
  String? modelId,
  String? language,
  String? format,
  bool includeWordTiming = false,
  bool includeConfidence = false,
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) {
  return transcribe(
    model: model,
    request: STTRequest(
      audioData: audioData,
      model: modelId,
      language: language,
      format: format,
      includeWordTiming: includeWordTiming,
      includeConfidence: includeConfidence,
    ),
    callOptions: callOptions,
    cancelToken: cancelToken,
  );
}

/// Convenience helper to transcribe from a local file path.
Future<TranscribeResult> transcribeFromFile({
  required SpeechToTextCapability model,
  required String filePath,
  String? modelId,
  String? language,
  String? format,
  bool includeWordTiming = false,
  bool includeConfidence = false,
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) {
  return transcribe(
    model: model,
    request: STTRequest(
      filePath: filePath,
      model: modelId,
      language: language,
      format: format,
      includeWordTiming: includeWordTiming,
      includeConfidence: includeConfidence,
    ),
    callOptions: callOptions,
    cancelToken: cancelToken,
  );
}

/// Translate audio to English (when supported by the provider).
Future<TranscribeResult> translateAudio({
  required AudioTranslationCapability model,
  required AudioTranslationRequest request,
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) async {
  final STTResponse response;

  if (callOptions.isEmpty) {
    response = await model.translateAudio(request, cancelToken: cancelToken);
  } else {
    if (model is! AudioTranslationCallOptionsCapability) {
      throw const InvalidRequestError(
        'This model does not support call-level overrides (headers/body) for audio translation. '
        'Implement `AudioTranslationCallOptionsCapability` (or use a provider that does).',
      );
    }

    response = await (model as AudioTranslationCallOptionsCapability)
        .translateAudioWithCallOptions(
      request,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  return TranscribeResult(rawResponse: response);
}
