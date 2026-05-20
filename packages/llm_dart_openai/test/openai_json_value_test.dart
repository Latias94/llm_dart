import 'dart:typed_data';

import 'package:llm_dart_openai/src/common/openai_json_value.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI JSON value helpers', () {
    test('coerces JSON containers and scalar values', () {
      final map = <String, Object?>{'id': 'file_123'};
      final list = <Object?>['file_123'];

      expect(identical(openAIRequiredMap(map, path: 'file'), map), isTrue);
      expect(identical(openAIRequiredList(list, path: 'files'), list), isTrue);
      expect(openAIRequiredNonEmptyString('gpt-4o', path: 'model'), 'gpt-4o');
      expect(openAIRequiredInt(3.9, path: 'usage.total_tokens'), 3);
      expect(openAIRequiredDouble(1, path: 'score'), 1.0);
      expect(openAIRequiredBool(false, path: 'deleted'), isFalse);
      expect(
        openAIRequiredEpochSecondsDateTime(1710003600, path: 'created_at'),
        DateTime.fromMillisecondsSinceEpoch(1710003600 * 1000, isUtc: true),
      );
    });

    test('returns null for optional values', () {
      expect(openAIOptionalMap(null, path: 'object'), isNull);
      expect(openAIOptionalList(null, path: 'items'), isNull);
      expect(openAIOptionalString(null, path: 'name'), isNull);
      expect(openAIOptionalInt(null, path: 'limit'), isNull);
      expect(openAIOptionalDouble(null, path: 'temperature'), isNull);
      expect(openAIOptionalBool(null, path: 'strict'), isNull);
      expect(openAIOptionalStringMap(null, path: 'metadata'), isNull);
      expect(openAIOptionalStringList(null, path: 'file_ids'), isNull);
      expect(
          openAIOptionalEpochSecondsDateTime(null, path: 'expires_at'), isNull);
    });

    test('validates typed string maps and lists', () {
      expect(
        openAIOptionalStringMap(
          {'imported_by': 'test'},
          path: 'metadata',
        ),
        {'imported_by': 'test'},
      );
      expect(
        openAIOptionalStringList(
          ['file_1', 'file_2'],
          path: 'file_ids',
        ),
        ['file_1', 'file_2'],
      );

      expect(
        () => openAIOptionalStringMap(
          {'count': 1},
          path: 'metadata',
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Expected a string value at metadata.count.',
          ),
        ),
      );
      expect(
        () => openAIOptionalStringList(
          ['file_1', 2],
          path: 'file_ids',
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Expected a string at file_ids[1].',
          ),
        ),
      );
    });

    test('reports path-aware shape errors', () {
      expect(
        () => openAIRequiredMap('bad', path: 'response'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Expected a JSON object at response.',
          ),
        ),
      );
      expect(
        () => openAIRequiredList('bad', path: 'response.data'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Expected a list at response.data.',
          ),
        ),
      );
      expect(
        () => openAIRequiredNonEmptyString('', path: 'response.id'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Expected a non-empty string at response.id.',
          ),
        ),
      );
    });

    test('normalizes byte responses and validates byte paths', () {
      final typedBytes = Uint8List.fromList([1, 2, 3]);

      expect(
        identical(
          openAIRequiredBytes(
            typedBytes,
            path: 'speech_response.body',
            sourceName: 'OpenAI speech response',
          ),
          typedBytes,
        ),
        isTrue,
      );
      expect(
        openAIRequiredBytes(
          [1, 2, 3],
          path: 'file_download.body',
          sourceName: 'OpenAI file download',
        ),
        [1, 2, 3],
      );
      expect(
        () => openAIRequiredBytes(
          ['bad'],
          path: 'file_download.body',
          sourceName: 'OpenAI file download',
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Expected an int at file_download.body[0].',
          ),
        ),
      );
      expect(
        () => openAIRequiredBytes(
          'bad',
          path: 'file_download.body',
          sourceName: 'OpenAI file download',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Expected OpenAI file download bytes at file_download.body '
                'but received String.',
          ),
        ),
      );
    });

    test('looks up headers case-insensitively', () {
      expect(
        openAILookupHeader({'Content-Type': 'audio/wav'}, 'content-type'),
        'audio/wav',
      );
      expect(
          openAILookupHeader({'x-request-id': 'req_123'}, 'missing'), isNull);
    });
  });
}
