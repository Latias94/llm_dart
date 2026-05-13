// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/elevenlabs.dart' as elevenlabs;

const _voiceId = elevenlabs.elevenLabsDefaultVoiceId;
const _speechModelId = 'eleven_multilingual_v2';
const _transcriptionModelId = 'scribe_v1';

/// ElevenLabs stable speech/transcription models and voice catalog.
Future<void> main() async {
  final apiKey = Platform.environment['ELEVENLABS_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Please set ELEVENLABS_API_KEY environment variable');
    return;
  }

  print('ElevenLabs Audio Demo\n');

  final provider = elevenlabs.elevenLabs(apiKey: apiKey);
  final speechModel = provider.speechModel(
    _speechModelId,
    settings: const elevenlabs.ElevenLabsSpeechModelSettings(
      defaultVoiceId: _voiceId,
      stability: 0.5,
      similarityBoost: 0.75,
      style: 0.2,
    ),
  );
  final transcriptionModel = provider.transcriptionModel(_transcriptionModelId);

  displaySupportedProfiles(
    speechModel: speechModel,
    transcriptionModel: transcriptionModel,
  );

  final generatedAudio = await testTextToSpeech(speechModel);
  await testSpeechToText(
    transcriptionModel: transcriptionModel,
    audioFile: generatedAudio,
  );
  await testVoiceCatalog(provider.voices());

  print('ElevenLabs audio demo completed.');
}

void displaySupportedProfiles({
  required core.SpeechModel speechModel,
  required core.TranscriptionModel transcriptionModel,
}) {
  final speechProfile = switch (speechModel) {
    core.CapabilityDescribedModel(:final capabilityProfile) =>
      capabilityProfile,
    _ => null,
  };
  final transcriptionProfile = switch (transcriptionModel) {
    core.CapabilityDescribedModel(:final capabilityProfile) =>
      capabilityProfile,
    _ => null,
  };

  print('Audio boundary:');
  print('  Speech model: ${speechModel.providerId}/${speechModel.modelId}');
  print(
    '  Transcription model: '
    '${transcriptionModel.providerId}/${transcriptionModel.modelId}',
  );
  print(
    '  Speech output format option: '
    '${speechProfile?.supports(core.ModelCapabilityFeatureIds.speechOutputFormat) ?? false}',
  );
  print(
    '  Speech voice selection: '
    '${speechProfile?.supports(core.ModelCapabilityFeatureIds.speechVoiceSelection) ?? false}',
  );
  print(
    '  Transcription timestamps: '
    '${transcriptionProfile?.supports(core.ModelCapabilityFeatureIds.transcriptionTimestamps) ?? false}',
  );
  print('');
}

Future<File> testTextToSpeech(core.SpeechModel speechModel) async {
  print('Stable Text-to-Speech');

  final outputFile = File('elevenlabs_quality.mp3');

  try {
    final result = await core.generateSpeech(
      model: speechModel,
      text: 'Welcome to ElevenLabs speech generation through typed options.',
      callOptions: const core.CallOptions(
        providerOptions: elevenlabs.ElevenLabsSpeechOptions(
          outputFormat: 'mp3',
          textNormalization: elevenlabs.ElevenLabsTextNormalization.auto,
          enableLogging: true,
        ),
      ),
    );

    await outputFile.writeAsBytes(result.audioBytes);
    print(
        '  Generated ${result.audioBytes.length} bytes at ${outputFile.path}');

    final metadata = result.providerMetadata?.namespace('elevenlabs');
    if (metadata case final values?) {
      print('  Provider metadata: $values');
    }
  } catch (error) {
    print('  TTS failed: $error');
  }

  print('');
  return outputFile;
}

Future<void> testSpeechToText({
  required core.TranscriptionModel transcriptionModel,
  required File audioFile,
}) async {
  print('Stable Speech-to-Text');

  if (!await audioFile.exists()) {
    print('  No audio file found for transcription test.\n');
    return;
  }

  try {
    final result = await core.transcribe(
      model: transcriptionModel,
      audioBytes: await audioFile.readAsBytes(),
      mediaType: 'audio/mpeg',
      callOptions: const core.CallOptions(
        providerOptions: elevenlabs.ElevenLabsTranscriptionOptions(
          diarize: true,
          numSpeakers: 1,
          tagAudioEvents: true,
          timestampGranularity:
              elevenlabs.ElevenLabsTranscriptionTimestampGranularity.word,
          enableLogging: true,
        ),
      ),
    );

    print('  Transcription: "${result.text}"');
    print('  Language: ${result.language ?? "unknown"}');
    final metadata = result.providerMetadata?.namespace('elevenlabs');
    print(
      '  Language probability: ${metadata?['languageProbability'] ?? "unknown"}',
    );

    for (final segment in result.segments.take(3)) {
      print(
        '  Segment: "${segment.text}" '
        '(${segment.startSeconds}s - ${segment.endSeconds}s)',
      );
    }
  } catch (error) {
    print('  STT failed: $error');
  }

  print('');
}

Future<void> testVoiceCatalog(
  elevenlabs.ElevenLabsVoiceCatalogClient voices,
) async {
  print('Provider-Owned Voice Catalog');

  try {
    final catalog = await voices.listVoices();
    print('  Available voices: ${catalog.length}');
    for (final voice in catalog.take(5)) {
      print('  - ${voice.name} (${voice.id})');
    }
  } catch (error) {
    print('  Voice catalog lookup failed: $error');
  }

  print('');
}
