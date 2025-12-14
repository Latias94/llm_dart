import 'dart:convert';
import 'dart:math';
import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

/// Integration tests for UTF-8 streaming functionality
///
/// These tests verify that the UTF-8 stream decoder correctly handles
/// multi-byte characters in streaming responses across different providers.
void main() {
  group('UTF-8 Streaming Integration Tests', () {
    test('UTF-8 stream decoder handles incomplete sequences', () {
      final decoder = Utf8StreamDecoder();

      // Test Japanese text that commonly causes issues
      final text = 'こんにちは世界！';
      final bytes = utf8.encode(text);

      // Simulate problematic chunk splitting
      final chunks = <List<int>>[];
      for (int i = 0; i < bytes.length; i += 2) {
        final end = (i + 2 < bytes.length) ? i + 2 : bytes.length;
        chunks.add(bytes.sublist(i, end));
      }

      // Decode chunks one by one
      final result = StringBuffer();
      for (final chunk in chunks) {
        final decoded = decoder.decode(chunk);
        result.write(decoded);
      }

      // Flush any remaining bytes
      final remaining = decoder.flush();
      result.write(remaining);

      expect(result.toString(), equals(text));
    });

    test('UTF-8 stream decoder handles various languages', () {
      final testCases = [
        'Hello World', // ASCII
        '你好世界', // Chinese
        'こんにちは', // Japanese
        '안녕하세요', // Korean
        'Здравствуй мир', // Russian
        'مرحبا بالعالم', // Arabic
        '🌍🚀✨🎌🌸', // Emojis
        'Mixed: Hello 你好 🌍 こんにちは', // Mixed content
      ];

      for (final testCase in testCases) {
        final decoder = Utf8StreamDecoder();
        final bytes = utf8.encode(testCase);

        // Split into random chunks
        final random = Random(42); // Fixed seed for reproducible tests
        final chunks = <List<int>>[];
        int i = 0;
        while (i < bytes.length) {
          final chunkSize = 1 + random.nextInt(5); // 1-5 bytes per chunk
          final end =
              (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
          chunks.add(bytes.sublist(i, end));
          i = end;
        }

        // Decode chunks
        final result = StringBuffer();
        for (final chunk in chunks) {
          final decoded = decoder.decode(chunk);
          result.write(decoded);
        }
        result.write(decoder.flush());

        expect(result.toString(), equals(testCase),
            reason: 'Failed for test case: $testCase');
      }
    });

    test('UTF-8 stream decoder extension works correctly', () async {
      final text = 'Hello 你好 World 🌍 こんにちは';
      final bytes = utf8.encode(text);

      // Create a stream that splits bytes awkwardly
      Stream<List<int>> byteStream() async* {
        final random = Random(123); // Fixed seed
        int i = 0;
        while (i < bytes.length) {
          final chunkSize = 1 + random.nextInt(4);
          final end =
              (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
          yield bytes.sublist(i, end);
          i = end;
        }
      }

      final stringStream = byteStream().decodeUtf8Stream();
      final result = await stringStream.join();

      expect(result, equals(text));
    });

    test('UTF-8 stream decoder handles edge cases', () {
      final decoder = Utf8StreamDecoder();

      // Test empty input
      expect(decoder.decode([]), equals(''));

      // Test single bytes
      expect(decoder.decode([65]), equals('A'));
      expect(decoder.decode([66, 67]), equals('BC'));

      // Test buffer state
      expect(decoder.hasBufferedBytes, isFalse);
      expect(decoder.bufferedByteCount, equals(0));

      // Add incomplete sequence
      final incomplete =
          utf8.encode('你').sublist(0, 2); // First 2 bytes of 3-byte char
      decoder.decode(incomplete);
      expect(decoder.hasBufferedBytes, isTrue);
      expect(decoder.bufferedByteCount, equals(2));

      // Reset should clear buffer
      decoder.reset();
      expect(decoder.hasBufferedBytes, isFalse);
      expect(decoder.bufferedByteCount, equals(0));
    });

    test('UTF-8 stream decoder handles malformed sequences gracefully', () {
      final decoder = Utf8StreamDecoder();

      // Test invalid UTF-8 sequences
      final invalidSequences = [
        [0xFF, 0xFE], // Invalid start bytes
        [0xC0, 0x80], // Overlong encoding
        [0xE0, 0x80], // Incomplete 3-byte sequence
      ];

      for (final sequence in invalidSequences) {
        // Should not throw, just return empty or handle gracefully
        expect(() => decoder.decode(sequence), returnsNormally);
        decoder.reset(); // Reset for next test
      }
    });

    test('UTF-8 stream decoder performance with large text', () {
      final decoder = Utf8StreamDecoder();

      // Create large text with mixed content
      final largeMixedText = List.generate(1000, (i) {
        switch (i % 4) {
          case 0:
            return 'Hello $i ';
          case 1:
            return '你好$i ';
          case 2:
            return 'こんにちは$i ';
          case 3:
            return '🌍$i ';
          default:
            return '';
        }
      }).join();

      final bytes = utf8.encode(largeMixedText);

      // Split into many small chunks
      final chunks = <List<int>>[];
      for (int i = 0; i < bytes.length; i += 3) {
        final end = (i + 3 < bytes.length) ? i + 3 : bytes.length;
        chunks.add(bytes.sublist(i, end));
      }

      // Measure performance
      final stopwatch = Stopwatch()..start();

      final result = StringBuffer();
      for (final chunk in chunks) {
        final decoded = decoder.decode(chunk);
        result.write(decoded);
      }
      result.write(decoder.flush());

      stopwatch.stop();

      expect(result.toString(), equals(largeMixedText));
      expect(stopwatch.elapsedMilliseconds, lessThan(1000),
          reason: 'UTF-8 decoding should be fast');
    });

    test('UTF-8 stream decoder handles emoji sequences correctly', () {
      final decoder = Utf8StreamDecoder();

      // Test various emoji types
      final emojiTests = [
        '🌍', // Single emoji
        '👨‍💻', // Compound emoji with ZWJ
        '🇺🇸', // Flag emoji
        '🌈🦄✨', // Multiple emojis
        '👨‍👩‍👧‍👦', // Family emoji (complex ZWJ sequence)
      ];

      for (final emojiText in emojiTests) {
        decoder.reset();
        final bytes = utf8.encode(emojiText);

        // Split bytes in problematic ways
        final result = StringBuffer();
        for (int i = 0; i < bytes.length; i += 2) {
          final end = (i + 2 < bytes.length) ? i + 2 : bytes.length;
          final chunk = bytes.sublist(i, end);
          result.write(decoder.decode(chunk));
        }
        result.write(decoder.flush());

        expect(result.toString(), equals(emojiText),
            reason: 'Failed for emoji: $emojiText');
      }
    });

    test('UTF-8 stream decoder handles thinking tags correctly', () {
      final decoder = Utf8StreamDecoder();

      // Test thinking content that might be split across chunks
      final thinkingTests = [
        '<think>这是思考内容</think>',
        '<think>Hello world thinking</think>',
        '<think>🤔 Complex thinking with emoji 💭</think>',
        '<think>\n多行思考内容\n包含换行符\n</think>',
        'Normal content <think>embedded thinking</think> more content',
        '<think>Nested <inner>tags</inner> in thinking</think>',
        '<think>Very long thinking content that spans multiple lines and contains various characters including 中文, emojis 🌍, and special symbols</think>',
      ];

      for (final testCase in thinkingTests) {
        decoder.reset();
        final bytes = utf8.encode(testCase);

        // Test various problematic split positions
        final splitPositions = [
          1, 2, 3, 5, 7, // Very small chunks
          bytes.length ~/ 4, // Quarter splits
          bytes.length ~/ 2, // Half splits
        ];

        for (final chunkSize in splitPositions) {
          if (chunkSize >= bytes.length) continue;

          decoder.reset();
          final result = StringBuffer();

          // Split into chunks of specified size
          for (int i = 0; i < bytes.length; i += chunkSize) {
            final end =
                (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
            final chunk = bytes.sublist(i, end);
            result.write(decoder.decode(chunk));
          }
          result.write(decoder.flush());

          expect(result.toString(), equals(testCase),
              reason:
                  'Failed for test case: "$testCase" with chunk size: $chunkSize');
        }
      }
    });

    test('UTF-8 stream decoder handles thinking tag boundaries', () {
      final decoder = Utf8StreamDecoder();

      // Test cases where tags are split at critical boundaries
      final testText = '<think>思考内容</think>正常内容';
      final bytes = utf8.encode(testText);

      // Find positions where tags might be split
      final tagPositions = <int>[];
      final textStr = testText;

      // Find all positions of '<', '>', and other critical characters
      for (int i = 0; i < textStr.length; i++) {
        if ('<>'.contains(textStr[i])) {
          // Convert string position to byte position
          final bytePos = utf8.encode(textStr.substring(0, i)).length;
          if (bytePos < bytes.length) {
            tagPositions.add(bytePos);
          }
        }
      }

      // Test splitting at each critical position
      for (final splitPos in tagPositions) {
        decoder.reset();
        final result = StringBuffer();

        // Split at the critical position
        final part1 = bytes.sublist(0, splitPos);
        final part2 = bytes.sublist(splitPos);

        result.write(decoder.decode(part1));
        result.write(decoder.decode(part2));
        result.write(decoder.flush());

        expect(result.toString(), equals(testText),
            reason: 'Failed when splitting at position: $splitPos');
      }
    });

    test('UTF-8 stream decoder handles extreme fragmentation', () {
      final decoder = Utf8StreamDecoder();

      // Test with extremely fragmented thinking content
      final testText = '<think>复杂的思考内容包含🤔emoji和\n换行符</think>然后是正常内容';
      final bytes = utf8.encode(testText);

      // Split into single bytes (worst case scenario)
      final result = StringBuffer();
      for (final byte in bytes) {
        result.write(decoder.decode([byte]));
      }
      result.write(decoder.flush());

      expect(result.toString(), equals(testText),
          reason: 'Failed with single-byte fragmentation');
    });
  });
}
