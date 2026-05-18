// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart' as elevenlabs_pkg;
import 'package:llm_dart_ai/llm_dart_ai.dart' as core;

Future<void> main() async {
  final apiKey = Platform.environment['ELEVENLABS_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln('Set ELEVENLABS_API_KEY before running this example.');
    exitCode = 1;
    return;
  }

  final audioFilePath = Platform.environment['ELEVENLABS_AUDIO_FILE'];
  if (audioFilePath == null || audioFilePath.isEmpty) {
    stderr.writeln(
      'Set ELEVENLABS_AUDIO_FILE to a local audio file path before running this example.',
    );
    exitCode = 1;
    return;
  }

  final audioFile = File(audioFilePath);
  if (!await audioFile.exists()) {
    stderr.writeln('Audio file not found: $audioFilePath');
    exitCode = 1;
    return;
  }

  final modelId =
      Platform.environment['ELEVENLABS_TRANSCRIPTION_MODEL'] ?? 'scribe_v1';
  final audioBytes = await audioFile.readAsBytes();
  final mediaType = _detectMediaType(audioFile.path);
  if (mediaType == null) {
    stderr.writeln(
      'Unsupported audio file extension. Use mp3, wav, m4a, ogg, or webm.',
    );
    exitCode = 1;
    return;
  }

  final model = elevenlabs_pkg
      .elevenLabs(
        apiKey: apiKey,
      )
      .transcriptionModel(modelId);

  final result = await core.transcribe(
    model: model,
    audioBytes: audioBytes,
    mediaType: mediaType,
  );

  print('model=$modelId');
  print(result.text);
}

String? _detectMediaType(String path) {
  final lowerPath = path.toLowerCase();

  if (lowerPath.endsWith('.mp3')) {
    return 'audio/mpeg';
  }
  if (lowerPath.endsWith('.wav')) {
    return 'audio/wav';
  }
  if (lowerPath.endsWith('.m4a')) {
    return 'audio/mp4';
  }
  if (lowerPath.endsWith('.ogg')) {
    return 'audio/ogg';
  }
  if (lowerPath.endsWith('.webm')) {
    return 'audio/webm';
  }

  return null;
}
