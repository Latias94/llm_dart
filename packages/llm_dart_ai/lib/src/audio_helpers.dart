// High-level audio helpers that operate on AudioCapability instances.

library;

import 'package:llm_dart_core/llm_dart_core.dart';

/// Text-to-speech using an existing [AudioCapability] instance.
///
/// This helper is useful when you create speech models via provider facades:
/// ```dart
/// final elevenlabs = createElevenLabs(apiKey: apiKey);
/// final speech = elevenlabs.speech('eleven_multilingual_v2');
/// final bytes = await generateSpeechWithModel(speech, text: 'Hello');
/// ```
Future<List<int>> generateSpeechWithModel(
  AudioCapability model, {
  required String text,
  CancellationToken? cancelToken,
}) async {
  final response = await model.textToSpeech(
    TTSRequest(text: text),
    cancelToken: cancelToken,
  );
  return response.audioData;
}

/// Speech-to-text using an existing [AudioCapability] instance.
Future<String> transcribeWithModel(
  AudioCapability model, {
  required List<int> audio,
  CancellationToken? cancelToken,
}) async {
  final response = await model.speechToText(
    STTRequest.fromAudio(audio),
    cancelToken: cancelToken,
  );
  return response.text;
}

/// Speech-to-text for file paths using an existing [AudioCapability] instance.
Future<String> transcribeFileWithModel(
  AudioCapability model, {
  required String filePath,
  CancellationToken? cancelToken,
}) async {
  final response = await model.speechToText(
    STTRequest.fromFile(filePath),
    cancelToken: cancelToken,
  );
  return response.text;
}

/// Audio translation (to English) using an existing [AudioCapability] instance.
Future<String> translateWithModel(
  AudioCapability model, {
  required List<int> audio,
  CancellationToken? cancelToken,
}) async {
  final response = await model.translateAudio(
    AudioTranslationRequest.fromAudio(audio),
    cancelToken: cancelToken,
  );
  return response.text;
}

/// Audio translation (to English) from a file path using an existing [AudioCapability] instance.
Future<String> translateFileWithModel(
  AudioCapability model, {
  required String filePath,
  CancellationToken? cancelToken,
}) async {
  final response = await model.translateAudio(
    AudioTranslationRequest.fromFile(filePath),
    cancelToken: cancelToken,
  );
  return response.text;
}
