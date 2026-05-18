import 'dart:typed_data';

import 'package:llm_dart_elevenlabs/src/elevenlabs_value.dart';
import 'package:test/test.dart';

void main() {
  group('ElevenLabs value helpers', () {
    test('coerces JSON containers and scalar values', () {
      final map = <String, Object?>{'voice_id': 'voice_123'};
      final list = <Object?>['voice_123'];

      expect(
        identical(elevenLabsRequiredMap(map, path: 'voice'), map),
        isTrue,
      );
      expect(
        identical(elevenLabsRequiredList(list, path: 'voices'), list),
        isTrue,
      );
      expect(
        elevenLabsRequiredNonEmptyString('Rachel', path: 'voice.name'),
        'Rachel',
      );
      expect(
        elevenLabsOptionalString(null, path: 'voice.category'),
        isNull,
      );
      expect(
        elevenLabsOptionalStringMap({'gender': 'female'}, path: 'voice.labels'),
        {'gender': 'female'},
      );
      expect(
        elevenLabsOptionalStringList(['free', 'creator'],
            path: 'voice.available_for_tiers'),
        ['free', 'creator'],
      );
    });

    test('normalizes byte responses and header lookup', () {
      final bytes = Uint8List.fromList([1, 2, 3]);

      expect(
        identical(
          elevenLabsRequiredBytes(
            bytes,
            path: 'speech_response.body',
            sourceName: 'ElevenLabs speech response',
          ),
          bytes,
        ),
        isTrue,
      );
      expect(
        elevenLabsRequiredBytes(
          [1, 2, 3],
          path: 'file_download.body',
          sourceName: 'ElevenLabs file download',
        ),
        [1, 2, 3],
      );
      expect(
        elevenLabsLookupHeader({'Content-Type': 'audio/mpeg'}, 'content-type'),
        'audio/mpeg',
      );
    });

    test('reports path-aware shape errors', () {
      expect(
        () => elevenLabsRequiredMap('bad', path: 'voice'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Expected a JSON object at voice.',
          ),
        ),
      );
      expect(
        () => elevenLabsRequiredList('bad', path: 'voices'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Expected a list at voices.',
          ),
        ),
      );
      expect(
        () => elevenLabsRequiredNonEmptyString('', path: 'voice.name'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Expected a non-empty string at voice.name.',
          ),
        ),
      );
      expect(
        () => elevenLabsRequiredBytes(
          'bad',
          path: 'speech_response.body',
          sourceName: 'ElevenLabs speech response',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Expected ElevenLabs speech response bytes at speech_response.body '
                'but received String.',
          ),
        ),
      );
    });
  });
}
