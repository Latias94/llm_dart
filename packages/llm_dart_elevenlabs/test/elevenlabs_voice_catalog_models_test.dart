import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart';
import 'package:llm_dart_elevenlabs/src/elevenlabs_voice_catalog_models.dart'
    show decodeElevenLabsVoiceList;
import 'package:test/test.dart';

void main() {
  group('ElevenLabs voice catalog models', () {
    test('round-trips typed voice descriptors', () {
      final voice = ElevenLabsVoice.fromJson({
        'voice_id': 'voice_123',
        'name': 'Rachel',
        'category': 'premade',
        'description': 'Warm narration voice.',
        'preview_url': 'https://example.com/rachel.mp3',
        'labels': {
          'gender': 'female',
          'accent': 'american',
        },
        'available_for_tiers': ['free', 'creator'],
      });

      expect(voice.id, 'voice_123');
      expect(voice.name, 'Rachel');
      expect(voice.gender, 'female');
      expect(voice.accent, 'american');
      expect(voice.toJson(), {
        'voice_id': 'voice_123',
        'name': 'Rachel',
        'category': 'premade',
        'description': 'Warm narration voice.',
        'preview_url': 'https://example.com/rachel.mp3',
        'labels': {
          'gender': 'female',
          'accent': 'american',
        },
        'available_for_tiers': ['free', 'creator'],
      });
    });

    test('decodes catalog lists with path-aware errors', () {
      expect(
        () => decodeElevenLabsVoiceList({
          'voices': [
            {'voice_id': '', 'name': 'Rachel'},
          ],
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('voice.voice_id'),
          ),
        ),
      );

      expect(
        () => decodeElevenLabsVoiceList({'voices': 'not-list'}),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('voices'),
          ),
        ),
      );
    });
  });
}
