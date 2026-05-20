import 'package:llm_dart_elevenlabs/src/elevenlabs_model_settings.dart';
import 'package:llm_dart_elevenlabs/src/elevenlabs_speech_model_request.dart';
import 'package:llm_dart_elevenlabs/src/elevenlabs_speech_options.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('ElevenLabs speech request projection', () {
    test('resolves voice and output format defaults', () {
      expect(
        resolveElevenLabsSpeechVoiceId(
          requestVoice: null,
          settings: const ElevenLabsSpeechModelSettings(
            defaultVoiceId: 'voice_default',
          ),
        ),
        'voice_default',
      );
      expect(
        resolveElevenLabsSpeechVoiceId(
          requestVoice: 'voice_call',
          settings: const ElevenLabsSpeechModelSettings(
            defaultVoiceId: 'voice_default',
          ),
        ),
        'voice_call',
      );
      expect(resolveElevenLabsSpeechOutputFormat(null), 'mp3_44100_128');
      expect(resolveElevenLabsSpeechOutputFormat('mp3_64'), 'mp3_44100_64');
      expect(resolveElevenLabsSpeechOutputFormat('pcm'), 'pcm_44100');
      expect(resolveElevenLabsSpeechOutputFormat('custom'), 'custom');
    });

    test('builds provider request body from shared and provider fields', () {
      final body = buildElevenLabsSpeechRequestBody(
        const SpeechGenerationRequest(
          text: 'Hello',
          language: 'en',
          speed: 1.1,
          callOptions: CallOptions(),
        ),
        modelId: 'eleven_multilingual_v2',
        settings: const ElevenLabsSpeechModelSettings(
          stability: 0.3,
          similarityBoost: 0.4,
          style: 0.5,
          useSpeakerBoost: true,
        ),
        options: const ElevenLabsSpeechOptions(
          seed: 7,
          previousText: 'Before',
          nextText: 'After',
          previousRequestIds: ['req_prev'],
          nextRequestIds: ['req_next'],
          pronunciationDictionaryLocators: [
            ElevenLabsPronunciationDictionaryLocator(
              pronunciationDictionaryId: 'dict_1',
              versionId: 'v1',
            ),
          ],
          textNormalization: ElevenLabsTextNormalization.auto,
          applyLanguageTextNormalization: true,
        ),
      );

      expect(body, {
        'text': 'Hello',
        'model_id': 'eleven_multilingual_v2',
        'voice_settings': {
          'stability': 0.3,
          'similarity_boost': 0.4,
          'style': 0.5,
          'speed': 1.1,
          'use_speaker_boost': true,
        },
        'language_code': 'en',
        'pronunciation_dictionary_locators': [
          {
            'pronunciation_dictionary_id': 'dict_1',
            'version_id': 'v1',
          },
        ],
        'seed': 7,
        'previous_text': 'Before',
        'next_text': 'After',
        'previous_request_ids': ['req_prev'],
        'next_request_ids': ['req_next'],
        'apply_text_normalization': 'auto',
        'apply_language_text_normalization': true,
      });
    });
  });
}
