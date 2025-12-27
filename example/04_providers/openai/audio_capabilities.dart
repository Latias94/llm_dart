import 'dart:io';

import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';

/// OpenAI Audio Tasks Example
///
/// This example demonstrates task-specific audio capabilities:
/// - Text-to-Speech (TTS)
/// - Speech-to-Text (STT)
/// - Audio Translation
///
/// Note: Prefer task-level capabilities (TTS/STT/translation) to match the
/// Vercel AI SDK style.
Future<void> main() async {
  registerOpenAI();

  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set OPENAI_API_KEY environment variable');
    return;
  }

  print('🤖 OpenAI Audio Tasks Demo\n');

  final ttsProvider = await LLMBuilder()
      .provider(openaiProviderId)
      .apiKey(apiKey)
      .model('gpt-4o')
      .buildSpeech();

  final sttBuilder = LLMBuilder()
      .provider(openaiProviderId)
      .apiKey(apiKey)
      .model('whisper-1');

  final sttProvider = await sttBuilder.buildTranscription();
  final translationProvider = await sttBuilder.buildAudioTranslation();

  await displayCapabilities(ttsProvider, sttProvider, translationProvider);
  await testTextToSpeech(ttsProvider);
  await testSpeechToText(sttProvider);
  await testAudioTranslation(translationProvider);

  print('✅ OpenAI audio tasks demo completed!');
}

Future<void> displayCapabilities(
  TextToSpeechCapability ttsProvider,
  SpeechToTextCapability sttProvider,
  AudioTranslationCapability translationProvider,
) async {
  print('🔍 Available Capabilities:');
  print('   ✅ Text-to-Speech');
  print('   ✅ Speech-to-Text');
  print('   ✅ Audio Translation');

  final VoiceListingCapability? voiceListing =
      ttsProvider is VoiceListingCapability
          ? (ttsProvider as VoiceListingCapability)
          : null;
  if (voiceListing != null) {
    try {
      final voices = await voiceListing.getVoices();
      print('   ✅ Voice listing (${voices.length} voices)');
    } catch (_) {
      print('   ⚠️ Voice listing (failed)');
    }
  } else {
    print('   ⏭️ Voice listing (not exposed)');
  }

  print('');
}

Future<void> testTextToSpeech(TextToSpeechCapability provider) async {
  print('🎵 Testing Text-to-Speech');

  try {
    final VoiceListingCapability? voiceListing =
        provider is VoiceListingCapability
            ? (provider as VoiceListingCapability)
            : null;
    if (voiceListing != null) {
      final voices = await voiceListing.getVoices();
      print('   📢 Available voices: ${voices.map((v) => v.name).join(', ')}');
    }

    print('   🔄 Generating basic speech...');
    final basicTTS = await provider.textToSpeech(const TTSRequest(
      text: 'Hello! This is OpenAI text-to-speech in action.',
      voice: 'alloy',
      format: 'mp3',
      speed: 1.0,
    ));

    await File('openai_basic.mp3').writeAsBytes(basicTTS.audioData);
    print(
        '   ✅ Basic TTS: ${basicTTS.audioData.length} bytes → openai_basic.mp3');

    print('   🔄 Generating dramatic speech...');
    final dramaticTTS = await provider.textToSpeech(const TTSRequest(
      text: 'Welcome to the future of artificial intelligence!',
      voice: 'nova',
      format: 'wav',
      instructions: 'Speak in an enthusiastic, dramatic voice',
      speed: 0.9,
    ));

    await File('openai_dramatic.wav').writeAsBytes(dramaticTTS.audioData);
    print(
        '   ✅ Dramatic TTS: ${dramaticTTS.audioData.length} bytes → openai_dramatic.wav');
  } catch (e) {
    print('   ❌ TTS failed: $e');
  }

  print('');
}

Future<void> testSpeechToText(SpeechToTextCapability provider) async {
  print('🎤 Testing Speech-to-Text');

  try {
    if (await File('openai_basic.mp3').exists()) {
      print('   🔄 Transcribing openai_basic.mp3...');

      final transcription = await provider.speechToText(
        STTRequest.fromFile(
          'openai_basic.mp3',
          model: 'whisper-1',
          responseFormat: 'verbose_json',
          includeWordTiming: true,
        ),
      );

      print('   📝 Transcription: "${transcription.text}"');
      print('   🌍 Language: ${transcription.language ?? "unknown"}');

      final words = transcription.words;
      if (words != null && words.isNotEmpty) {
        print('   ⏱️  Word timing (first 3 words):');
        for (final word in words.take(3)) {
          print('      "${word.word}" (${word.start}s - ${word.end}s)');
        }
      }
    } else {
      print('   ⚠️  No audio file found for transcription test (openai_basic.mp3)');
    }
  } catch (e) {
    print('   ❌ STT failed: $e');
  }

  print('');
}

Future<void> testAudioTranslation(AudioTranslationCapability provider) async {
  print('🌐 Testing Audio Translation');

  try {
    if (await File('openai_basic.mp3').exists()) {
      print('   🔄 Translating openai_basic.mp3 to English...');

      final translation = await provider.translateAudio(
        AudioTranslationRequest.fromFile(
          'openai_basic.mp3',
          model: 'whisper-1',
          responseFormat: 'json',
        ),
      );

      print('   🌐 Translation: "${translation.text}"');
      print('   🌍 Target language: English (always)');
    } else {
      print('   ⚠️  No audio file found for translation test (openai_basic.mp3)');
    }
  } catch (e) {
    print('   ❌ Audio translation failed: $e');
  }

  print('');
}
