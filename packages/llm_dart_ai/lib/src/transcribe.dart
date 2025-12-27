import 'package:llm_dart_core/core/capability.dart';
import 'package:llm_dart_core/core/cancellation.dart';
import 'package:llm_dart_core/models/audio_models.dart';

import 'types.dart';

/// Transcribe speech to text using a provider-agnostic capability.
Future<TranscribeResult> transcribe({
  required AudioCapability model,
  required STTRequest request,
  CancelToken? cancelToken,
}) async {
  final response = await model.speechToText(request, cancelToken: cancelToken);
  return TranscribeResult(rawResponse: response);
}

/// Convenience helper to transcribe from audio bytes.
Future<TranscribeResult> transcribeFromAudioBytes({
  required AudioCapability model,
  required List<int> audioData,
  String? modelId,
  String? language,
  String? format,
  bool includeWordTiming = false,
  bool includeConfidence = false,
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
    cancelToken: cancelToken,
  );
}

/// Convenience helper to transcribe from a local file path.
Future<TranscribeResult> transcribeFromFile({
  required AudioCapability model,
  required String filePath,
  String? modelId,
  String? language,
  String? format,
  bool includeWordTiming = false,
  bool includeConfidence = false,
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
    cancelToken: cancelToken,
  );
}

/// Translate audio to English (when supported by the provider).
Future<TranscribeResult> translateAudio({
  required AudioCapability model,
  required AudioTranslationRequest request,
  CancelToken? cancelToken,
}) async {
  final response =
      await model.translateAudio(request, cancelToken: cancelToken);
  return TranscribeResult(rawResponse: response);
}
