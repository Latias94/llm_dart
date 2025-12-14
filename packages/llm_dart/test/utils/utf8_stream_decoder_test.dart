import 'dart:convert';
import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('Utf8StreamDecoder', () {
    late Utf8StreamDecoder decoder;

    setUp(() {
      decoder = Utf8StreamDecoder();
    });

    test('handles complete ASCII text', () {
      final input = utf8.encode('Hello World');
      final result = decoder.decode(input);
      expect(result, equals('Hello World'));
    });

    test('handles complete UTF-8 text', () {
      final input = utf8.encode('你好世界');
      final result = decoder.decode(input);
      expect(result, equals('你好世界'));
    });

    test('handles incomplete UTF-8 sequences', () {
      final text = '你好世界';
      final bytes = utf8.encode(text);

      // Split the bytes in the middle of a multi-byte character
      final part1 = bytes.sublist(0, 4); // Incomplete character
      final part2 = bytes.sublist(4); // Rest of the bytes

      // First part should return empty (incomplete sequence)
      final result1 = decoder.decode(part1);
      expect(result1, equals('你'));

      // Second part should complete the sequence
      final result2 = decoder.decode(part2);
      expect(result2, equals('好世界'));
    });

    test('handles mixed ASCII and UTF-8', () {
      final text = 'Hello 你好 World';
      final bytes = utf8.encode(text);

      // Split at various points
      final part1 = bytes.sublist(0, 8); // "Hello 你"
      final part2 = bytes.sublist(8); // "好 World"

      final result1 = decoder.decode(part1);
      final result2 = decoder.decode(part2);

      expect(result1 + result2, equals(text));
    });

    test('handles emoji characters', () {
      final text = '🌍🚀✨';
      final bytes = utf8.encode(text);

      // Split in the middle
      final part1 = bytes.sublist(0, 6); // First 1.5 emojis
      final part2 = bytes.sublist(6); // Rest

      final result1 = decoder.decode(part1);
      final result2 = decoder.decode(part2);

      expect(result1 + result2, equals(text));
    });

    test('flush returns remaining buffered content', () {
      final text = '你好';
      final bytes = utf8.encode(text);

      // Send incomplete sequence
      final incomplete = bytes.sublist(0, 2);
      final result1 = decoder.decode(incomplete);
      expect(result1, equals(''));

      // Flush should return the incomplete character if possible
      // or empty if truly incomplete
      final flushed = decoder.flush();
      expect(flushed, equals(''));
    });

    test('reset clears internal buffer', () {
      final bytes = utf8.encode('你好');
      final incomplete = bytes.sublist(0, 2);

      decoder.decode(incomplete);
      expect(decoder.hasBufferedBytes, isTrue);

      decoder.reset();
      expect(decoder.hasBufferedBytes, isFalse);
      expect(decoder.bufferedByteCount, equals(0));
    });

    test('handles empty input', () {
      final result = decoder.decode([]);
      expect(result, equals(''));
    });

    test('handles single byte characters', () {
      final result = decoder.decode([65, 66, 67]); // ABC
      expect(result, equals('ABC'));
    });
  });

  group('Utf8StreamDecoderExtension', () {
    test('transforms byte stream to string stream', () async {
      final text = 'Hello 你好 World 🌍';
      final bytes = utf8.encode(text);

      // Create a stream that splits bytes awkwardly
      Stream<List<int>> byteStream() async* {
        for (int i = 0; i < bytes.length; i += 3) {
          final end = (i + 3 < bytes.length) ? i + 3 : bytes.length;
          yield bytes.sublist(i, end);
        }
      }

      final stringStream = byteStream().decodeUtf8Stream();
      final result = await stringStream.join();

      expect(result, equals(text));
    });
  });
}
