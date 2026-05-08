import 'dart:io';
import 'dart:typed_data';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/google.dart' as google;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/providers/google/google.dart' as google_compat;
import 'package:llm_dart/providers/google/tts.dart' as google_tts;

/// Stable-first Google speech example with a provider-owned streaming appendix.
///
/// This example keeps the boundary explicit:
/// - one-shot speech generation uses `AI.google(...).speechModel(...)`
/// - provider-specific one-shot knobs stay on `GoogleSpeechOptions`
/// - native streamed PCM output and voice discovery remain on the older
///   `GoogleTTSCapability` appendix

const _googleSpeechModelId = 'gemini-2.5-flash-preview-tts';

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

Future<void> main() async {
  final apiKey = Platform.environment['GOOGLE_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Please set GOOGLE_API_KEY environment variable');
    return;
  }

  print('🎤 Google Speech Example\n');

  final speechModel = llm.AI
      .google(
        apiKey: apiKey,
      )
      .speechModel(
        _googleSpeechModelId,
        settings: const google.GoogleSpeechModelSettings(defaultVoice: 'Kore'),
      );

  final compatibilityTts = google_compat.createGoogleProvider(
    apiKey: apiKey,
    model: _googleSpeechModelId,
  );

  describeBoundary(speechModel);
  await singleSpeakerExample(speechModel);
  await multiSpeakerExample(speechModel);
  await controllableSpeechExample(speechModel);
  await streamingExample(compatibilityTts);
  await voiceDiscoveryExample(compatibilityTts);
}

void describeBoundary(core.SpeechModel speechModel) {
  print('🧭 Boundary');
  print(
    '   ✅ Stable one-shot speech via ${speechModel.providerId}/${speechModel.modelId}',
  );
  print('   ✅ Multi-speaker one-shot generation stays available through');
  print('      Google-owned `GoogleSpeechOptions` on the stable model call');
  print('   ⚠️  Native streamed PCM output and voice discovery remain on the');
  print('      Google compatibility appendix for now');
  print('');
}

Future<void> singleSpeakerExample(core.SpeechModel speechModel) async {
  print('📢 Example 1: Stable Single-Speaker TTS');

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

  print('✅ Generated single-speaker audio: ${file.path}');
  print('   Voice: Kore (Firm)');
  print('   Media type: ${response.mediaType ?? 'unknown'}');
  print('   PCM data size: ${response.audioBytes.length} bytes');
  final metadata = response.providerMetadata?.namespace('google');
  if (metadata?['usage'] case final usage?) {
    print('   Usage: $usage');
  }
  print('');
}

Future<void> multiSpeakerExample(core.SpeechModel speechModel) async {
  print('🎭 Example 2: Stable Multi-Speaker TTS');

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

  print('✅ Generated multi-speaker audio: ${file.path}');
  print('   Speakers: Joe (Kore), Jane (Puck)');
  print('   PCM data size: ${response.audioBytes.length} bytes');
  print('');
}

Future<void> controllableSpeechExample(core.SpeechModel speechModel) async {
  print('🎨 Example 3: Stable Prompt-Driven Speech Style');

  final spookyResponse = await core.generateSpeech(
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

  final spookyFile = await _writeWavOutput(
    'output/spooky_whisper.wav',
    spookyResponse.audioBytes,
  );
  print('👻 Generated spooky whisper: ${spookyFile.path}');

  final emotionalResponse = await core.generateSpeech(
    model: speechModel,
    text:
        '''Make Speaker1 sound tired and bored, and Speaker2 sound excited and happy:

Speaker1: So... what's on the agenda today?
Speaker2: You're never going to guess! We just got approval for the new project!
Speaker1: Oh... that's... nice, I suppose.
Speaker2: Nice? It's amazing! This is going to change everything!''',
    callOptions: const core.CallOptions(
      providerOptions: google.GoogleSpeechOptions(
        speakers: [
          google.GoogleSpeechSpeakerVoice(
            speaker: 'Speaker1',
            voice: 'Enceladus',
          ),
          google.GoogleSpeechSpeakerVoice(
            speaker: 'Speaker2',
            voice: 'Puck',
          ),
        ],
        temperature: 0.6,
        maxOutputTokens: 512,
      ),
    ),
  );

  final emotionalFile = await _writeWavOutput(
    'output/emotional_dialogue.wav',
    emotionalResponse.audioBytes,
  );
  print('😴😄 Generated emotional dialogue: ${emotionalFile.path}');
  print('');
}

Future<void> streamingExample(
    google_tts.GoogleTTSCapability ttsProvider) async {
  print('🌊 Example 4: Compatibility Streaming Appendix');

  final request = google_tts.GoogleTTSRequest.singleSpeaker(
    text:
        'This is a streaming example. The audio will be generated in chunks as the text is processed.',
    voiceName: 'Zephyr',
  );

  final audioChunks = <int>[];

  await for (final event in ttsProvider.generateSpeechStream(request)) {
    switch (event) {
      case google_tts.GoogleTTSAudioDataEvent():
        audioChunks.addAll(event.data);
        print('📦 Received audio chunk: ${event.data.length} bytes');
      case google_tts.GoogleTTSMetadataEvent():
        print('📋 Metadata: ${event.contentType ?? 'unknown content type'}');
      case google_tts.GoogleTTSCompletionEvent():
        print('✅ Streaming completed');
      case google_tts.GoogleTTSErrorEvent():
        print('❌ Stream error: ${event.message}');
    }
  }

  if (audioChunks.isEmpty) {
    print('⚠️  No streamed audio chunks were returned');
    print('');
    return;
  }

  final file = await _writeWavOutput('output/streaming.wav', audioChunks);
  print('💾 Saved streaming audio: ${file.path}');
  print('   Total PCM data: ${audioChunks.length} bytes');
  print('');
}

Future<void> voiceDiscoveryExample(
  google_tts.GoogleTTSCapability ttsProvider,
) async {
  print('🔍 Example 5: Compatibility Voice Discovery');

  final voices = await ttsProvider.getAvailableVoices();
  print('📋 Available voices (${voices.length} total):');
  for (final voice in voices.take(10)) {
    print('   • ${voice.name}: ${voice.description}');
  }

  final languages = await ttsProvider.getSupportedLanguages();
  print('\n🌍 Supported languages (${languages.length} total):');
  print('   ${languages.take(10).join(', ')}...');
  print('');
}

Future<File> _writeWavOutput(String path, List<int> pcmData) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(createWavFile(pcmData));
  return file;
}
