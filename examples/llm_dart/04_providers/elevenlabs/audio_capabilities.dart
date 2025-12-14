import 'dart:io';
import 'package:llm_dart/llm_dart.dart';

/// ElevenLabs Audio Capabilities Example
///
/// This example demonstrates the unified AudioCapability interface
/// with ElevenLabs' advanced text-to-speech and speech-to-text features.
///
/// **New Feature**: Uses the buildAudio() capability factory method for
/// type-safe provider building without runtime type casting.
Future<void> main() async {
  // Get API key from environment
  final apiKey = Platform.environment['ELEVENLABS_API_KEY'];
  if (apiKey == null) {
    print('❌ Please set ELEVENLABS_API_KEY environment variable');
    return;
  }

  print('🎙️ ElevenLabs Audio Capabilities Demo\n');

  // Create ElevenLabs provider with high-quality voice settings using buildAudio()
  // This provides compile-time type safety and eliminates runtime type casting
  final audioProvider = await ai()
      .elevenlabs((elevenlabs) => elevenlabs
          .voiceId('JBFqnCBsd6RMkjVDRZzb') // High-quality voice
          .stability(0.5)
          .similarityBoost(0.75)
          .style(0.2))
      .apiKey(apiKey)
      .buildAudio(); // Type-safe audio capability building

  // Display supported features
  await displaySupportedFeatures(audioProvider);

  // Test Text-to-Speech
  await testTextToSpeech(audioProvider);

  // Test Speech-to-Text
  await testSpeechToText(audioProvider);

  // Test Advanced Features
  await testAdvancedFeatures(audioProvider);

  print('✅ ElevenLabs audio capabilities demo completed!');
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
    print('   📢 Available voices: ${voices.length} voices');
    if (voices.isNotEmpty) {
      print(
          '   🎭 Sample voices: ${voices.take(3).map((v) => v.name).join(', ')}...');
    }

    // High-quality TTS
    print('   🔄 Generating high-quality speech...');
    final highQualityTTS = await provider.textToSpeech(TTSRequest(
      text: 'Welcome to ElevenLabs, the most advanced text-to-speech platform.',
      voice: 'JBFqnCBsd6RMkjVDRZzb',
      model: 'eleven_multilingual_v2',
      includeTimestamps: true,
      timestampGranularity: TimestampGranularity.character,
      textNormalization: TextNormalization.auto,
      enableLogging: true,
    ));

    await File('elevenlabs_quality.mp3').writeAsBytes(highQualityTTS.audioData);
    print(
        '   ✅ High-quality TTS: ${highQualityTTS.audioData.length} bytes → elevenlabs_quality.mp3');

    // Check for character timing
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

    // Test convenience method
    final quickSpeech = await provider.speech('Quick ElevenLabs test');
    await File('elevenlabs_quick.mp3').writeAsBytes(quickSpeech);
    print(
        '   ✅ Quick speech: ${quickSpeech.length} bytes → elevenlabs_quick.mp3');
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
    print(
        '   🗣️  Sample languages: ${languages.take(5).map((l) => l.name).join(', ')}...');

    // Test with generated audio file
    if (await File('elevenlabs_quality.mp3').exists()) {
      print('   🔄 Transcribing generated audio with advanced features...');

      // Advanced STT with speaker diarization
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

      if (advancedSTT.words != null && advancedSTT.words!.isNotEmpty) {
        print('   ⏱️  Word timing (first 3 words):');
        for (final word in advancedSTT.words!.take(3)) {
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

      // Test convenience method
      final quickTranscription =
          await provider.transcribeFile('elevenlabs_quality.mp3');
      print('   ✅ Quick transcription: "$quickTranscription"');
    } else {
      print('   ⚠️  No audio file found for transcription test');
    }
  } catch (e) {
    print('   ❌ STT failed: $e');
  }
  print('');
}

/// Test advanced ElevenLabs features
Future<void> testAdvancedFeatures(AudioCapability provider) async {
  print('🚀 Testing Advanced Features');

  // Test streaming TTS (if supported)
  if (provider.supportedFeatures.contains(AudioFeature.streamingTTS)) {
    print('   🔄 Testing streaming TTS...');
    try {
      final audioChunks = <int>[];
      var chunkCount = 0;

      await for (final event in provider.textToSpeechStream(TTSRequest(
        text: 'This is a streaming test for ElevenLabs advanced capabilities.',
        processingMode: AudioProcessingMode.streaming,
        optimizeStreamingLatency: 2,
      ))) {
        if (event is AudioDataEvent) {
          audioChunks.addAll(event.data);
          chunkCount++;
          print('     📦 Chunk $chunkCount: ${event.data.length} bytes');
          if (event.isFinal) {
            print('     ✅ Streaming complete');
            break;
          }
        } else if (event is AudioTimingEvent) {
          print(
              '     ⏱️  Character "${event.character}" at ${event.startTime}s');
        }
      }

      await File('elevenlabs_streaming.mp3').writeAsBytes(audioChunks);
      print(
          '   ✅ Streaming TTS: $chunkCount chunks, ${audioChunks.length} total bytes');
    } catch (e) {
      print('   ❌ Streaming TTS failed: $e');
    }
  } else {
    print('   ⏭️  Streaming TTS not supported');
  }

  // Test real-time audio (if supported)
  if (provider.supportedFeatures.contains(AudioFeature.realtimeProcessing)) {
    print('   🔄 Testing real-time audio session...');
    try {
      final session = await provider.startRealtimeSession(
        const RealtimeAudioConfig(
          enableVAD: true,
          enableEchoCancellation: true,
          enableNoiseSuppression: true,
        ),
      );

      print('     ✅ Real-time session started: ${session.sessionId}');

      // Send some test audio data
      session.sendAudio([1, 2, 3, 4, 5]); // Dummy data for demo

      // Listen for events briefly
      try {
        await session.events
            .take(1)
            .timeout(
              const Duration(seconds: 2),
            )
            .toList();
      } catch (e) {
        // Timeout is expected for demo
      }

      await session.close();
      print('     ✅ Real-time session closed');
    } catch (e) {
      print('   ❌ Real-time audio failed: $e');
    }
  } else {
    print('   ⏭️  Real-time audio not supported');
  }

  // Test audio translation (should fail for ElevenLabs)
  if (provider.supportedFeatures.contains(AudioFeature.audioTranslation)) {
    print('   🔄 Testing audio translation...');
    // This should not execute for ElevenLabs
  } else {
    print('   ⏭️  Audio translation not supported (expected for ElevenLabs)');
  }

  print('');
}
