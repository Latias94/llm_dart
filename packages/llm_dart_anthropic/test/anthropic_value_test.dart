import 'dart:typed_data';

import 'package:llm_dart_anthropic/src/anthropic_value.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic value helpers', () {
    test('coerces JSON containers and scalar values', () {
      final map = <String, Object?>{'id': 'file_123'};
      final list = <Object?>['file_123'];

      expect(identical(anthropicRequiredMap(map, path: 'file'), map), isTrue);
      expect(
          identical(anthropicRequiredList(list, path: 'files'), list), isTrue);
      expect(
        anthropicRequiredNonEmptyString('file_123', path: 'file.id'),
        'file_123',
      );
      expect(anthropicOptionalString(null, path: 'file.type'), isNull);
      expect(anthropicRequiredInt(3.9, path: 'file.size_bytes'), 3);
      expect(anthropicOptionalBool(null, path: 'file.downloadable'), isNull);
      expect(
        anthropicOptionalBool(false, path: 'file.downloadable'),
        isFalse,
      );
    });

    test('normalizes byte responses and header lookup', () {
      final bytes = Uint8List.fromList([1, 2, 3]);

      expect(
        identical(
          anthropicRequiredBytes(
            bytes,
            path: 'download.body',
            sourceName: 'Anthropic file download',
          ),
          bytes,
        ),
        isTrue,
      );
      expect(
        anthropicRequiredBytes(
          [1, 2, 3],
          path: 'download.body',
          sourceName: 'Anthropic file download',
        ),
        [1, 2, 3],
      );
      expect(
        anthropicLookupHeader(
          {'Content-Type': 'application/octet-stream'},
          'content-type',
        ),
        'application/octet-stream',
      );
    });

    test('reports path-aware shape errors', () {
      expect(
        () => anthropicRequiredMap('bad', path: 'file'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Expected a JSON object at file.',
          ),
        ),
      );
      expect(
        () => anthropicRequiredList('bad', path: 'file_list.data'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Expected a list at file_list.data.',
          ),
        ),
      );
      expect(
        () => anthropicRequiredNonEmptyString('', path: 'file.id'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Expected a non-empty string at file.id.',
          ),
        ),
      );
      expect(
        () => anthropicRequiredBytes(
          'bad',
          path: 'download.body',
          sourceName: 'Anthropic file download',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Expected Anthropic file download bytes at download.body '
                'but received String.',
          ),
        ),
      );
    });
  });
}
