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

  final modelId = Platform.environment['ELEVENLABS_SPEECH_MODEL'] ??
      'eleven_multilingual_v2';
  final outputPath = Platform.environment['ELEVENLABS_OUTPUT_PATH'] ??
      'elevenlabs_example.mp3';

  final model = elevenlabs_pkg
      .elevenLabs(
        apiKey: apiKey,
      )
      .speechModel(modelId);

  final result = await core.generateSpeech(
    model: model,
    text: 'Hello from llm_dart ElevenLabs examples.',
  );

  await File(outputPath).writeAsBytes(result.audioBytes);

  print('model=$modelId');
  print('saved=$outputPath');
  print('audioBytes=${result.audioBytes.length}');
}
