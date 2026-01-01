import 'package:llm_dart_core/llm_dart_core.dart';

import 'types.dart';

/// Generate speech audio (TTS) using a provider-agnostic capability.
Future<GenerateSpeechResult> generateSpeech({
  required TextToSpeechCapability model,
  required TTSRequest request,
  CancelToken? cancelToken,
}) async {
  final response = await model.textToSpeech(request, cancelToken: cancelToken);
  return GenerateSpeechResult(rawResponse: response);
}

/// Convenience helper to generate speech from plain text.
Future<GenerateSpeechResult> generateSpeechFromText({
  required TextToSpeechCapability model,
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
  required StreamingTextToSpeechCapability model,
  required TTSRequest request,
  CancelToken? cancelToken,
}) {
  return model.textToSpeechStream(request, cancelToken: cancelToken);
}

/// Convenience helper to stream speech from plain text.
Stream<AudioStreamEvent> streamSpeechFromText({
  required StreamingTextToSpeechCapability model,
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
