import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

/// OpenAI Audio Capabilities Example
///
/// This example demonstrates the unified AudioCapability interface
/// with OpenAI's text-to-speech, speech-to-text, and audio translation features.
Future<void> main() async {
  // Get API key from environment
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null) {
    print('❌ Please set OPENAI_API_KEY environment variable');
    return;
  }

  print('🤖 OpenAI Audio Capabilities Demo\n');

  // Create OpenAI provider
  final provider = await ai().openai().apiKey(apiKey).model('gpt-4o').build();

  // Check if provider supports audio capabilities
  if (provider is! AudioCapability) {
    print('❌ Provider does not support audio capabilities');
    return;
  }

  final audioProvider = provider as AudioCapability;

  // Display supported features
  await displaySupportedFeatures(audioProvider);

  // Test Text-to-Speech
  await testTextToSpeech(audioProvider);

  // Test Speech-to-Text
  await testSpeechToText(audioProvider);

  // Test Audio Translation
  await testAudioTranslation(audioProvider);

  print('✅ OpenAI audio capabilities demo completed!');
}

/// Display supported audio features
Future<void> displaySupportedFeatures(AudioCapability provider) async {
  print('🔍 Supported Audio Features:');
  final features = provider.supportedFeatures;

  for (final feature in AudioFeature.values) {
    final supported = features.contains(feature);
    final icon = supported ? '✅' : '❌';
    print('   $icon ${feature.name}');
  }

  print('\n📋 Available Audio Formats:');
  final formats = provider.getSupportedAudioFormats();
  for (final format in formats) {
    print('   • $format');
  }
  print('');
}

/// Test Text-to-Speech functionality
Future<void> testTextToSpeech(AudioCapability provider) async {
  if (!provider.supportedFeatures.contains(AudioFeature.textToSpeech)) {
    print('⏭️  Skipping TTS - not supported\n');
    return;
  }

  print('🎵 Testing Text-to-Speech');

  try {
    // Get available voices
    final voices = await provider.getVoices();
    print('   📢 Available voices: ${voices.map((v) => v.name).join(', ')}');

    // Basic TTS
    print('   🔄 Generating basic speech...');
    final basicTTS = await provider.textToSpeech(TTSRequest(
      text: 'Hello! This is OpenAI text-to-speech in action.',
      voice: 'alloy',
      format: 'mp3',
      speed: 1.0,
    ));

    await File('openai_basic.mp3').writeAsBytes(basicTTS.audioData);
    print(
        '   ✅ Basic TTS: ${basicTTS.audioData.length} bytes → openai_basic.mp3');

    // Advanced TTS with instructions
    print('   🔄 Generating dramatic speech...');
    final dramaticTTS = await provider.textToSpeech(TTSRequest(
      text: 'Welcome to the future of artificial intelligence!',
      voice: 'nova',
      format: 'wav',
      instructions: 'Speak in an enthusiastic, dramatic voice',
      speed: 0.9,
    ));

    await File('openai_dramatic.wav').writeAsBytes(dramaticTTS.audioData);
    print(
        '   ✅ Dramatic TTS: ${dramaticTTS.audioData.length} bytes → openai_dramatic.wav');

    // Test convenience method
    final quickSpeech =
        await provider.speech('Quick test using convenience method');
    await File('openai_quick.mp3').writeAsBytes(quickSpeech);
    print('   ✅ Quick speech: ${quickSpeech.length} bytes → openai_quick.mp3');
  } catch (e) {
    print('   ❌ TTS failed: $e');
  }
  print('');
}

/// Test Speech-to-Text functionality
Future<void> testSpeechToText(AudioCapability provider) async {
  if (!provider.supportedFeatures.contains(AudioFeature.speechToText)) {
    print('⏭️  Skipping STT - not supported\n');
    return;
  }

  print('🎤 Testing Speech-to-Text');

  try {
    // Get supported languages
    final languages = await provider.getSupportedLanguages();
    print('   🌍 Supported languages: ${languages.length} languages');

    // Test with generated audio file
    if (await File('openai_basic.mp3').exists()) {
      print('   🔄 Transcribing generated audio...');

      // Basic transcription
      final basicSTT = await provider.speechToText(STTRequest.fromFile(
        'openai_basic.mp3',
        model: 'whisper-1',
        includeWordTiming: true,
        responseFormat: 'verbose_json',
      ));

      print('   📝 Transcription: "${basicSTT.text}"');
      print('   🌍 Detected language: ${basicSTT.language ?? "unknown"}');
      print('   ⏱️  Duration: ${basicSTT.duration ?? "unknown"}s');

      if (basicSTT.words != null && basicSTT.words!.isNotEmpty) {
        print('   📊 Word timing (first 3 words):');
        for (final word in basicSTT.words!.take(3)) {
          print('      "${word.word}" (${word.start}s - ${word.end}s)');
        }
      }

      // Test convenience method
      final quickTranscription =
          await provider.transcribeFile('openai_basic.mp3');
      print('   ✅ Quick transcription: "$quickTranscription"');
    } else {
      print('   ⚠️  No audio file found for transcription test');
    }
  } catch (e) {
    print('   ❌ STT failed: $e');
  }
  print('');
}

/// Test Audio Translation functionality
Future<void> testAudioTranslation(AudioCapability provider) async {
  if (!provider.supportedFeatures.contains(AudioFeature.audioTranslation)) {
    print('⏭️  Skipping audio translation - not supported\n');
    return;
  }

  print('🌐 Testing Audio Translation');

  try {
    // For demo purposes, we'll use the English audio file
    // In practice, you'd use non-English audio
    if (await File('openai_basic.mp3').exists()) {
      print('   🔄 Translating audio to English...');

      final translation = await provider.translateAudio(
        AudioTranslationRequest.fromFile(
          'openai_basic.mp3',
          model: 'whisper-1',
          responseFormat: 'json',
        ),
      );

      print('   🌐 Translation: "${translation.text}"');
      print('   🌍 Target language: English (always)');

      // Test convenience method
      final quickTranslation = await provider.translateFile('openai_basic.mp3');
      print('   ✅ Quick translation: "$quickTranslation"');
    } else {
      print('   ⚠️  No audio file found for translation test');
    }
  } catch (e) {
    print('   ❌ Audio translation failed: $e');
  }
  print('');
}
