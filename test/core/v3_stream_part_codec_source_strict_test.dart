import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('v3 stream part codec: source strictness', () {
    test('duplicate source id throws', () {
      expect(
        () => decodeV3StreamParts([
          {
            'type': 'source',
            'sourceType': 'url',
            'id': 'id-0',
            'url': 'https://example.com',
          },
          {
            'type': 'source',
            'sourceType': 'url',
            'id': 'id-0',
            'url': 'https://example.com',
          },
        ]),
        throwsA(isA<FormatException>()),
      );
    });

    test('url source missing url throws', () {
      expect(
        () => decodeV3StreamParts([
          {
            'type': 'source',
            'sourceType': 'url',
            'id': 'id-0',
          },
        ]),
        throwsA(isA<FormatException>()),
      );
    });

    test('document source missing mediaType throws', () {
      expect(
        () => decodeV3StreamParts([
          {
            'type': 'source',
            'sourceType': 'document',
            'id': 'id-0',
            'title': 'Doc',
          },
        ]),
        throwsA(isA<FormatException>()),
      );
    });

    test('document source missing title throws', () {
      expect(
        () => decodeV3StreamParts([
          {
            'type': 'source',
            'sourceType': 'document',
            'id': 'id-0',
            'mediaType': 'application/pdf',
          },
        ]),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
