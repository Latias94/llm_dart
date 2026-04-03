import 'dart:convert';
import 'dart:math';
import 'package:test/test.dart';
import 'package:llm_dart/legacy.dart';

/// Tests for thinking tags in streaming scenarios
///
/// This test suite specifically addresses the issue where \<think\>\</think\> tags
/// can be split across multiple chunks in streaming responses, making it
/// difficult to properly identify and extract thinking content.
void main() {
  group('Thinking Tags Streaming Tests', () {
    test('handles thinking tags split at tag boundaries', () {
      final decoder = Utf8StreamDecoder();

      // Test case that mimics the problem described in the issue
      final thinkingContent = '''<think>
这是一个复杂的思考过程
包含多行内容和中文字符
需要仔细分析用户的问题
</think>

这是正常的回答内容，用户可以看到的部分。''';

      final bytes = utf8.encode(thinkingContent);

      // Test splitting at various positions that would break tags
      final criticalPositions = [
        1, // Split after '<'
        6, // Split after '<think'
        7, // Split after '<think>'
        bytes.indexOf(utf8.encode('</think>')[0]), // Split at closing tag start
        bytes.indexOf(utf8.encode('</think>')[0]) +
            2, // Split in middle of closing tag
      ];

      for (final splitPos in criticalPositions) {
        if (splitPos >= bytes.length || splitPos <= 0) continue;

        decoder.reset();
        final result = StringBuffer();

        // Split into two parts at critical position
        final part1 = bytes.sublist(0, splitPos);
        final part2 = bytes.sublist(splitPos);

        result.write(decoder.decode(part1));
        result.write(decoder.decode(part2));
        result.write(decoder.flush());

        expect(result.toString(), equals(thinkingContent),
            reason: 'Failed when splitting at position: $splitPos');
      }
    });

    test('handles thinking tags with extreme fragmentation', () {
      final decoder = Utf8StreamDecoder();

      // Simulate the exact problem from the issue: tags split character by character
      final problematicContent = '''<think>
分析用户的问题：
1. 用户想要了解某个概念
2. 需要提供清晰的解释
3. 举例说明会更好
</think>

根据您的问题，我来为您详细解释...''';

      final bytes = utf8.encode(problematicContent);

      // Simulate very small chunks (1-3 bytes) that would split tags
      final result = StringBuffer();
      final random = Random(42); // Fixed seed for reproducible tests

      int i = 0;
      while (i < bytes.length) {
        final chunkSize = 1 + random.nextInt(3); // 1-3 bytes per chunk
        final end =
            (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        final chunk = bytes.sublist(i, end);

        result.write(decoder.decode(chunk));
        i = end;
      }
      result.write(decoder.flush());

      expect(result.toString(), equals(problematicContent));
    });

    test('handles multiple thinking blocks in one stream', () {
      final decoder = Utf8StreamDecoder();

      final multipleThinkingContent = '''<think>
第一个思考块：分析问题
</think>

这是第一部分回答。

<think>
第二个思考块：考虑解决方案
包含更多细节
</think>

这是第二部分回答。

<think>
第三个思考块：总结
</think>

最终的回答内容。''';

      final bytes = utf8.encode(multipleThinkingContent);

      // Split at random positions to simulate real streaming
      final chunks = <List<int>>[];
      final random = Random(123); // Fixed seed
      int i = 0;
      while (i < bytes.length) {
        final chunkSize = 2 + random.nextInt(8); // 2-9 bytes per chunk
        final end =
            (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        chunks.add(bytes.sublist(i, end));
        i = end;
      }

      // Decode chunks
      final result = StringBuffer();
      for (final chunk in chunks) {
        result.write(decoder.decode(chunk));
      }
      result.write(decoder.flush());

      expect(result.toString(), equals(multipleThinkingContent));
    });

    test('handles thinking tags with mixed content types', () {
      final decoder = Utf8StreamDecoder();

      final mixedContent = '''<think>
思考内容包含：
- 中文字符 🤔
- English text
- 数字 123
- 特殊符号 @#\$%
- 换行符和空格
</think>

回答：这是一个包含多种字符类型的测试。🌍✨''';

      final bytes = utf8.encode(mixedContent);

      // Test with single-byte chunks (worst case)
      final result = StringBuffer();
      for (final byte in bytes) {
        result.write(decoder.decode([byte]));
      }
      result.write(decoder.flush());

      expect(result.toString(), equals(mixedContent));
    });

    test('handles nested tags within thinking blocks', () {
      final decoder = Utf8StreamDecoder();

      final nestedContent = '''<think>
这里有嵌套的标签：
<analysis>
  <step1>分析问题</step1>
  <step2>制定方案</step2>
</analysis>
<conclusion>得出结论</conclusion>
</think>

基于以上分析，我的回答是...''';

      final bytes = utf8.encode(nestedContent);

      // Split at positions that might break nested tags
      final result = StringBuffer();
      for (int i = 0; i < bytes.length; i += 4) {
        final end = (i + 4 < bytes.length) ? i + 4 : bytes.length;
        final chunk = bytes.sublist(i, end);
        result.write(decoder.decode(chunk));
      }
      result.write(decoder.flush());

      expect(result.toString(), equals(nestedContent));
    });

    test('handles incomplete thinking tags at stream end', () {
      final decoder = Utf8StreamDecoder();

      // Test case where stream ends with incomplete thinking tag
      final incompleteContent = '''<think>
这是一个未完成的思考过程
可能由于网络问题或其他原因被截断''';

      final bytes = utf8.encode(incompleteContent);

      // Process all bytes except the last few
      final result = StringBuffer();
      for (int i = 0; i < bytes.length; i += 3) {
        final end = (i + 3 < bytes.length) ? i + 3 : bytes.length;
        final chunk = bytes.sublist(i, end);
        result.write(decoder.decode(chunk));
      }

      // Flush should handle incomplete content gracefully
      final flushed = decoder.flush();
      result.write(flushed);

      expect(result.toString(), equals(incompleteContent));
    });

    test('handles thinking tags with various line endings', () {
      final decoder = Utf8StreamDecoder();

      final lineEndingVariants = [
        '<think>\n思考内容\n</think>\n回答内容',
        '<think>\r\n思考内容\r\n</think>\r\n回答内容',
        '<think>\r思考内容\r</think>\r回答内容',
        '<think>思考内容</think>回答内容', // No line endings
      ];

      for (final content in lineEndingVariants) {
        decoder.reset();
        final bytes = utf8.encode(content);

        // Split at random positions
        final result = StringBuffer();
        final random = Random(456); // Fixed seed
        int i = 0;
        while (i < bytes.length) {
          final chunkSize = 1 + random.nextInt(5);
          final end =
              (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
          final chunk = bytes.sublist(i, end);
          result.write(decoder.decode(chunk));
          i = end;
        }
        result.write(decoder.flush());

        expect(result.toString(), equals(content),
            reason:
                'Failed for line ending variant: ${content.replaceAll('\n', '\\n').replaceAll('\r', '\\r')}');
      }
    });

    test('performance test with large thinking content', () {
      final decoder = Utf8StreamDecoder();

      // Generate large thinking content
      final largeThinking = StringBuffer();
      largeThinking.write('<think>\n');
      for (int i = 0; i < 1000; i++) {
        largeThinking.write('思考步骤 $i: 这是一个复杂的分析过程，包含中文和数字。\n');
      }
      largeThinking.write('</think>\n\n');
      largeThinking.write('基于以上详细分析，我的最终回答是...');

      final content = largeThinking.toString();
      final bytes = utf8.encode(content);

      // Measure performance with small chunks
      final stopwatch = Stopwatch()..start();

      final result = StringBuffer();
      for (int i = 0; i < bytes.length; i += 5) {
        final end = (i + 5 < bytes.length) ? i + 5 : bytes.length;
        final chunk = bytes.sublist(i, end);
        result.write(decoder.decode(chunk));
      }
      result.write(decoder.flush());

      stopwatch.stop();

      expect(result.toString(), equals(content));
      expect(stopwatch.elapsedMilliseconds, lessThan(2000),
          reason: 'Large thinking content processing should be fast');
    });
  });
}
