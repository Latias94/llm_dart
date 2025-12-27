import 'package:llm_dart_core/core/capability.dart';
import 'package:llm_dart_core/core/cancellation.dart';
import 'package:llm_dart_core/models/audio_models.dart';

import 'types.dart';

/// Generate speech audio (TTS) using a provider-agnostic capability.
Future<GenerateSpeechResult> generateSpeech({
  required AudioCapability model,
  required TTSRequest request,
  CancelToken? cancelToken,
}) async {
  final response = await model.textToSpeech(request, cancelToken: cancelToken);
  return GenerateSpeechResult(rawResponse: response);
}

/// Convenience helper to generate speech from plain text.
Future<GenerateSpeechResult> generateSpeechFromText({
  required AudioCapability model,
  required String text,
  String? voice,
  String? modelId,
  String? format,
  int? sampleRate,
  String? languageCode,
  CancelToken? cancelToken,
}) {
  return generateSpeech(
    model: model,
    request: TTSRequest(
      text: text,
      voice: voice,
      model: modelId,
      format: format,
      sampleRate: sampleRate,
      languageCode: languageCode,
    ),
    cancelToken: cancelToken,
  );
}

/// Stream speech audio (TTS) as provider-agnostic audio stream events.
Stream<AudioStreamEvent> streamSpeech({
  required AudioCapability model,
  required TTSRequest request,
  CancelToken? cancelToken,
}) {
  return model.textToSpeechStream(request, cancelToken: cancelToken);
}

/// Convenience helper to stream speech from plain text.
Stream<AudioStreamEvent> streamSpeechFromText({
  required AudioCapability model,
  required String text,
  String? voice,
  String? modelId,
  String? format,
  int? sampleRate,
  String? languageCode,
  CancelToken? cancelToken,
}) {
  return streamSpeech(
    model: model,
    request: TTSRequest(
      text: text,
      voice: voice,
      model: modelId,
      format: format,
      sampleRate: sampleRate,
      languageCode: languageCode,
      processingMode: AudioProcessingMode.streaming,
    ),
    cancelToken: cancelToken,
  );
}
