/// High-level audio helpers (TTS/STT) built on LLMBuilder + AudioCapability.
library;

import 'package:llm_dart_core/llm_dart_core.dart';
export 'package:llm_dart_ai/llm_dart_ai.dart'
    show
        generateSpeechWithModel,
        transcribeWithModel,
        transcribeFileWithModel,
        translateWithModel,
        translateFileWithModel;

import 'builder/llm_builder.dart';
import 'src/builtin_providers.dart' show registerBuiltinProviders;

/// High-level text-to-speech helper (Vercel AI SDK-style).
///
/// Builds an [AudioCapability] for the given `model` identifier and
/// returns raw audio bytes for the synthesized speech.
Future<List<int>> generateSpeech({
  required String model,
  required String text,
  String? apiKey,
  String? baseUrl,
  CancellationToken? cancelToken,
}) async {
  registerBuiltinProviders();
  var builder = LLMBuilder().use(model);

  if (apiKey != null) {
    builder = builder.apiKey(apiKey);
  }
  if (baseUrl != null) {
    builder = builder.baseUrl(baseUrl);
  }

  final audioProvider = await builder.buildAudio();
  return audioProvider.speech(text, cancelToken: cancelToken);
}

/// High-level transcription helper for in-memory audio.
///
/// Builds an [AudioCapability] for the given `model` identifier and
/// returns the transcribed text for the provided audio bytes.
Future<String> transcribe({
  required String model,
  required List<int> audio,
  String? apiKey,
  String? baseUrl,
  CancellationToken? cancelToken,
}) async {
  registerBuiltinProviders();
  var builder = LLMBuilder().use(model);

  if (apiKey != null) {
    builder = builder.apiKey(apiKey);
  }
  if (baseUrl != null) {
    builder = builder.baseUrl(baseUrl);
  }

  final audioProvider = await builder.buildAudio();
  // AudioCapability.transcribe(...) is a convenience wrapper around
  // speechToText(STTRequest.fromAudio).
  return audioProvider.transcribe(audio);
}

/// High-level transcription helper for audio files.
///
/// This variant accepts a file path and uses the underlying audio
/// provider's `transcribeFile(...)` convenience method.
///
/// Note: On web, file-path based transcription is typically not supported.
/// Prefer [transcribe] with in-memory audio bytes.
Future<String> transcribeFile({
  required String model,
  required String filePath,
  String? apiKey,
  String? baseUrl,
  CancellationToken? cancelToken,
}) async {
  registerBuiltinProviders();
  var builder = LLMBuilder().use(model);

  if (apiKey != null) {
    builder = builder.apiKey(apiKey);
  }
  if (baseUrl != null) {
    builder = builder.baseUrl(baseUrl);
  }

  final audioProvider = await builder.buildAudio();
  return audioProvider.transcribeFile(filePath);
}
