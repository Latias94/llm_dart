import 'dart:io';

import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart';

/// ElevenLabs Audio Tasks Example
///
/// This example demonstrates task-specific audio capabilities (Vercel-aligned):
/// - Text-to-Speech (TTS)
/// - Speech-to-Text (STT) (if available)
/// - Streaming TTS (if available)
/// - Realtime audio sessions (if available)
///
/// Note: Prefer task-level capabilities (TTS/STT/streaming) for composability.
Future<void> main() async {
  final apiKey = Platform.environment['ELEVENLABS_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set ELEVENLABS_API_KEY environment variable');
    return;
  }

  print('🎙️ ElevenLabs Audio Tasks Demo\n');

  registerElevenLabs();

  final builder = LLMBuilder()
      .provider(elevenLabsProviderId)
      .apiKey(apiKey)
      .providerOptions(elevenLabsProviderId, const {
    'voiceId': 'JBFqnCBsd6RMkjVDRZzb',
    'stability': 0.5,
    'similarityBoost': 0.75,
    'style': 0.2,
  });

  final ttsProvider = await builder.buildSpeech();

  StreamingTextToSpeechCapability? streamingTtsProvider;
  try {
    streamingTtsProvider = await builder.buildStreamingSpeech();
  } catch (_) {
    streamingTtsProvider = null;
  }

  SpeechToTextCapability? sttProvider;
  try {
    sttProvider = await builder.buildTranscription();
  } catch (_) {
    sttProvider = null;
  }

  RealtimeAudioCapability? realtimeProvider;
  try {
    realtimeProvider = await builder.buildRealtimeAudio();
  } catch (_) {
    realtimeProvider = null;
  }

  await displayCapabilities(
    ttsProvider,
    streamingTtsProvider: streamingTtsProvider,
    sttProvider: sttProvider,
    realtimeProvider: realtimeProvider,
  );

  await testTextToSpeech(ttsProvider);

  if (streamingTtsProvider != null) {
    await testStreamingTextToSpeech(streamingTtsProvider);
  }

  if (sttProvider != null) {
    await testSpeechToText(sttProvider);
  }

  if (realtimeProvider != null) {
    await testRealtimeAudio(realtimeProvider);
  }

  print('✅ ElevenLabs audio tasks demo completed!');
}

Future<void> displayCapabilities(
  TextToSpeechCapability ttsProvider, {
  StreamingTextToSpeechCapability? streamingTtsProvider,
  SpeechToTextCapability? sttProvider,
  RealtimeAudioCapability? realtimeProvider,
}) async {
  print('🔍 Available Capabilities:');
  print('   ✅ Text-to-Speech');
  print('   ${streamingTtsProvider == null ? "⏭️" : "✅"} Streaming TTS');
  print('   ${sttProvider == null ? "⏭️" : "✅"} Speech-to-Text');
  print('   ${realtimeProvider == null ? "⏭️" : "✅"} Realtime audio');

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
    List<VoiceInfo> voices = const [];
    final VoiceListingCapability? voiceListing =
        provider is VoiceListingCapability
            ? (provider as VoiceListingCapability)
            : null;
    if (voiceListing != null) {
      voices = await voiceListing.getVoices();
      print('   📢 Available voices: ${voices.length} voices');
      if (voices.isNotEmpty) {
        print(
            '   🎭 Sample voices: ${voices.take(3).map((v) => v.name).join(', ')}...');
      }
    }

    print('   🔄 Generating high-quality speech...');
    final highQualityTTS = await provider.textToSpeech(TTSRequest(
      text: 'Welcome to ElevenLabs, the most advanced text-to-speech platform.',
      voice: voices.isNotEmpty ? voices.first.id : 'JBFqnCBsd6RMkjVDRZzb',
      model: 'eleven_multilingual_v2',
      format: 'mp3_44100_128',
      includeTimestamps: true,
      timestampGranularity: TimestampGranularity.character,
      textNormalization: TextNormalization.auto,
      enableLogging: true,
    ));

    await File('elevenlabs_quality.mp3').writeAsBytes(highQualityTTS.audioData);
    print(
        '   ✅ High-quality TTS: ${highQualityTTS.audioData.length} bytes → elevenlabs_quality.mp3');

    if (highQualityTTS.alignment != null) {
      final alignment = highQualityTTS.alignment!;
      print(
          '   ⏱️  Character timing: ${alignment.characters.length} characters');
      print('   📊 Sample timing (first 5 chars):');
      for (int i = 0; i < 5 && i < alignment.characters.length; i++) {
        print(
            '      "${alignment.characters[i]}" at ${alignment.characterStartTimes[i]}s');
      }
    }
  } catch (e) {
    print('   ❌ TTS failed: $e');
  }

  print('');
}

Future<void> testStreamingTextToSpeech(
  StreamingTextToSpeechCapability provider,
) async {
  print('📡 Testing Streaming Text-to-Speech');

  try {
    final audioChunks = <int>[];
    var chunkCount = 0;

    await for (final event in provider.textToSpeechStream(const TTSRequest(
      text: 'This is a streaming test for ElevenLabs capabilities.',
      processingMode: AudioProcessingMode.streaming,
      optimizeStreamingLatency: 2,
    ))) {
      if (event is AudioDataEvent) {
        audioChunks.addAll(event.data);
        chunkCount++;
        print('   📦 Chunk $chunkCount: ${event.data.length} bytes');
        if (event.isFinal) {
          print('   ✅ Streaming complete');
          break;
        }
      } else if (event is AudioTimingEvent) {
        print('   ⏱️  Character "${event.character}" at ${event.startTime}s');
      }
    }

    await File('elevenlabs_streaming.mp3').writeAsBytes(audioChunks);
    print(
        '   ✅ Streaming TTS: $chunkCount chunks, ${audioChunks.length} total bytes → elevenlabs_streaming.mp3');
  } catch (e) {
    print('   ❌ Streaming TTS failed: $e');
  }

  print('');
}

Future<void> testSpeechToText(SpeechToTextCapability provider) async {
  print('🎤 Testing Speech-to-Text');

  try {
    final TranscriptionLanguageListingCapability? languageListing =
        provider is TranscriptionLanguageListingCapability
            ? (provider as TranscriptionLanguageListingCapability)
            : null;
    if (languageListing != null) {
      final languages = await languageListing.getSupportedLanguages();
      print('   🌍 Supported languages: ${languages.length} languages');
      if (languages.isNotEmpty) {
        print(
            '   🗣️  Sample languages: ${languages.take(5).map((l) => l.name).join(', ')}...');
      }
    }

    if (await File('elevenlabs_quality.mp3').exists()) {
      print('   🔄 Transcribing generated audio with advanced features...');

      final advancedSTT = await provider.speechToText(STTRequest.fromFile(
        'elevenlabs_quality.mp3',
        model: 'scribe_v1',
        diarize: true,
        numSpeakers: 1,
        timestampGranularity: TimestampGranularity.word,
        tagAudioEvents: true,
        enableLogging: true,
      ));

      print('   📝 Transcription: "${advancedSTT.text}"');
      print('   🌍 Language: ${advancedSTT.language ?? "unknown"}');
      print(
          '   📊 Confidence: ${advancedSTT.languageProbability ?? "unknown"}');

      final words = advancedSTT.words;
      if (words != null && words.isNotEmpty) {
        print('   ⏱️  Word timing (first 3 words):');
        for (final word in words.take(3)) {
          if (word is EnhancedWordTiming) {
            final speaker =
                word.speakerId != null ? ' [${word.speakerId}]' : '';
            print(
                '      "${word.word}"$speaker (${word.start}s - ${word.end}s)');
          } else {
            print('      "${word.word}" (${word.start}s - ${word.end}s)');
          }
        }
      }
    } else {
      print(
          '   ⚠️  No audio file found for transcription test (elevenlabs_quality.mp3)');
    }
  } catch (e) {
    print('   ❌ STT failed: $e');
  }

  print('');
}

Future<void> testRealtimeAudio(RealtimeAudioCapability provider) async {
  print('🎧 Testing Realtime Audio Session');

  try {
    final session = await provider.startRealtimeSession(
      const RealtimeAudioConfig(
        enableVAD: true,
        enableEchoCancellation: true,
        enableNoiseSuppression: true,
      ),
    );

    print('   ✅ Real-time session started: ${session.sessionId}');
    session.sendAudio([1, 2, 3, 4, 5]);

    try {
      await session.events.take(1).timeout(const Duration(seconds: 2)).toList();
    } catch (_) {
      // Timeout is expected for this demo.
    }

    await session.close();
    print('   ✅ Real-time session closed');
  } catch (e) {
    print('   ❌ Real-time audio failed: $e');
  }

  print('');
}
