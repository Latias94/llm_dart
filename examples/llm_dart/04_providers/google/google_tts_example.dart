import 'dart:io';
import 'dart:typed_data';
import 'package:llm_dart/llm_dart.dart';

/// Example demonstrating Google's native text-to-speech capabilities
///
/// This example shows how to use Google Gemini's TTS API for both
/// single-speaker and multi-speaker audio generation.
///
/// **Prerequisites:**
/// - Google AI API key
/// - TTS-compatible model (gemini-2.5-flash-preview-tts or gemini-2.5-pro-preview-tts)
///
/// **Features demonstrated:**
/// - Single-speaker TTS with voice selection
/// - Multi-speaker TTS with different voices
/// - Streaming TTS for real-time audio
/// - Voice and language discovery
/// - Controllable speech style through prompts
///
/// **Audio Format:**
/// Google TTS API returns PCM audio data with the following specifications:
/// - Sample rate: 24000 Hz
/// - Channels: 1 (mono)
/// - Bit depth: 16-bit signed little-endian
/// - Format: Raw PCM data (not WAV format)
///
/// **Important:** The API returns raw PCM data, not a complete WAV file.
/// To create playable audio files, you need to add a proper WAV header.
/// This example demonstrates how to convert PCM data to WAV format.

/// Creates a proper WAV file from PCM audio data
///
/// Google TTS API returns raw PCM data, not WAV format.
/// This function adds the necessary WAV header to make the audio playable.
///
/// Parameters:
/// - [pcmData]: Raw PCM audio data from Google TTS API
/// - [sampleRate]: Audio sample rate (default: 24000 Hz)
/// - [channels]: Number of audio channels (default: 1 for mono)
/// - [bitsPerSample]: Bits per sample (default: 16-bit)
Future<Uint8List> createWavFile(
  List<int> pcmData, {
  int sampleRate = 24000,
  int channels = 1,
  int bitsPerSample = 16,
}) async {
  final bytesPerSample = bitsPerSample ~/ 8;
  final byteRate = sampleRate * channels * bytesPerSample;
  final blockAlign = channels * bytesPerSample;
  final dataSize = pcmData.length;
  final fileSize = 36 + dataSize;

  final wavData = BytesBuilder();

  // WAV file header (44 bytes total)
  // RIFF chunk descriptor
  wavData.add('RIFF'.codeUnits); // ChunkID
  wavData.add(_int32ToBytes(fileSize)); // ChunkSize
  wavData.add('WAVE'.codeUnits); // Format

  // fmt sub-chunk
  wavData.add('fmt '.codeUnits); // Subchunk1ID
  wavData.add(_int32ToBytes(16)); // Subchunk1Size (16 for PCM)
  wavData.add(_int16ToBytes(1)); // AudioFormat (1 for PCM)
  wavData.add(_int16ToBytes(channels)); // NumChannels
  wavData.add(_int32ToBytes(sampleRate)); // SampleRate
  wavData.add(_int32ToBytes(byteRate)); // ByteRate
  wavData.add(_int16ToBytes(blockAlign)); // BlockAlign
  wavData.add(_int16ToBytes(bitsPerSample)); // BitsPerSample

  // data sub-chunk
  wavData.add('data'.codeUnits); // Subchunk2ID
  wavData.add(_int32ToBytes(dataSize)); // Subchunk2Size
  wavData.add(pcmData); // The actual audio data

  return wavData.toBytes();
}

/// Converts a 32-bit integer to little-endian bytes
List<int> _int32ToBytes(int value) {
  return [
    value & 0xFF,
    (value >> 8) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 24) & 0xFF,
  ];
}

/// Converts a 16-bit integer to little-endian bytes
List<int> _int16ToBytes(int value) {
  return [
    value & 0xFF,
    (value >> 8) & 0xFF,
  ];
}

void main() async {
  // Get API key from environment
  final apiKey = Platform.environment['GOOGLE_API_KEY'];
  if (apiKey == null) {
    print('Please set GOOGLE_API_KEY environment variable');
    return;
  }

  print('🎤 Google TTS Example\n');

  try {
    // Build Google TTS provider
    final ttsProvider = await ai()
        .google((google) =>
            google.ttsModel('gemini-2.5-flash-preview-tts').enableAudioOutput())
        .apiKey(apiKey)
        .buildGoogleTTS();

    // Example 1: Single-speaker TTS
    await singleSpeakerExample(ttsProvider);

    // Example 2: Multi-speaker TTS
    await multiSpeakerExample(ttsProvider);

    // Example 3: Streaming TTS
    await streamingExample(ttsProvider);

    // Example 4: Voice discovery
    await voiceDiscoveryExample(ttsProvider);

    // Example 5: Controllable speech style
    await controllableSpeechExample(ttsProvider);
  } catch (e) {
    print('❌ Error: $e');
  }
}

/// Example 1: Single-speaker text-to-speech
Future<void> singleSpeakerExample(GoogleTTSCapability ttsProvider) async {
  print('📢 Example 1: Single-speaker TTS');

  final request = GoogleTTSRequest.singleSpeaker(
    text: 'Say cheerfully: Have a wonderful day!',
    voiceName: 'Kore', // Firm voice
  );

  final response = await ttsProvider.generateSpeech(request);

  // Convert PCM data to WAV format
  final wavData = await createWavFile(response.audioData);

  // Save WAV file
  final file = File('output/single_speaker.wav');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(wavData);

  print('✅ Generated single-speaker audio: ${file.path}');
  print('   Voice: Kore (Firm)');
  print('   PCM data size: ${response.audioData.length} bytes');
  print('   WAV file size: ${wavData.length} bytes');
  if (response.usage != null) {
    print('   Usage: ${response.usage}');
  }
  print('');
}

/// Example 2: Multi-speaker text-to-speech
Future<void> multiSpeakerExample(GoogleTTSCapability ttsProvider) async {
  print('🎭 Example 2: Multi-speaker TTS');

  final request = GoogleTTSRequest.multiSpeaker(
    text: '''TTS the following conversation between Joe and Jane:
Joe: How's it going today Jane?
Jane: Not too bad, how about you?
Joe: Pretty good! I've been working on some exciting projects.
Jane: That sounds great! Tell me more about them.''',
    speakers: [
      GoogleSpeakerVoiceConfig(
        speaker: 'Joe',
        voiceConfig: GoogleVoiceConfig.prebuilt('Kore'), // Firm
      ),
      GoogleSpeakerVoiceConfig(
        speaker: 'Jane',
        voiceConfig: GoogleVoiceConfig.prebuilt('Puck'), // Upbeat
      ),
    ],
  );

  final response = await ttsProvider.generateSpeech(request);

  // Convert PCM data to WAV format
  final wavData = await createWavFile(response.audioData);

  // Save WAV file
  final file = File('output/multi_speaker.wav');
  await file.writeAsBytes(wavData);

  print('✅ Generated multi-speaker audio: ${file.path}');
  print('   Speakers: Joe (Kore), Jane (Puck)');
  print('   PCM data size: ${response.audioData.length} bytes');
  print('   WAV file size: ${wavData.length} bytes');
  print('');
}

/// Example 3: Streaming text-to-speech
Future<void> streamingExample(GoogleTTSCapability ttsProvider) async {
  print('🌊 Example 3: Streaming TTS');

  final request = GoogleTTSRequest.singleSpeaker(
    text:
        'This is a streaming example. The audio will be generated in chunks as the text is processed.',
    voiceName: 'Zephyr', // Bright voice
  );

  final audioChunks = <int>[];

  await for (final event in ttsProvider.generateSpeechStream(request)) {
    switch (event) {
      case GoogleTTSAudioDataEvent():
        audioChunks.addAll(event.data);
        print('📦 Received audio chunk: ${event.data.length} bytes');

      case GoogleTTSMetadataEvent():
        print('📋 Metadata: ${event.contentType}');

      case GoogleTTSCompletionEvent():
        print('✅ Streaming completed');

      case GoogleTTSErrorEvent():
        print('❌ Stream error: ${event.message}');
    }
  }

  // Convert accumulated PCM data to WAV format
  final wavData = await createWavFile(audioChunks);

  // Save WAV file
  final file = File('output/streaming.wav');
  await file.writeAsBytes(wavData);

  print('💾 Saved streaming audio: ${file.path}');
  print('   Total PCM data: ${audioChunks.length} bytes');
  print('   WAV file size: ${wavData.length} bytes');
  print('');
}

/// Example 4: Voice discovery
Future<void> voiceDiscoveryExample(GoogleTTSCapability ttsProvider) async {
  print('🔍 Example 4: Voice Discovery');

  // Get available voices
  final voices = await ttsProvider.getAvailableVoices();
  print('📋 Available voices (${voices.length} total):');

  for (final voice in voices.take(10)) {
    // Show first 10
    print('   • ${voice.name}: ${voice.description}');
  }

  // Get supported languages
  final languages = await ttsProvider.getSupportedLanguages();
  print('\n🌍 Supported languages (${languages.length} total):');
  print('   ${languages.take(10).join(', ')}...');
  print('');
}

/// Example 5: Controllable speech style
Future<void> controllableSpeechExample(GoogleTTSCapability ttsProvider) async {
  print('🎨 Example 5: Controllable Speech Style');

  // Example with style control
  final spookyRequest = GoogleTTSRequest.singleSpeaker(
    text: '''Say in a spooky whisper:
"By the pricking of my thumbs...
Something wicked this way comes"''',
    voiceName: 'Enceladus', // Breathy voice works well for whispers
  );

  final spookyResponse = await ttsProvider.generateSpeech(spookyRequest);

  // Convert PCM data to WAV format
  final spookyWavData = await createWavFile(spookyResponse.audioData);
  final spookyFile = File('output/spooky_whisper.wav');
  await spookyFile.writeAsBytes(spookyWavData);

  print('👻 Generated spooky whisper: ${spookyFile.path}');

  // Example with emotional control for multiple speakers
  final emotionalRequest = GoogleTTSRequest.multiSpeaker(
    text:
        '''Make Speaker1 sound tired and bored, and Speaker2 sound excited and happy:

Speaker1: So... what's on the agenda today?
Speaker2: You're never going to guess! We just got approval for the new project!
Speaker1: Oh... that's... nice, I suppose.
Speaker2: Nice? It's amazing! This is going to change everything!''',
    speakers: [
      GoogleSpeakerVoiceConfig(
        speaker: 'Speaker1',
        voiceConfig:
            GoogleVoiceConfig.prebuilt('Enceladus'), // Breathy for tired
      ),
      GoogleSpeakerVoiceConfig(
        speaker: 'Speaker2',
        voiceConfig: GoogleVoiceConfig.prebuilt('Puck'), // Upbeat for excited
      ),
    ],
  );

  final emotionalResponse = await ttsProvider.generateSpeech(emotionalRequest);

  // Convert PCM data to WAV format
  final emotionalWavData = await createWavFile(emotionalResponse.audioData);
  final emotionalFile = File('output/emotional_dialogue.wav');
  await emotionalFile.writeAsBytes(emotionalWavData);

  print('😴😄 Generated emotional dialogue: ${emotionalFile.path}');
  print('');
}
