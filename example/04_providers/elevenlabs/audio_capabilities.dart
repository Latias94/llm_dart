import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/core/capability.dart' as compat_core;
import 'package:llm_dart/models/audio_models.dart';
import 'package:llm_dart/providers/elevenlabs/elevenlabs.dart'
    as elevenlabs_compat;
import 'package:llm_dart_community/llm_dart_community.dart' as community;

/// ElevenLabs shared speech/transcription models plus provider-owned appendix.
///
/// This example keeps the boundary explicit:
/// - stable app-facing TTS and STT use `llm_dart_community`
/// - provider-owned voice catalogs use a focused community helper
/// - streaming helpers and realtime flags stay on the compatibility provider surface

const _elevenLabsVoiceId = 'JBFqnCBsd6RMkjVDRZzb';
const _elevenLabsSpeechModelId = 'eleven_multilingual_v2';
const _elevenLabsTranscriptionModelId = 'scribe_v1';

Future<void> main() async {
  final apiKey = Platform.environment['ELEVENLABS_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set ELEVENLABS_API_KEY environment variable');
    return;
  }

  print('🎙️ ElevenLabs Audio Boundary Demo\n');

  final speechModel = community.ElevenLabs(
    apiKey: apiKey,
  ).speechModel(
    _elevenLabsSpeechModelId,
    settings: const community.ElevenLabsSpeechModelSettings(
      defaultVoiceId: _elevenLabsVoiceId,
      stability: 0.5,
      similarityBoost: 0.75,
      style: 0.2,
    ),
  );

  final transcriptionModel = community.ElevenLabs(
    apiKey: apiKey,
  ).transcriptionModel(_elevenLabsTranscriptionModelId);

  final voiceCatalog = community.ElevenLabs(
    apiKey: apiKey,
  ).voices();

  final audioProvider = elevenlabs_compat.createElevenLabsProvider(
    apiKey: apiKey,
    voiceId: _elevenLabsVoiceId,
    model: _elevenLabsSpeechModelId,
    stability: 0.5,
    similarityBoost: 0.75,
    style: 0.2,
  );

  displaySupportedFeatures(
    speechModel: speechModel,
    transcriptionModel: transcriptionModel,
    provider: audioProvider,
  );

  final generatedAudio = await testTextToSpeech(speechModel);
  await testSpeechToText(
    transcriptionModel: transcriptionModel,
    audioFile: generatedAudio,
  );
  await testVoiceCatalog(
    voices: voiceCatalog,
    provider: audioProvider,
  );
  await testCompatibilityStreaming(audioProvider);
  await testCompatibilityConvenienceTranscription(
    provider: audioProvider,
    audioFile: generatedAudio,
  );
  await inspectRealtimeBoundary(audioProvider);

  print('✅ ElevenLabs audio capabilities demo completed!');
}

void displaySupportedFeatures({
  required core.SpeechModel speechModel,
  required core.TranscriptionModel transcriptionModel,
  required compat_core.AudioCapability provider,
}) {
  print('🔍 Audio Boundary');
  print(
    '   ✅ Stable speech model: ${speechModel.providerId}/${speechModel.modelId}',
  );
  print(
    '   ✅ Stable transcription model: '
    '${transcriptionModel.providerId}/${transcriptionModel.modelId}',
  );
  print('   ✅ Provider-owned voice catalog: llm_dart_community');
  print('   ⚠️  Streamed TTS helpers and realtime flags remain');
  print('      provider owned on the compatibility surface');

  print('\n📋 Compatibility Feature Flags:');
  for (final feature in compat_core.AudioFeature.values) {
    final supported = provider.supportedFeatures.contains(feature);
    print('   ${supported ? '✅' : '❌'} ${feature.name}');
  }

  print('\n🎧 Compatibility Audio Formats:');
  for (final format in provider.getSupportedAudioFormats()) {
    print('   • $format');
  }
  print('');
}

Future<File> testTextToSpeech(core.SpeechModel speechModel) async {
  print('🎵 Stable Text-to-Speech');

  final outputFile = File('elevenlabs_quality.mp3');

  try {
    final result = await core.generateSpeech(
      model: speechModel,
      text: 'Welcome to ElevenLabs, the most advanced text-to-speech platform.',
      callOptions: const core.CallOptions(
        providerOptions: community.ElevenLabsSpeechOptions(
          outputFormat: 'mp3',
          textNormalization: community.ElevenLabsTextNormalization.auto,
          enableLogging: true,
        ),
      ),
    );

    await outputFile.writeAsBytes(result.audioBytes);
    print(
      '   ✅ Stable TTS: ${result.audioBytes.length} bytes → ${outputFile.path}',
    );

    final metadata = result.providerMetadata?.namespace('elevenlabs');
    if (metadata case final values?) {
      print('   📦 Provider metadata: $values');
    }
  } catch (error) {
    print('   ❌ Stable TTS failed: $error');
  }

  print('');
  return outputFile;
}

Future<void> testSpeechToText({
  required core.TranscriptionModel transcriptionModel,
  required File audioFile,
}) async {
  print('🎤 Stable Speech-to-Text');

  if (!await audioFile.exists()) {
    print('   ⚠️  No audio file found for transcription test');
    print('');
    return;
  }

  try {
    final result = await core.transcribe(
      model: transcriptionModel,
      audioBytes: await audioFile.readAsBytes(),
      mediaType: 'audio/mpeg',
      callOptions: const core.CallOptions(
        providerOptions: community.ElevenLabsTranscriptionOptions(
          diarize: true,
          numSpeakers: 1,
          tagAudioEvents: true,
          timestampGranularity:
              community.ElevenLabsTranscriptionTimestampGranularity.word,
          enableLogging: true,
        ),
      ),
    );

    print('   📝 Transcription: "${result.text}"');
    print('   🌍 Language: ${result.language ?? "unknown"}');
    final metadata = result.providerMetadata?.namespace('elevenlabs');
    print(
      '   📊 Language probability: ${metadata?['languageProbability'] ?? "unknown"}',
    );

    if (result.segments.isNotEmpty) {
      print('   ⏱️  Segment timing (first 3 segments):');
      for (final segment in result.segments.take(3)) {
        print(
          '      "${segment.text}" (${segment.startSeconds}s - ${segment.endSeconds}s)',
        );
      }
    }
  } catch (error) {
    print('   ❌ Stable STT failed: $error');
  }

  print('');
}

Future<void> testVoiceCatalog({
  required community.ElevenLabsVoiceCatalogClient voices,
  required compat_core.AudioCapability provider,
}) async {
  print('📚 Provider-Owned Voice Catalog');

  try {
    final catalog = await voices.listVoices();
    print('   📢 Available voices: ${catalog.length} voices');
    if (catalog.isNotEmpty) {
      print(
        '   🎭 Sample voices: ${catalog.take(3).map((voice) => voice.name).join(', ')}',
      );
    }

    final languages = await provider.getSupportedLanguages();
    print(
      '   🌍 Sample languages: ${languages.take(5).map((l) => l.name).join(', ')}',
    );
  } catch (error) {
    print('   ❌ Voice catalog lookup failed: $error');
  }

  print('');
}

Future<void> testCompatibilityStreaming(
  compat_core.AudioCapability provider,
) async {
  print('🌊 Provider-Owned Streaming Appendix');

  if (!provider.supportedFeatures
      .contains(compat_core.AudioFeature.streamingTTS)) {
    print('   ⏭️  Streaming TTS not advertised on this provider surface');
    print('');
    return;
  }

  try {
    final audioChunks = <int>[];
    var chunkCount = 0;

    await for (final event in provider.textToSpeechStream(
      const TTSRequest(
        text: 'This is a streaming test for ElevenLabs advanced capabilities.',
        voice: _elevenLabsVoiceId,
        model: _elevenLabsSpeechModelId,
        processingMode: AudioProcessingMode.streaming,
        optimizeStreamingLatency: 2,
      ),
    )) {
      if (event is AudioDataEvent) {
        audioChunks.addAll(event.data);
        chunkCount++;
        print('   📦 Chunk $chunkCount: ${event.data.length} bytes');
        if (event.isFinal) {
          print('   ✅ Streaming complete');
        }
      } else if (event is AudioTimingEvent) {
        print('   ⏱️  Character "${event.character}" at ${event.startTime}s');
      } else if (event is AudioErrorEvent) {
        print('   ❌ Streaming event error: ${event.message}');
      }
    }

    if (audioChunks.isNotEmpty) {
      await File('elevenlabs_streaming.mp3').writeAsBytes(audioChunks);
      print(
        '   ✅ Streaming TTS: $chunkCount chunks, ${audioChunks.length} total bytes',
      );
    }
  } on UnsupportedError catch (error) {
    print(
        '   ⚠️  Compatibility surface exists, but streaming is still pending:');
    print('      $error');
  } catch (error) {
    print('   ❌ Streaming TTS failed: $error');
  }

  print('');
}

Future<void> testCompatibilityConvenienceTranscription({
  required compat_core.AudioCapability provider,
  required File audioFile,
}) async {
  print('🧰 Provider Convenience Appendix');

  if (!await audioFile.exists()) {
    print('   ⏭️  Skipping file-path convenience transcription');
    print('');
    return;
  }

  try {
    final quickTranscription = await provider.transcribeFile(audioFile.path);
    print('   ✅ Quick transcription: "$quickTranscription"');
  } catch (error) {
    print('   ❌ Convenience transcription failed: $error');
  }

  print('');
}

Future<void> inspectRealtimeBoundary(
    compat_core.AudioCapability provider) async {
  print('📡 Realtime Boundary');

  if (!provider.supportedFeatures
      .contains(compat_core.AudioFeature.realtimeProcessing)) {
    print('   ⏭️  Realtime processing not advertised by this provider');
    print('');
    return;
  }

  try {
    final session = await provider.startRealtimeSession(
      const compat_core.RealtimeAudioConfig(
        inputFormat: 'pcm16',
        outputFormat: 'pcm16',
        sampleRate: 16000,
        timeoutSeconds: 5,
      ),
    );
    print('   ✅ Realtime session started: ${session.sessionId}');
    await session.close();
  } on UnsupportedError catch (error) {
    print('   ⚠️  Realtime remains provider owned and is still implementation');
    print('      boundary material on the compatibility shell: $error');
    print(
      '   ℹ️  See ../03_advanced_features/realtime_audio.dart for the app-owned orchestration pattern.',
    );
  } catch (error) {
    print('   ❌ Realtime startup failed: $error');
  }

  print('');
}
