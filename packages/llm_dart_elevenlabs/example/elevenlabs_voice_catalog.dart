// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart';

Future<void> main() async {
  final apiKey = Platform.environment['ELEVENLABS_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln('Set ELEVENLABS_API_KEY before running this example.');
    exitCode = 1;
    return;
  }

  final voices = await elevenLabs(apiKey: apiKey).voices().listVoices();

  print('ElevenLabs voices: ${voices.length}');
  for (final voice in voices.take(10)) {
    final label = [
      if (voice.gender != null) voice.gender,
      if (voice.accent != null) voice.accent,
      if (voice.category != null) voice.category,
    ].join(', ');
    print('- ${voice.name} (${voice.id})${label.isEmpty ? '' : ' - $label'}');
  }
}
