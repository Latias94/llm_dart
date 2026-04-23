import 'package:llm_dart_community/llm_dart_community.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('ElevenLabs model describers', () {
    test('describeElevenLabsSpeechModel exposes speech option surface', () {
      final profile = describeElevenLabsSpeechModel(
        'eleven_multilingual_v2',
        settings: const ElevenLabsSpeechModelSettings(
          defaultVoiceId: 'Rachel',
        ),
      );

      expect(profile.providerId, 'elevenlabs');
      expect(profile.kind, ModelCapabilityKind.speech);
      expect(
        profile.supports(ModelCapabilityFeatureIds.speechOutputFormat),
        isTrue,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.speechVoiceSelection),
        isTrue,
      );
      expect(
        profile.providerFeature('elevenlabs', 'api.route')?.detail,
        'text_to_speech',
      );
      expect(
        profile
            .providerFeature('elevenlabs', 'elevenlabs.speech.providerOptions')
            ?.detail,
        {
          'supportedOptions': [
            'outputFormat',
            'languageCode',
            'speed',
            'pronunciationDictionaryLocators',
            'seed',
            'previousText',
            'nextText',
            'previousRequestIds',
            'nextRequestIds',
            'textNormalization',
            'applyLanguageTextNormalization',
            'enableLogging',
            'optimizeStreamingLatency',
            'stability',
            'similarityBoost',
            'style',
            'useSpeakerBoost',
          ],
          'defaultVoiceId': 'Rachel',
        },
      );
    });

    test(
        'describeElevenLabsTranscriptionModel exposes timestamps and diarization',
        () {
      final profile =
          describeElevenLabsTranscriptionModel('scribe_v1_experimental');

      expect(profile.providerId, 'elevenlabs');
      expect(profile.kind, ModelCapabilityKind.transcription);
      expect(
        profile.supports(ModelCapabilityFeatureIds.transcriptionLanguageHints),
        isTrue,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.transcriptionTimestamps),
        isTrue,
      );
      expect(
        profile.providerFeature('elevenlabs', 'api.route')?.detail,
        'speech_to_text',
      );
      expect(
        profile
            .providerFeature(
              'elevenlabs',
              'elevenlabs.transcription.diarization',
            )
            ?.detail,
        {
          'supported': true,
          'speakerRange': [1, 32],
        },
      );
    });
  });
}
