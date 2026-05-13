// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/google.dart' as google;

const _googleSpeechModelId = 'gemini-2.5-flash-preview-tts';

Future<void> main() async {
  final apiKey = Platform.environment['GOOGLE_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Please set GOOGLE_API_KEY environment variable');
    return;
  }

  print('Google Speech Example\n');

  final speechModel = google.google(apiKey: apiKey).speechModel(
        _googleSpeechModelId,
        settings: const google.GoogleSpeechModelSettings(defaultVoice: 'Kore'),
      );

  describeBoundary(speechModel);
  await singleSpeakerExample(speechModel);
  await multiSpeakerExample(speechModel);
  await controllableSpeechExample(speechModel);
}

void describeBoundary(core.SpeechModel speechModel) {
  final profile = switch (speechModel) {
    core.CapabilityDescribedModel(:final capabilityProfile) =>
      capabilityProfile,
    _ => null,
  };

  print('Boundary:');
  print(
    '  Stable one-shot speech via ${speechModel.providerId}/${speechModel.modelId}',
  );
  print(
    '  Speech output format option: '
    '${profile?.supports(core.ModelCapabilityFeatureIds.speechOutputFormat) ?? false}',
  );
  print(
    '  Voice selection option: '
    '${profile?.supports(core.ModelCapabilityFeatureIds.speechVoiceSelection) ?? false}',
  );
  print(
    '  Google-specific multi-speaker and style controls live in GoogleSpeechOptions.',
  );
  print('');
}

Future<void> singleSpeakerExample(core.SpeechModel speechModel) async {
  print('Example 1: Stable Single-Speaker TTS');

  final response = await core.generateSpeech(
    model: speechModel,
    text: 'Say cheerfully: Have a wonderful day!',
    voice: 'Kore',
    callOptions: const core.CallOptions(
      providerOptions: google.GoogleSpeechOptions(
        temperature: 0.4,
        maxOutputTokens: 256,
      ),
    ),
  );

  final file = await _writeWavOutput(
    'output/single_speaker.wav',
    response.audioBytes,
  );

  print('Generated single-speaker audio: ${file.path}');
  print('Media type: ${response.mediaType ?? 'unknown'}');
  print('PCM data size: ${response.audioBytes.length} bytes');
  final metadata = response.providerMetadata?.namespace('google');
  if (metadata?['usage'] case final usage?) {
    print('Usage: $usage');
  }
  print('');
}

Future<void> multiSpeakerExample(core.SpeechModel speechModel) async {
  print('Example 2: Stable Multi-Speaker TTS');

  final response = await core.generateSpeech(
    model: speechModel,
    text: '''TTS the following conversation between Joe and Jane:
Joe: How's it going today Jane?
Jane: Not too bad, how about you?
Joe: Pretty good! I've been working on some exciting projects.
Jane: That sounds great! Tell me more about them.''',
    callOptions: const core.CallOptions(
      providerOptions: google.GoogleSpeechOptions(
        speakers: [
          google.GoogleSpeechSpeakerVoice(
            speaker: 'Joe',
            voice: 'Kore',
          ),
          google.GoogleSpeechSpeakerVoice(
            speaker: 'Jane',
            voice: 'Puck',
          ),
        ],
        temperature: 0.5,
        maxOutputTokens: 512,
      ),
    ),
  );

  final file = await _writeWavOutput(
    'output/multi_speaker.wav',
    response.audioBytes,
  );

  print('Generated multi-speaker audio: ${file.path}');
  print('Speakers: Joe (Kore), Jane (Puck)');
  print('PCM data size: ${response.audioBytes.length} bytes');
  print('');
}

Future<void> controllableSpeechExample(core.SpeechModel speechModel) async {
  print('Example 3: Prompt-Driven Speech Style');

  final response = await core.generateSpeech(
    model: speechModel,
    text: '''Say in a spooky whisper:
"By the pricking of my thumbs...
Something wicked this way comes"''',
    voice: 'Enceladus',
    callOptions: const core.CallOptions(
      providerOptions: google.GoogleSpeechOptions(
        temperature: 0.3,
        maxOutputTokens: 256,
      ),
    ),
  );

  final file = await _writeWavOutput(
    'output/spooky_whisper.wav',
    response.audioBytes,
  );
  print('Generated styled speech: ${file.path}');
  print('');
}

Future<File> _writeWavOutput(String path, List<int> pcmData) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(createWavFile(pcmData));
  return file;
}

Uint8List createWavFile(
  List<int> pcmData, {
  int sampleRate = 24000,
  int channels = 1,
  int bitsPerSample = 16,
}) {
  final bytesPerSample = bitsPerSample ~/ 8;
  final byteRate = sampleRate * channels * bytesPerSample;
  final blockAlign = channels * bytesPerSample;
  final dataSize = pcmData.length;
  final fileSize = 36 + dataSize;

  final wavData = BytesBuilder();
  wavData.add('RIFF'.codeUnits);
  wavData.add(_int32ToBytes(fileSize));
  wavData.add('WAVE'.codeUnits);
  wavData.add('fmt '.codeUnits);
  wavData.add(_int32ToBytes(16));
  wavData.add(_int16ToBytes(1));
  wavData.add(_int16ToBytes(channels));
  wavData.add(_int32ToBytes(sampleRate));
  wavData.add(_int32ToBytes(byteRate));
  wavData.add(_int16ToBytes(blockAlign));
  wavData.add(_int16ToBytes(bitsPerSample));
  wavData.add('data'.codeUnits);
  wavData.add(_int32ToBytes(dataSize));
  wavData.add(pcmData);

  return wavData.toBytes();
}

List<int> _int32ToBytes(int value) {
  return [
    value & 0xFF,
    (value >> 8) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 24) & 0xFF,
  ];
}

List<int> _int16ToBytes(int value) {
  return [
    value & 0xFF,
    (value >> 8) & 0xFF,
  ];
}
