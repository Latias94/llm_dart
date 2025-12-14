import 'dart:math';

import 'package:test/test.dart';
import 'package:llm_dart_openai/testing.dart' as openai;

/// Tests for streaming the complete "Memorial on Dispatching Troops" content
///
/// This test specifically validates that long Chinese classical text content
/// is properly handled in streaming scenarios without character loss.
void main() {
  group('Memorial on Dispatching Troops Streaming Tests', () {
    late openai.OpenAIClient client;

    setUp(() {
      final config = openai.OpenAIConfig(
        apiKey: 'test-key',
        model: 'gpt-4o',
      );
      client = openai.OpenAIClient(config);
    });

    test('handles complete 《出师表》 original text in streaming', () {
      // The complete original text of "Memorial on Dispatching Troops"
      const memorialText =
          '''　先帝创业未半而中道崩殂，今天下三分，益州疲弊，此诚危急存亡之秋也。然侍卫之臣不懈于内，忠志之士忘身于外者，盖追先帝之殊遇，欲报之于陛下也。诚宜开张圣听，以光先帝遗德，恢弘志士之气，不宜妄自菲薄，引喻失义，以塞忠谏之路也。

　　宫中府中，俱为一体；陟罚臧否，不宜异同。若有作奸犯科及为忠善者，宜付有司论其刑赏，以昭陛下平明之理，不宜偏私，使内外异法也。

　　侍中、侍郎郭攸之、费祎、董允等，此皆良实，志虑忠纯，是以先帝简拔以遗陛下。愚以为宫中之事，事无大小，悉以咨之，然后施行，必能裨补阙漏，有所广益。

　　将军向宠，性行淑均，晓畅军事，试用于昔日，先帝称之曰能，是以众议举宠为督。愚以为营中之事，悉以咨之，必能使行阵和睦，优劣得所。

　　亲贤臣，远小人，此先汉所以兴隆也；亲小人，远贤臣，此后汉所以倾颓也。先帝在时，每与臣论此事，未尝不叹息痛恨于桓、灵也。侍中、尚书、长史、参军，此悉贞良死节之臣，愿陛下亲之信之，则汉室之隆，可计日而待也。

　　臣本布衣，躬耕于南阳，苟全性命于乱世，不求闻达于诸侯。先帝不以臣卑鄙，猥自枉屈，三顾臣于草庐之中，咨臣以当世之事，由是感激，遂许先帝以驱驰。后值倾覆，受任于败军之际，奉命于危难之间，尔来二十有一年矣。

　　先帝知臣谨慎，故临崩寄臣以大事也。受命以来，夙夜忧叹，恐托付不效，以伤先帝之明；故五月渡泸，深入不毛。今南方已定，兵甲已足，当奖率三军，北定中原，庶竭驽钝，攘除奸凶，兴复汉室，还于旧都。此臣所以报先帝而忠陛下之职分也。至于斟酌损益，进尽忠言，则攸之、祎、允之任也。

　　愿陛下托臣以讨贼兴复之效，不效，则治臣之罪，以告先帝之灵。若无兴德之言，则责攸之、祎、允等之慢，以彰其咎；陛下亦宜自谋，以咨诹善道，察纳雅言，深追先帝遗诏。臣不胜受恩感激。今当远离，临表涕零，不知所言。''';

      // Split content into realistic streaming chunks (simulating OpenAI response)
      final chunks = _createRealisticSSEChunks(memorialText);

      // Test normal sequential processing
      client.resetSSEBuffer();
      final results = <String>[];

      for (final chunk in chunks) {
        final parsed = client.parseSSEChunk(chunk);
        for (final json in parsed) {
          final content = _extractContentFromJson(json);
          if (content != null) {
            results.add(content);
          }
        }
      }

      final reconstructedText = results.join();

      // Verify content integrity
      expect(reconstructedText, equals(memorialText));
      expect(reconstructedText, contains('先帝创业未半而中道崩殂'));
      expect(reconstructedText, contains('今天下三分，益州疲弊'));
      expect(reconstructedText, contains('三顾臣于草庐之中'));
      expect(reconstructedText, contains('北定中原'));
      expect(reconstructedText, contains('兴复汉室，还于旧都'));
      expect(reconstructedText, contains('临表涕零，不知所言'));
    });

    test('handles 《出师表》 with problematic chunk boundaries', () {
      const content =
          '''先帝创业未半而中道崩殂，今天下三分，益州疲弊，此诚危急存亡之秋也。然侍卫之臣不懈于内，忠志之士忘身于外者，盖追先帝之殊遇，欲报之于陛下也。''';

      // Create chunks that split at problematic positions
      final problematicChunks = [
        'data: {"choices":[{"delta":{"content":"先帝创业未半而中道崩殂，今天下三分，益州疲弊，此诚危急存亡之秋也。然侍卫之臣不懈于内，忠志之士忘身于外者，盖追先帝之殊"}}]}\n\n',
        'data: {"choices":[{"delta":{"content":"遇，欲报之于陛下也。"}}]}\n\n',
        'data: [DONE]\n\n'
      ];

      client.resetSSEBuffer();
      final results = <String>[];

      for (final chunk in problematicChunks) {
        final parsed = client.parseSSEChunk(chunk);
        for (final json in parsed) {
          final extractedContent = _extractContentFromJson(json);
          if (extractedContent != null) {
            results.add(extractedContent);
          }
        }
      }

      final reconstructedText = results.join();
      expect(reconstructedText, equals(content));

      // Verify specific problematic parts are intact
      expect(reconstructedText, contains('盖追先帝之殊遇'));
      expect(reconstructedText, contains('欲报之于陛下也'));
    });

    test('handles 《出师表》 with extreme fragmentation', () {
      const shortContent = '亲贤臣，远小人，此先汉所以兴隆也；亲小人，远贤臣，此后汉所以倾颓也。';

      // Create extremely fragmented chunks (split every few characters)
      final fragmentedChunks = <String>[];
      const chunkSize = 6; // Very small chunks

      for (int i = 0; i < shortContent.length; i += chunkSize) {
        final end = (i + chunkSize < shortContent.length)
            ? i + chunkSize
            : shortContent.length;
        final fragment = shortContent.substring(i, end);
        fragmentedChunks.add(
            'data: {"choices":[{"delta":{"content":"${_escapeJson(fragment)}"}}]}\n\n');
      }
      fragmentedChunks.add('data: [DONE]\n\n');

      client.resetSSEBuffer();
      final results = <String>[];

      for (final chunk in fragmentedChunks) {
        final parsed = client.parseSSEChunk(chunk);
        for (final json in parsed) {
          final extractedContent = _extractContentFromJson(json);
          if (extractedContent != null) {
            results.add(extractedContent);
          }
        }
      }

      final reconstructedText = results.join();
      expect(reconstructedText, equals(shortContent));
    });

    test('handles 《出师表》 with mixed chunk splitting', () {
      const content = '臣本布衣，躬耕于南阳，苟全性命于乱世，不求闻达于诸侯。先帝不以臣卑鄙，猥自枉屈，三顾臣于草庐之中。';

      // Simulate realistic but problematic network splitting
      final mixedChunks = [
        'data: {"choices":[{"delta":{"content":"臣本布衣，躬耕于南阳，苟全性命于乱世，不求闻达于诸侯。先帝不以臣卑鄙，猥自枉屈，三顾臣于草庐之"}}]', // No \n\n
        '}\n\ndata: {"choices":[{"delta":{"content":"中。"}}]}\n\n', // Completing previous + new complete chunk
      ];

      client.resetSSEBuffer();
      final results = <String>[];

      for (final chunk in mixedChunks) {
        final parsed = client.parseSSEChunk(chunk);
        for (final json in parsed) {
          final extractedContent = _extractContentFromJson(json);
          if (extractedContent != null) {
            results.add(extractedContent);
          }
        }
      }

      final reconstructedText = results.join();
      expect(reconstructedText, equals(content));
    });

    test('handles classical Chinese punctuation and formatting', () {
      const content =
          '　　宫中府中，俱为一体；陟罚臧否，不宜异同。若有作奸犯科及为忠善者，宜付有司论其刑赏，以昭陛下平明之理，不宜偏私，使内外异法也。';

      // Test with punctuation split across chunks
      final punctuationChunks = [
        'data: {"choices":[{"delta":{"content":"　　宫中府中，俱为一体"}}]}\n\n',
        'data: {"choices":[{"delta":{"content":"；陟罚臧否，不宜异同。若有作奸犯科及为忠善者，宜付有司论其刑赏，以昭陛下平明之理，不宜偏私，使内外异法也。"}}]}\n\n',
        'data: [DONE]\n\n'
      ];

      client.resetSSEBuffer();
      final results = <String>[];

      for (final chunk in punctuationChunks) {
        final parsed = client.parseSSEChunk(chunk);
        for (final json in parsed) {
          final extractedContent = _extractContentFromJson(json);
          if (extractedContent != null) {
            results.add(extractedContent);
          }
        }
      }

      final reconstructedText = results.join();
      expect(reconstructedText, equals(content));

      // Verify punctuation integrity
      expect(reconstructedText, contains('俱为一体；陟罚臧否'));
      expect(reconstructedText, contains('不宜异同。若有作奸犯科'));
    });
  });
}

/// Create realistic SSE chunks that simulate OpenAI streaming response
List<String> _createRealisticSSEChunks(String content) {
  final chunks = <String>[];
  final random = Random(42); // Fixed seed for reproducible tests

  int i = 0;
  while (i < content.length) {
    // Vary chunk sizes to simulate realistic streaming (8-40 characters)
    final chunkSize = 8 + random.nextInt(32);
    final end =
        (i + chunkSize < content.length) ? i + chunkSize : content.length;
    final fragment = content.substring(i, end);

    // Create proper SSE format
    final sseChunk =
        'data: {"choices":[{"delta":{"content":"${_escapeJson(fragment)}"}}]}\n\n';
    chunks.add(sseChunk);

    i = end;
  }

  // Add completion signal
  chunks.add('data: [DONE]\n\n');

  return chunks;
}

/// Extract content from parsed JSON
String? _extractContentFromJson(Map<String, dynamic> json) {
  final choices = json['choices'] as List?;
  if (choices == null || choices.isEmpty) return null;

  final choice = choices.first as Map<String, dynamic>;
  final delta = choice['delta'] as Map<String, dynamic>?;
  if (delta == null) return null;

  return delta['content'] as String?;
}

/// Escape JSON string content
String _escapeJson(String content) {
  return content
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r')
      .replaceAll('\t', '\\t');
}
