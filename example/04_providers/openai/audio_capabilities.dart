import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/openai.dart' as openai;

/// OpenAI Audio Models Example
///
/// This example demonstrates the stable OpenAI speech and transcription model
/// surfaces. Audio translation remains compatibility oriented and is called out
/// explicitly as a boundary.
Future<void> main() async {
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null) {
    print('❌ Please set OPENAI_API_KEY environment variable');
    return;
  }

  print('🤖 OpenAI Audio Models Demo\n');

  final speechModel =
      llm.openai(apiKey: apiKey).speechModel('gpt-4o-mini-tts');
  final transcriptionModel = llm
      .openai(
        apiKey: apiKey,
      )
      .transcriptionModel('whisper-1');

  displaySupportedFeatures(speechModel, transcriptionModel);
  await testTextToSpeech(speechModel);
  await testSpeechToText(transcriptionModel);
  explainTranslationBoundary();

  print('✅ OpenAI audio models demo completed!');
}

void displaySupportedFeatures(
  core.SpeechModel speechModel,
  core.TranscriptionModel transcriptionModel,
) {
  print('🔍 Stable Audio Features:');
  print(
      '   ✅ Text-to-speech via ${speechModel.providerId}/${speechModel.modelId}');
  print(
    '   ✅ Speech-to-text via ${transcriptionModel.providerId}/${transcriptionModel.modelId}',
  );
  print(
      '   ⚠️  Audio translation is not yet frozen on the stable model surface');
  print('');
}

Future<void> testTextToSpeech(core.SpeechModel speechModel) async {
  print('🎵 Testing Text-to-Speech');

  try {
    print('   🔄 Generating basic speech...');
    final basicTTS = await core.generateSpeech(
      model: speechModel,
      text: 'Hello! This is OpenAI text-to-speech in action.',
      voice: 'alloy',
      callOptions: const core.CallOptions(
        providerOptions: openai.OpenAISpeechOptions(
          outputFormat: 'mp3',
          speed: 1.0,
        ),
      ),
    );

    await File('openai_basic.mp3').writeAsBytes(basicTTS.audioBytes);
    print(
      '   ✅ Basic TTS: ${basicTTS.audioBytes.length} bytes → openai_basic.mp3',
    );

    print('   🔄 Generating dramatic speech...');
    final dramaticTTS = await core.generateSpeech(
      model: speechModel,
      text: 'Welcome to the future of artificial intelligence!',
      voice: 'nova',
      callOptions: const core.CallOptions(
        providerOptions: openai.OpenAISpeechOptions(
          outputFormat: 'wav',
          instructions: 'Speak in an enthusiastic, dramatic voice',
          speed: 0.9,
        ),
      ),
    );

    await File('openai_dramatic.wav').writeAsBytes(dramaticTTS.audioBytes);
    print(
      '   ✅ Dramatic TTS: ${dramaticTTS.audioBytes.length} bytes → openai_dramatic.wav',
    );
  } catch (error) {
    print('   ❌ TTS failed: $error');
  }
  print('');
}

Future<void> testSpeechToText(
    core.TranscriptionModel transcriptionModel) async {
  print('🎤 Testing Speech-to-Text');

  try {
    final audioFile = File('openai_basic.mp3');
    if (!await audioFile.exists()) {
      print('   ⚠️  No audio file found for transcription test');
      print('');
      return;
    }

    print('   🔄 Transcribing generated audio...');
    final transcript = await core.transcribe(
      model: transcriptionModel,
      audioBytes: await audioFile.readAsBytes(),
      mediaType: 'audio/mpeg',
      callOptions: const core.CallOptions(
        providerOptions: openai.OpenAITranscriptionOptions(
          responseFormat: openai.OpenAITranscriptionResponseFormat.verboseJson,
          timestampGranularities: [
            openai.OpenAITranscriptionTimestampGranularity.word,
          ],
        ),
      ),
    );

    print('   📝 Transcription: "${transcript.text}"');
    final metadata = transcript.providerMetadata?.namespace('openai');
    print('   🌍 Detected language: ${metadata?['language'] ?? "unknown"}');
    print('   ⏱️  Duration: ${metadata?['durationSeconds'] ?? "unknown"}s');

    final words = metadata?['words'];
    if (words is List && words.isNotEmpty) {
      print('   📊 Word timing (first 3 words):');
      for (final entry in words.take(3)) {
        if (entry is Map) {
          print(
            '      "${entry['word']}" (${entry['start']}s - ${entry['end']}s)',
          );
        }
      }
    }
  } catch (error) {
    print('   ❌ STT failed: $error');
  }
  print('');
}

void explainTranslationBoundary() {
  print('🌐 Audio Translation Boundary');
  print(
      '   ℹ️  OpenAI audio translation is still exposed only through the older');
  print('      compatibility capability surface.');
  print('   ℹ️  The stable model API currently freezes speech generation and');
  print('      transcription, but not a separate translation model contract.');
  print('   ✅ Boundary documented\n');
}
