import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

/// Audio processing examples using AudioCapability interface
///
/// This example demonstrates:
/// - Text-to-speech conversion
/// - Speech-to-text transcription
/// - Audio format handling
Future<void> main() async {
  print('🎵 Audio Processing Examples\n');

  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null) {
    print('❌ Please set OPENAI_API_KEY environment variable');
    return;
  }

  try {
    final provider = await ai().openai().apiKey(apiKey).buildAudio();

    await demonstrateTextToSpeech(provider, 'OpenAI');
    await demonstrateSpeechToText(provider, 'OpenAI');
  } catch (e) {
    print('❌ Failed to initialize audio processing: $e');
  }

  print('✅ Audio processing examples completed!');
}

/// Demonstrate text-to-speech functionality
Future<void> demonstrateTextToSpeech(
    AudioCapability provider, String providerName) async {
  print('🗣️ Text-to-Speech ($providerName):\n');

  try {
    final request = TTSRequest(
      text:
          'Hello! This is a demonstration of text-to-speech conversion using LLM Dart.',
      voice: 'alloy',
      format: 'mp3',
      speed: 1.0,
    );

    final response = await provider.textToSpeech(request);

    print('   ✅ Audio generated successfully');
    print('   📊 Audio data size: ${response.audioData.length} bytes');

    // Save audio to file
    final filename = 'tts_output_${DateTime.now().millisecondsSinceEpoch}.mp3';
    await File(filename).writeAsBytes(response.audioData);
    print('   💾 Saved audio to: $filename');
  } catch (e) {
    print('   ❌ Text-to-speech failed: $e');
  }
  print('');
}

/// Demonstrate speech-to-text functionality
Future<void> demonstrateSpeechToText(
    AudioCapability provider, String providerName) async {
  print('🎤 Speech-to-Text ($providerName):\n');

  try {
    // Note: In real usage, you would provide an actual audio file
    // For demo purposes, we'll show the API structure

    print('   📝 Speech-to-text API ready (provide audio file to test)');
    print('   Example usage:');
    print('   ```dart');
    print('   final audioBytes = await File("audio.mp3").readAsBytes();');
    print('   final request = STTRequest.fromAudio(audioBytes,');
    print('     language: "en",');
    print('     format: "mp3",');
    print('   );');
    print('   final response = await provider.speechToText(request);');
    print('   print("Transcription: \${response.text}");');
    print('   ```');

    // Uncomment to test with real audio file:
    // final audioBytes = await File('path/to/audio.mp3').readAsBytes();
    // final request = STTRequest.fromAudio(audioBytes,
    //   language: 'en',
    //   format: 'mp3',
    // );
    // final response = await provider.speechToText(request);
    // print('   📝 Transcription: ${response.text}');
  } catch (e) {
    print('   ❌ Speech-to-text failed: $e');
  }
  print('');
}
