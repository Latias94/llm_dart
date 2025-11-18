import 'dart:io';

import 'package:llm_dart/llm_dart.dart';

/// Google Gemini multimodal audio & video understanding example.
///
/// This example shows how to:
/// - Send an audio file together with a text prompt.
/// - Send a video URL together with a text prompt.
///
/// It uses the ChatPromptBuilder helpers for audio/video parts and
/// the native Google (Gemini) provider.
Future<void> main() async {
  print('🎧🎬 Google Gemini Multimodal Audio & Video Example\n');

  final apiKey = Platform.environment['GOOGLE_API_KEY'];
  if (apiKey == null) {
    print('❌ Please set GOOGLE_API_KEY environment variable');
    print('   Get your API key from: https://aistudio.google.com/app/apikey');
    return;
  }

  // Optional: local audio file path (e.g. WAV/MP3).
  final audioPath =
      Platform.environment['GEMINI_AUDIO_FILE'] ?? 'sample_audio.wav';

  // Example video URL. Replace with your own if needed.
  final videoUrl = Platform.environment['GEMINI_VIDEO_URL'] ??
      'https://storage.googleapis.com/generativeai-downloads/data/GoogleIO2023_Keynote.mp4';

  // Build a Gemini provider that can handle multimodal inputs.
  final provider =
      await ai().google().apiKey(apiKey).model('gemini-2.5-flash').build();

  await _runAudioExample(provider, audioPath);
  await _runVideoExample(provider, videoUrl);
}

Future<void> _runAudioExample(ChatCapability provider, String audioPath) async {
  print('=== Audio Understanding ===');

  if (!File(audioPath).existsSync()) {
    print('⚠️  Audio file not found: $audioPath');
    print(
        '    Set GEMINI_AUDIO_FILE or place sample_audio.wav next to this file.');
    return;
  }

  final bytes = await File(audioPath).readAsBytes();

  final prompt = ChatPromptBuilder.user()
      .text('请先转录这段音频内容，然后用中文总结出三个要点。')
      .audioBytes(
        bytes,
        mime: audioPath.toLowerCase().endsWith('.wav')
            ? FileMime.wav
            : FileMime.mp3,
        filename: audioPath,
      )
      .build();

  final response = await provider.chat([
    // Convert the structured prompt into a ChatMessage that
    // preserves all content parts for providers that consume
    // ChatPromptMessage internally (e.g. Gemini).
    ChatMessage.fromPromptMessage(prompt),
  ]);

  print('--- Audio Response ---');
  print(response.text);
}

Future<void> _runVideoExample(ChatCapability provider, String videoUrl) async {
  print('\n=== Video Understanding ===');

  final prompt = ChatPromptBuilder.user()
      .text('请根据这个视频的大致内容，用中文总结演讲的主题和两个关键点。')
      .videoUrl(
        videoUrl,
        mime: FileMime.mp4,
      )
      .build();

  final response = await provider.chat([
    ChatMessage.fromPromptMessage(prompt),
  ]);

  print('--- Video Response ---');
  print(response.text);
}
