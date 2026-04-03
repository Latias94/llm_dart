import 'dart:convert';
import 'dart:math';
import 'package:test/test.dart';
import 'package:llm_dart/legacy.dart';

/// Tests for thinking content extraction in streaming scenarios
///
/// This test suite simulates the real-world problem where thinking content
/// needs to be identified and extracted from streaming responses, even when
/// the \<think\>\</think\> tags are split across multiple chunks.
void main() {
  group('Thinking Content Extraction Tests', () {
    /// Helper function to extract thinking content from text
    String? extractThinkingContent(String text) {
      final thinkStart = text.indexOf('<think>');
      final thinkEnd = text.indexOf('</think>');

      if (thinkStart != -1 && thinkEnd != -1 && thinkEnd > thinkStart) {
        return text.substring(thinkStart + 7, thinkEnd);
      }
      return null;
    }

    /// Helper function to remove thinking content from text
    String removeThinkingContent(String text) {
      final regex = RegExp(r'<think>.*?</think>', dotAll: true);
      return text.replaceAll(regex, '').trim();
    }

    test('extracts thinking content correctly after streaming reconstruction',
        () {
      final decoder = Utf8StreamDecoder();

      // Simulate a response with thinking content
      final originalResponse = '''<think>
用户询问了一个关于编程的问题。
我需要：
1. 分析问题的核心
2. 提供清晰的解释
3. 给出实用的示例
</think>

根据您的问题，我来为您详细解释编程概念...''';

      final bytes = utf8.encode(originalResponse);

      // Simulate problematic chunking that splits the thinking tags
      final problematicChunks = [
        bytes.sublist(0, 2), // '<t'
        bytes.sublist(2, 5), // 'hin'
        bytes.sublist(5, 8), // 'k>\n'
        bytes.sublist(8, 20), // '用户询问了一个关于'
        bytes.sublist(20, 40), // '编程的问题。\n我需要：\n1.'
        bytes.sublist(40, 60), // ' 分析问题的核心\n2. 提供'
        bytes.sublist(60, 80), // '清晰的解释\n3. 给出实用'
        bytes.sublist(80, 90), // '的示例\n</th'
        bytes.sublist(90, 95), // 'ink>'
        bytes.sublist(95), // '\n\n根据您的问题...'
      ];

      // Reconstruct the response using UTF8 decoder
      final result = StringBuffer();
      for (final chunk in problematicChunks) {
        result.write(decoder.decode(chunk));
      }
      result.write(decoder.flush());

      final reconstructedResponse = result.toString();

      // Verify the response was reconstructed correctly
      expect(reconstructedResponse, equals(originalResponse));

      // Extract thinking content
      final thinkingContent = extractThinkingContent(reconstructedResponse);
      expect(thinkingContent, isNotNull);
      expect(thinkingContent, contains('用户询问了一个关于编程的问题'));
      expect(thinkingContent, contains('分析问题的核心'));

      // Extract visible content (without thinking)
      final visibleContent = removeThinkingContent(reconstructedResponse);
      expect(visibleContent, equals('根据您的问题，我来为您详细解释编程概念...'));
    });

    test('handles multiple thinking blocks in streaming', () {
      final decoder = Utf8StreamDecoder();

      final responseWithMultipleThinking = '''<think>
第一个思考：分析用户问题
</think>

这是第一部分回答。

<think>
第二个思考：考虑更深层的含义
需要提供更多细节
</think>

这是第二部分回答。

<think>
最终思考：总结要点
</think>

最终结论。''';

      final bytes = utf8.encode(responseWithMultipleThinking);

      // Create random chunks that might split thinking tags
      final chunks = <List<int>>[];
      final random = Random(789); // Fixed seed
      int i = 0;
      while (i < bytes.length) {
        final chunkSize = 3 + random.nextInt(10); // 3-12 bytes per chunk
        final end =
            (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        chunks.add(bytes.sublist(i, end));
        i = end;
      }

      // Reconstruct using decoder
      final result = StringBuffer();
      for (final chunk in chunks) {
        result.write(decoder.decode(chunk));
      }
      result.write(decoder.flush());

      final reconstructed = result.toString();
      expect(reconstructed, equals(responseWithMultipleThinking));

      // Verify we can extract all thinking blocks
      final allThinkingMatches = RegExp(r'<think>(.*?)</think>', dotAll: true)
          .allMatches(reconstructed);

      expect(allThinkingMatches.length, equals(3));

      final thinkingContents =
          allThinkingMatches.map((match) => match.group(1)?.trim()).toList();

      expect(thinkingContents[0], contains('第一个思考：分析用户问题'));
      expect(thinkingContents[1], contains('第二个思考：考虑更深层的含义'));
      expect(thinkingContents[2], contains('最终思考：总结要点'));
    });

    test('handles incomplete thinking tags gracefully', () {
      final decoder = Utf8StreamDecoder();

      // Simulate a case where the stream is cut off mid-thinking
      final incompleteResponse = '''<think>
这是一个未完成的思考过程
可能由于网络中断而被截断
没有结束标签''';

      final bytes = utf8.encode(incompleteResponse);

      // Process in small chunks
      final result = StringBuffer();
      for (int i = 0; i < bytes.length; i += 4) {
        final end = (i + 4 < bytes.length) ? i + 4 : bytes.length;
        final chunk = bytes.sublist(i, end);
        result.write(decoder.decode(chunk));
      }
      result.write(decoder.flush());

      final reconstructed = result.toString();
      expect(reconstructed, equals(incompleteResponse));

      // Should handle incomplete thinking tags gracefully
      final thinkingContent = extractThinkingContent(reconstructed);
      expect(thinkingContent, isNull); // No complete thinking block found
    });

    test('handles thinking tags with complex nested content', () {
      final decoder = Utf8StreamDecoder();

      final complexResponse = '''<think>
复杂的思考过程包含：
- 列表项目
- 代码片段：`function test() { return true; }`
- 数学公式：E = mc²
- 特殊字符：@#\$%^&*()
- 多语言：Hello, 你好, こんにちは, 🌍
- JSON数据：{"key": "value", "number": 123}
</think>

基于复杂的分析，我的回答是...''';

      final bytes = utf8.encode(complexResponse);

      // Use very small chunks to maximize the chance of splitting
      final result = StringBuffer();
      for (final byte in bytes) {
        result.write(decoder.decode([byte]));
      }
      result.write(decoder.flush());

      final reconstructed = result.toString();
      expect(reconstructed, equals(complexResponse));

      // Verify thinking content extraction
      final thinkingContent = extractThinkingContent(reconstructed);
      expect(thinkingContent, isNotNull);
      expect(thinkingContent, contains('复杂的思考过程包含'));
      expect(thinkingContent, contains('function test()'));
      expect(thinkingContent, contains('E = mc²'));
      expect(thinkingContent, contains('Hello, 你好, こんにちは'));
    });

    test('simulates real-world streaming scenario', () async {
      // Simulate a real streaming scenario where chunks arrive at different times
      final decoder = Utf8StreamDecoder();

      final realWorldResponse = '''<think>
用户问了一个关于AI的问题。我需要：
1. 理解问题的背景
2. 提供准确的信息
3. 确保回答有用且易懂
</think>

人工智能（AI）是一个广泛的领域，包含多个子领域...''';

      final bytes = utf8.encode(realWorldResponse);

      // Simulate realistic chunk sizes (like what you might get from an API)
      final realisticChunks = <List<int>>[];
      final chunkSizes = [1, 3, 2, 8, 5, 12, 7, 15, 4, 20, 10]; // Varying sizes

      int i = 0;
      for (final chunkSize in chunkSizes) {
        if (i >= bytes.length) break;
        final end =
            (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        realisticChunks.add(bytes.sublist(i, end));
        i = end;
      }

      // Add remaining bytes if any
      if (i < bytes.length) {
        realisticChunks.add(bytes.sublist(i));
      }

      // Process chunks as they would arrive in a real stream
      final result = StringBuffer();
      for (final chunk in realisticChunks) {
        final decoded = decoder.decode(chunk);
        result.write(decoded);

        // In a real application, you might try to extract thinking content
        // from partial results here, but it should handle incomplete tags gracefully
      }
      result.write(decoder.flush());

      final finalResult = result.toString();
      expect(finalResult, equals(realWorldResponse));

      // Final extraction should work correctly
      final thinkingContent = extractThinkingContent(finalResult);
      expect(thinkingContent, isNotNull);
      expect(thinkingContent, contains('用户问了一个关于AI的问题'));

      final visibleContent = removeThinkingContent(finalResult);
      expect(visibleContent, startsWith('人工智能（AI）是一个广泛的领域'));
    });

    test('performance with large thinking content and small chunks', () {
      final decoder = Utf8StreamDecoder();

      // Generate a large response with substantial thinking content
      final largeThinking = StringBuffer();
      largeThinking.write('<think>\n');
      for (int i = 0; i < 500; i++) {
        largeThinking.write('思考步骤 $i: 这是一个详细的分析过程，包含复杂的逻辑推理。\n');
      }
      largeThinking.write('</think>\n\n');
      largeThinking.write('基于以上详细分析，我的回答是：这是一个复杂问题的解决方案。');

      final largeResponse = largeThinking.toString();
      final bytes = utf8.encode(largeResponse);

      // Measure performance with very small chunks
      final stopwatch = Stopwatch()..start();

      final result = StringBuffer();
      // Use 2-byte chunks to maximize processing overhead
      for (int i = 0; i < bytes.length; i += 2) {
        final end = (i + 2 < bytes.length) ? i + 2 : bytes.length;
        final chunk = bytes.sublist(i, end);
        result.write(decoder.decode(chunk));
      }
      result.write(decoder.flush());

      stopwatch.stop();

      // Verify correctness
      expect(result.toString(), equals(largeResponse));

      // Verify performance (should be reasonable even with small chunks)
      expect(stopwatch.elapsedMilliseconds, lessThan(3000),
          reason:
              'Large content processing with small chunks should be efficient');

      // Verify thinking content extraction still works
      final thinkingContent = extractThinkingContent(result.toString());
      expect(thinkingContent, isNotNull);
      expect(thinkingContent, contains('思考步骤 0'));
      expect(thinkingContent, contains('思考步骤 499'));
    });
  });
}
