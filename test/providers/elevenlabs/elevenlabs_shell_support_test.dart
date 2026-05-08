import 'package:llm_dart_community/llm_dart_community.dart' as modern_community;
import 'package:llm_dart/models/audio_models.dart';
import 'package:llm_dart/providers/elevenlabs/config.dart';
import 'package:llm_dart/src/compatibility/providers/elevenlabs/shell_support.dart';
import 'package:test/test.dart';

void main() {
  group('ElevenLabsCompatShellSupport bridge gating', () {
    late ElevenLabsCompatShellSupport shell;

    setUp(() {
      shell = ElevenLabsCompatShellSupport(
        config: ElevenLabsConfig(apiKey: 'test-key'),
      );
    });

    test('speech bridge rejects out-of-range provider speech options', () {
      expect(
        shell.canUseSpeechBridge(
          const TTSRequest(
            text: 'hello',
            providerOptions: modern_community.ElevenLabsSpeechOptions(
              stability: 1.2,
            ),
          ),
        ),
        isFalse,
      );
      expect(
        shell.canUseSpeechBridge(
          const TTSRequest(
            text: 'hello',
            providerOptions: modern_community.ElevenLabsSpeechOptions(
              similarityBoost: -0.1,
            ),
          ),
        ),
        isFalse,
      );
      expect(
        shell.canUseSpeechBridge(
          const TTSRequest(
            text: 'hello',
            providerOptions: modern_community.ElevenLabsSpeechOptions(
              seed: -1,
            ),
          ),
        ),
        isFalse,
      );
    });

    test('transcription bridge keeps only supported byte-based requests', () {
      expect(
        shell.canUseTranscriptionBridge(
          STTRequest.fromFile('audio.wav'),
        ),
        isFalse,
      );
      expect(
        shell.canUseTranscriptionBridge(
          const STTRequest(
            audioData: [1, 2, 3],
            timestampGranularity: TimestampGranularity.segment,
          ),
        ),
        isFalse,
      );
      expect(
        shell.canUseTranscriptionBridge(
          const STTRequest(
            audioData: [1, 2, 3],
            providerOptions: modern_community.ElevenLabsTranscriptionOptions(
              numSpeakers: 33,
            ),
          ),
        ),
        isFalse,
      );
      expect(
        shell.canUseTranscriptionBridge(
          const STTRequest(
            audioData: [1, 2, 3],
            timestampGranularity: TimestampGranularity.word,
            providerOptions: modern_community.ElevenLabsTranscriptionOptions(
              numSpeakers: 2,
            ),
          ),
        ),
        isTrue,
      );
    });
  });
}
