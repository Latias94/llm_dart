import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_google/src/google_model_settings.dart';
import 'package:llm_dart_google/src/google_speech_model_body.dart';
import 'package:llm_dart_google/src/google_speech_options.dart';
import 'package:test/test.dart';

void main() {
  group('Google speech body projection', () {
    test('maps single-speaker request and generation options', () {
      final body = buildGoogleSpeechRequestBody(
        SpeechGenerationRequest(
          text: 'Hello world.',
          voice: 'Puck',
        ),
        settings: const GoogleSpeechModelSettings(defaultVoice: 'Kore'),
        options: const GoogleSpeechOptions(
          temperature: 0.4,
          topP: 0.9,
          topK: 32,
          maxOutputTokens: 256,
          stopSequences: ['END'],
        ),
      );

      expect(
        body,
        {
          'contents': [
            {
              'parts': [
                {
                  'text': 'Hello world.',
                },
              ],
            },
          ],
          'generationConfig': {
            'responseModalities': ['AUDIO'],
            'speechConfig': {
              'voiceConfig': {
                'prebuiltVoiceConfig': {
                  'voiceName': 'Puck',
                },
              },
            },
            'temperature': 0.4,
            'topP': 0.9,
            'topK': 32,
            'maxOutputTokens': 256,
            'stopSequences': ['END'],
          },
        },
      );
    });

    test('uses multi-speaker voice config when provider options request it',
        () {
      final body = buildGoogleSpeechRequestBody(
        SpeechGenerationRequest(text: 'Speaker1: Hi. Speaker2: Hello.'),
        settings: const GoogleSpeechModelSettings(defaultVoice: 'Kore'),
        options: const GoogleSpeechOptions(
          speakers: [
            GoogleSpeechSpeakerVoice(
              speaker: 'Speaker1',
              voice: 'Kore',
            ),
            GoogleSpeechSpeakerVoice(
              speaker: 'Speaker2',
              voice: 'Puck',
            ),
          ],
        ),
      );

      final generationConfig = body['generationConfig'] as Map<String, Object?>;
      expect(
        generationConfig['speechConfig'],
        {
          'multiSpeakerVoiceConfig': {
            'speakerVoiceConfigs': [
              {
                'speaker': 'Speaker1',
                'voiceConfig': {
                  'prebuiltVoiceConfig': {
                    'voiceName': 'Kore',
                  },
                },
              },
              {
                'speaker': 'Speaker2',
                'voiceConfig': {
                  'prebuiltVoiceConfig': {
                    'voiceName': 'Puck',
                  },
                },
              },
            ],
          },
        },
      );
    });
  });
}
