import 'package:test/test.dart';
import 'package:llm_dart/src/compatibility/reasoning_utils.dart';

void main() {
  group('CompatReasoningUtils', () {
    group('checkReasoningStatus', () {
      test('returns false when delta is null', () {
        final result = CompatReasoningUtils.checkReasoningStatus(
          delta: null,
          hasReasoningContent: false,
          lastChunk: '',
        );

        expect(result.isReasoningJustDone, isFalse);
        expect(result.hasReasoningContent, isFalse);
        expect(result.updatedLastChunk, equals(''));
      });

      test('returns false when delta content is null', () {
        final result = CompatReasoningUtils.checkReasoningStatus(
          delta: {'other': 'value'},
          hasReasoningContent: false,
          lastChunk: '',
        );

        expect(result.isReasoningJustDone, isFalse);
        expect(result.hasReasoningContent, isFalse);
        expect(result.updatedLastChunk, equals(''));
      });

      test('detects reasoning end with ###Response marker', () {
        final result = CompatReasoningUtils.checkReasoningStatus(
          delta: {'content': 'Response'},
          hasReasoningContent: true,
          lastChunk: '###',
        );

        expect(result.isReasoningJustDone, isTrue);
        expect(result.hasReasoningContent, isTrue);
        expect(result.updatedLastChunk, equals('Response'));
      });

      test('detects reasoning end with </think> tag', () {
        final result = CompatReasoningUtils.checkReasoningStatus(
          delta: {'content': '</think>'},
          hasReasoningContent: true,
          lastChunk: '',
        );

        expect(result.isReasoningJustDone, isTrue);
        expect(result.hasReasoningContent, isTrue);
        expect(result.updatedLastChunk, equals('</think>'));
      });

      test('detects reasoning content from reasoning_content field', () {
        final result = CompatReasoningUtils.checkReasoningStatus(
          delta: {'reasoning_content': 'thinking...'},
          hasReasoningContent: false,
          lastChunk: '',
        );

        expect(result.isReasoningJustDone, isFalse);
        expect(result.hasReasoningContent, isTrue);
        expect(result.updatedLastChunk, equals(''));
      });

      test('detects reasoning content from reasoning field', () {
        final result = CompatReasoningUtils.checkReasoningStatus(
          delta: {'reasoning': 'thinking...'},
          hasReasoningContent: false,
          lastChunk: '',
        );

        expect(result.isReasoningJustDone, isFalse);
        expect(result.hasReasoningContent, isTrue);
        expect(result.updatedLastChunk, equals(''));
      });

      test('detects reasoning content from thinking field', () {
        final result = CompatReasoningUtils.checkReasoningStatus(
          delta: {'thinking': 'thinking...'},
          hasReasoningContent: false,
          lastChunk: '',
        );

        expect(result.isReasoningJustDone, isFalse);
        expect(result.hasReasoningContent, isTrue);
        expect(result.updatedLastChunk, equals(''));
      });

      test('detects reasoning end when switching from reasoning to content',
          () {
        final result = CompatReasoningUtils.checkReasoningStatus(
          delta: {'content': 'Hello'},
          hasReasoningContent: true,
          lastChunk: '',
        );

        expect(result.isReasoningJustDone, isTrue);
        expect(result.hasReasoningContent, isTrue);
        expect(result.updatedLastChunk, equals('Hello'));
      });

      test('does not detect reasoning end with empty content', () {
        final result = CompatReasoningUtils.checkReasoningStatus(
          delta: {'content': ''},
          hasReasoningContent: true,
          lastChunk: '',
        );

        expect(result.isReasoningJustDone, isFalse);
        expect(result.hasReasoningContent, isTrue);
        expect(result.updatedLastChunk, equals(''));
      });
    });

    group('extractReasoningContent', () {
      test('returns null for null delta', () {
        final result = CompatReasoningUtils.extractReasoningContent(null);
        expect(result, isNull);
      });

      test('extracts reasoning_content field', () {
        final result = CompatReasoningUtils.extractReasoningContent({
          'reasoning_content': 'thinking...',
          'other': 'value',
        });
        expect(result, equals('thinking...'));
      });

      test('extracts reasoning field when reasoning_content is null', () {
        final result = CompatReasoningUtils.extractReasoningContent({
          'reasoning': 'thinking...',
          'other': 'value',
        });
        expect(result, equals('thinking...'));
      });

      test('extracts thinking field when others are null', () {
        final result = CompatReasoningUtils.extractReasoningContent({
          'thinking': 'thinking...',
          'other': 'value',
        });
        expect(result, equals('thinking...'));
      });

      test('returns null when no reasoning fields present', () {
        final result = CompatReasoningUtils.extractReasoningContent({
          'content': 'regular content',
          'other': 'value',
        });
        expect(result, isNull);
      });

      test('prioritizes reasoning_content over others', () {
        final result = CompatReasoningUtils.extractReasoningContent({
          'reasoning_content': 'priority',
          'reasoning': 'secondary',
          'thinking': 'tertiary',
        });
        expect(result, equals('priority'));
      });
    });

    group('hasReasoningContent', () {
      test('returns false for null delta', () {
        final result = CompatReasoningUtils.hasReasoningContent(null);
        expect(result, isFalse);
      });

      test('returns true when reasoning_content is present', () {
        final result = CompatReasoningUtils.hasReasoningContent({
          'reasoning_content': 'thinking...',
        });
        expect(result, isTrue);
      });

      test('returns true when reasoning is present', () {
        final result = CompatReasoningUtils.hasReasoningContent({
          'reasoning': 'thinking...',
        });
        expect(result, isTrue);
      });

      test('returns true when thinking is present', () {
        final result = CompatReasoningUtils.hasReasoningContent({
          'thinking': 'thinking...',
        });
        expect(result, isTrue);
      });

      test('returns false when no reasoning fields present', () {
        final result = CompatReasoningUtils.hasReasoningContent({
          'content': 'regular content',
        });
        expect(result, isFalse);
      });
    });

    group('filterThinkingContent', () {
      test('removes simple thinking tags', () {
        final input = '<think>This is thinking</think>Hello world';
        final result = CompatReasoningUtils.filterThinkingContent(input);
        expect(result, equals('Hello world'));
      });

      test('removes multiple thinking tags', () {
        final input = '<think>First</think>Hello<think>Second</think>World';
        final result = CompatReasoningUtils.filterThinkingContent(input);
        expect(result, equals('HelloWorld'));
      });

      test('removes multiline thinking content', () {
        final input = '''<think>
This is
multiline thinking
</think>Hello world''';
        final result = CompatReasoningUtils.filterThinkingContent(input);
        expect(result, equals('Hello world'));
      });

      test('handles content without thinking tags', () {
        final input = 'Hello world';
        final result = CompatReasoningUtils.filterThinkingContent(input);
        expect(result, equals('Hello world'));
      });

      test('handles empty string', () {
        final input = '';
        final result = CompatReasoningUtils.filterThinkingContent(input);
        expect(result, equals(''));
      });

      test('handles only thinking tags', () {
        final input = '<think>Only thinking</think>';
        final result = CompatReasoningUtils.filterThinkingContent(input);
        expect(result, equals(''));
      });
    });

    group('containsThinkingTags', () {
      test('detects opening thinking tag', () {
        final result = CompatReasoningUtils.containsThinkingTags(
          'Hello <think>',
        );
        expect(result, isTrue);
      });

      test('detects closing thinking tag', () {
        final result = CompatReasoningUtils.containsThinkingTags(
          '</think> Hello',
        );
        expect(result, isTrue);
      });

      test('detects both tags', () {
        final result = CompatReasoningUtils.containsThinkingTags(
          '<think>thinking</think>',
        );
        expect(result, isTrue);
      });

      test('returns false for content without tags', () {
        final result = CompatReasoningUtils.containsThinkingTags('Hello world');
        expect(result, isFalse);
      });

      test('returns false for empty string', () {
        final result = CompatReasoningUtils.containsThinkingTags('');
        expect(result, isFalse);
      });
    });
  });
}
