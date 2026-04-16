// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/openai.dart' as openai;
import 'package:llm_dart_community/llm_dart_community.dart' as community;

/// Stable audio processing example built on shared speech/transcription helpers.
///
/// This example demonstrates:
/// - shared `generateSpeech(...)` across OpenAI and ElevenLabs
/// - shared `transcribe(...)` across OpenAI and ElevenLabs
/// - provider-native options passed through `CallOptions.providerOptions`
Future<void> main() async {
  print('Stable audio processing examples\n');

  final speechModels = _collectSpeechModels();
  final transcriptionModels = _collectTranscriptionModels();

  if (speechModels.isEmpty && transcriptionModels.isEmpty) {
    print('No audio models are configured.');
    print('Set OPENAI_API_KEY and/or ELEVENLABS_API_KEY.');
    return;
  }

  _GeneratedAudioSample? generatedSample;
  if (speechModels.isNotEmpty) {
    print('Speech generation:\n');
    for (final entry in speechModels) {
      final sample = await _demonstrateSpeechGeneration(entry);
      generatedSample ??= sample;
    }
  }

  final transcriptionSample =
      await _resolveTranscriptionSample(generatedSample: generatedSample);
  if (transcriptionSample == null) {
    print('No audio sample is available for transcription.');
    print(
      'Set AUDIO_SAMPLE_PATH or let one of the speech generation demos complete.',
    );
    return;
  }

  if (transcriptionModels.isNotEmpty) {
    print('Transcription:\n');
    for (final entry in transcriptionModels) {
      await _demonstrateTranscription(entry, transcriptionSample);
    }
  }

  print('Completed stable audio processing examples.');
}

List<_SpeechDemoEntry> _collectSpeechModels() {
  final entries = <_SpeechDemoEntry>[];

  final openAIKey = Platform.environment['OPENAI_API_KEY'];
  if (openAIKey != null && openAIKey.isNotEmpty) {
    entries.add(
      _SpeechDemoEntry(
        label: 'OpenAI gpt-4o-mini-tts',
        model: llm.AI
            .openai(
              apiKey: openAIKey,
            )
            .speechModel('gpt-4o-mini-tts'),
        voice: 'alloy',
        callOptions: const core.CallOptions(
          providerOptions: openai.OpenAISpeechOptions(
            outputFormat: 'mp3',
          ),
        ),
      ),
    );
  }

  final elevenLabsKey = Platform.environment['ELEVENLABS_API_KEY'];
  if (elevenLabsKey != null && elevenLabsKey.isNotEmpty) {
    entries.add(
      _SpeechDemoEntry(
        label: 'ElevenLabs eleven_multilingual_v2',
        model: community.ElevenLabs(
          apiKey: elevenLabsKey,
        ).speechModel('eleven_multilingual_v2'),
        callOptions: const core.CallOptions(
          providerOptions: community.ElevenLabsSpeechOptions(
            outputFormat: 'mp3',
          ),
        ),
      ),
    );
  }

  return entries;
}

List<_TranscriptionDemoEntry> _collectTranscriptionModels() {
  final entries = <_TranscriptionDemoEntry>[];

  final openAIKey = Platform.environment['OPENAI_API_KEY'];
  if (openAIKey != null && openAIKey.isNotEmpty) {
    entries.add(
      _TranscriptionDemoEntry(
        label: 'OpenAI whisper-1',
        model: llm.AI
            .openai(
              apiKey: openAIKey,
            )
            .transcriptionModel('whisper-1'),
        callOptions: const core.CallOptions(
          providerOptions: openai.OpenAITranscriptionOptions(
            responseFormat:
                openai.OpenAITranscriptionResponseFormat.verboseJson,
            timestampGranularities: [
              openai.OpenAITranscriptionTimestampGranularity.word,
            ],
          ),
        ),
      ),
    );
  }

  final elevenLabsKey = Platform.environment['ELEVENLABS_API_KEY'];
  if (elevenLabsKey != null && elevenLabsKey.isNotEmpty) {
    entries.add(
      _TranscriptionDemoEntry(
        label: 'ElevenLabs scribe_v1',
        model: community.ElevenLabs(
          apiKey: elevenLabsKey,
        ).transcriptionModel('scribe_v1'),
        callOptions: const core.CallOptions(
          providerOptions: community.ElevenLabsTranscriptionOptions(
            timestampGranularity:
                community.ElevenLabsTranscriptionTimestampGranularity.word,
          ),
        ),
      ),
    );
  }

  return entries;
}

Future<_GeneratedAudioSample?> _demonstrateSpeechGeneration(
  _SpeechDemoEntry entry,
) async {
  print('  ${entry.label}');
  print('  Model: ${entry.model.providerId}/${entry.model.modelId}');

  try {
    final result = await core.generateSpeech(
      model: entry.model,
      text:
          'Hello from the stable llm_dart speech generation example. This sample is used for both playback and transcription demos.',
      voice: entry.voice,
      callOptions: entry.callOptions,
    );

    final outputPath = _defaultAudioOutputPath(entry.model);
    await File(outputPath).writeAsBytes(result.audioBytes);

    print('    Saved: $outputPath');
    print('    Audio bytes: ${result.audioBytes.length}');
    print('    Media type: ${result.mediaType ?? 'unknown'}');

    return _GeneratedAudioSample(
      label: entry.label,
      outputPath: outputPath,
      audioBytes: result.audioBytes,
      mediaType: result.mediaType ?? _defaultMediaTypeForPath(outputPath),
    );
  } catch (error) {
    print('    Failed: $error');
    return null;
  } finally {
    print('');
  }
}

Future<_GeneratedAudioSample?> _resolveTranscriptionSample({
  required _GeneratedAudioSample? generatedSample,
}) async {
  final audioSamplePath = Platform.environment['AUDIO_SAMPLE_PATH'];
  if (audioSamplePath != null && audioSamplePath.isNotEmpty) {
    final file = File(audioSamplePath);
    if (!await file.exists()) {
      print('Configured AUDIO_SAMPLE_PATH was not found: $audioSamplePath');
      print('');
      return generatedSample;
    }

    return _GeneratedAudioSample(
      label: 'External sample',
      outputPath: audioSamplePath,
      audioBytes: await file.readAsBytes(),
      mediaType: _defaultMediaTypeForPath(audioSamplePath),
    );
  }

  return generatedSample;
}

Future<void> _demonstrateTranscription(
  _TranscriptionDemoEntry entry,
  _GeneratedAudioSample sample,
) async {
  print('  ${entry.label}');
  print('  Model: ${entry.model.providerId}/${entry.model.modelId}');
  print('  Input sample: ${sample.outputPath} (${sample.label})');

  try {
    final result = await core.transcribe(
      model: entry.model,
      audioBytes: sample.audioBytes,
      mediaType: sample.mediaType,
      callOptions: entry.callOptions,
    );

    print('    Text: ${result.text}');
    print('    Segments: ${result.segments.length}');
    print('    Language: ${result.language ?? 'unknown'}');
    print(
      '    Duration: ${result.durationSeconds?.toStringAsFixed(2) ?? 'unknown'}s',
    );

    if (result.segments.isNotEmpty) {
      for (final segment in result.segments.take(3)) {
        print(
          '      [${segment.startSeconds.toStringAsFixed(2)}-${segment.endSeconds.toStringAsFixed(2)}] ${segment.text}',
        );
      }
    }
  } catch (error) {
    print('    Failed: $error');
  } finally {
    print('');
  }
}

String _defaultAudioOutputPath(core.SpeechModel model) {
  return 'audio_sample_${model.providerId}_${model.modelId.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')}.mp3';
}

String? _defaultMediaTypeForPath(String path) {
  final lowerPath = path.toLowerCase();

  if (lowerPath.endsWith('.mp3')) {
    return 'audio/mpeg';
  }
  if (lowerPath.endsWith('.wav')) {
    return 'audio/wav';
  }
  if (lowerPath.endsWith('.m4a')) {
    return 'audio/mp4';
  }
  if (lowerPath.endsWith('.ogg')) {
    return 'audio/ogg';
  }
  if (lowerPath.endsWith('.webm')) {
    return 'audio/webm';
  }

  return null;
}

final class _SpeechDemoEntry {
  final String label;
  final core.SpeechModel model;
  final String? voice;
  final core.CallOptions callOptions;

  const _SpeechDemoEntry({
    required this.label,
    required this.model,
    this.voice,
    this.callOptions = const core.CallOptions(),
  });
}

final class _TranscriptionDemoEntry {
  final String label;
  final core.TranscriptionModel model;
  final core.CallOptions callOptions;

  const _TranscriptionDemoEntry({
    required this.label,
    required this.model,
    this.callOptions = const core.CallOptions(),
  });
}

final class _GeneratedAudioSample {
  final String label;
  final String outputPath;
  final List<int> audioBytes;
  final String? mediaType;

  const _GeneratedAudioSample({
    required this.label,
    required this.outputPath,
    required this.audioBytes,
    required this.mediaType,
  });
}
