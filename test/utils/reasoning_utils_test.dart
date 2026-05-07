import 'package:test/test.dart';
import 'package:llm_dart/utils/reasoning_utils.dart';

void main() {
  group('ReasoningUtils', () {
    group('checkReasoningStatus', () {
      test('returns false when delta is null', () {
        final result = ReasoningUtils.checkReasoningStatus(
          delta: null,
          hasReasoningContent: false,
          lastChunk: '',
        );

        expect(result.isReasoningJustDone, isFalse);
        expect(result.hasReasoningContent, isFalse);
        expect(result.updatedLastChunk, equals(''));
      });

      test('returns false when delta content is null', () {
        final result = ReasoningUtils.checkReasoningStatus(
          delta: {'other': 'value'},
          hasReasoningContent: false,
          lastChunk: '',
        );

        expect(result.isReasoningJustDone, isFalse);
        expect(result.hasReasoningContent, isFalse);
        expect(result.updatedLastChunk, equals(''));
      });

      test('detects reasoning end with ###Response marker', () {
        final result = ReasoningUtils.checkReasoningStatus(
          delta: {'content': 'Response'},
          hasReasoningContent: true,
          lastChunk: '###',
        );

        expect(result.isReasoningJustDone, isTrue);
        expect(result.hasReasoningContent, isTrue);
        expect(result.updatedLastChunk, equals('Response'));
      });

      test('detects reasoning end with </think> tag', () {
        final result = ReasoningUtils.checkReasoningStatus(
          delta: {'content': '</think>'},
          hasReasoningContent: true,
          lastChunk: '',
        );

        expect(result.isReasoningJustDone, isTrue);
        expect(result.hasReasoningContent, isTrue);
        expect(result.updatedLastChunk, equals('</think>'));
      });

      test('detects reasoning content from reasoning_content field', () {
        final result = ReasoningUtils.checkReasoningStatus(
          delta: {'reasoning_content': 'thinking...'},
          hasReasoningContent: false,
          lastChunk: '',
        );

        expect(result.isReasoningJustDone, isFalse);
        expect(result.hasReasoningContent, isTrue);
        expect(result.updatedLastChunk, equals(''));
      });

      test('detects reasoning content from reasoning field', () {
        final result = ReasoningUtils.checkReasoningStatus(
          delta: {'reasoning': 'thinking...'},
          hasReasoningContent: false,
          lastChunk: '',
        );

        expect(result.isReasoningJustDone, isFalse);
        expect(result.hasReasoningContent, isTrue);
        expect(result.updatedLastChunk, equals(''));
      });

      test('detects reasoning content from thinking field', () {
        final result = ReasoningUtils.checkReasoningStatus(
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
        final result = ReasoningUtils.checkReasoningStatus(
          delta: {'content': 'Hello'},
          hasReasoningContent: true,
          lastChunk: '',
        );

        expect(result.isReasoningJustDone, isTrue);
        expect(result.hasReasoningContent, isTrue);
        expect(result.updatedLastChunk, equals('Hello'));
      });

      test('does not detect reasoning end with empty content', () {
        final result = ReasoningUtils.checkReasoningStatus(
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
        final result = ReasoningUtils.extractReasoningContent(null);
        expect(result, isNull);
      });

      test('extracts reasoning_content field', () {
        final result = ReasoningUtils.extractReasoningContent({
          'reasoning_content': 'thinking...',
          'other': 'value',
        });
        expect(result, equals('thinking...'));
      });

      test('extracts reasoning field when reasoning_content is null', () {
        final result = ReasoningUtils.extractReasoningContent({
          'reasoning': 'thinking...',
          'other': 'value',
        });
        expect(result, equals('thinking...'));
      });

      test('extracts thinking field when others are null', () {
        final result = ReasoningUtils.extractReasoningContent({
          'thinking': 'thinking...',
          'other': 'value',
        });
        expect(result, equals('thinking...'));
      });

      test('returns null when no reasoning fields present', () {
        final result = ReasoningUtils.extractReasoningContent({
          'content': 'regular content',
          'other': 'value',
        });
        expect(result, isNull);
      });

      test('prioritizes reasoning_content over others', () {
        final result = ReasoningUtils.extractReasoningContent({
          'reasoning_content': 'priority',
          'reasoning': 'secondary',
          'thinking': 'tertiary',
        });
        expect(result, equals('priority'));
      });
    });

    group('hasReasoningContent', () {
      test('returns false for null delta', () {
        final result = ReasoningUtils.hasReasoningContent(null);
        expect(result, isFalse);
      });

      test('returns true when reasoning_content is present', () {
        final result = ReasoningUtils.hasReasoningContent({
          'reasoning_content': 'thinking...',
        });
        expect(result, isTrue);
      });

      test('returns true when reasoning is present', () {
        final result = ReasoningUtils.hasReasoningContent({
          'reasoning': 'thinking...',
        });
        expect(result, isTrue);
      });

      test('returns true when thinking is present', () {
        final result = ReasoningUtils.hasReasoningContent({
          'thinking': 'thinking...',
        });
        expect(result, isTrue);
      });

      test('returns false when no reasoning fields present', () {
        final result = ReasoningUtils.hasReasoningContent({
          'content': 'regular content',
        });
        expect(result, isFalse);
      });
    });

    group('filterThinkingContent', () {
      test('removes simple thinking tags', () {
        final input = '<think>This is thinking</think>Hello world';
        final result = ReasoningUtils.filterThinkingContent(input);
        expect(result, equals('Hello world'));
      });

      test('removes multiple thinking tags', () {
        final input = '<think>First</think>Hello<think>Second</think>World';
        final result = ReasoningUtils.filterThinkingContent(input);
        expect(result, equals('HelloWorld'));
      });

      test('removes multiline thinking content', () {
        final input = '''<think>
This is
multiline thinking
</think>Hello world''';
        final result = ReasoningUtils.filterThinkingContent(input);
        expect(result, equals('Hello world'));
      });

      test('handles content without thinking tags', () {
        final input = 'Hello world';
        final result = ReasoningUtils.filterThinkingContent(input);
        expect(result, equals('Hello world'));
      });

      test('handles empty string', () {
        final input = '';
        final result = ReasoningUtils.filterThinkingContent(input);
        expect(result, equals(''));
      });

      test('handles only thinking tags', () {
        final input = '<think>Only thinking</think>';
        final result = ReasoningUtils.filterThinkingContent(input);
        expect(result, equals(''));
      });
    });

    group('containsThinkingTags', () {
      test('detects opening thinking tag', () {
        final result = ReasoningUtils.containsThinkingTags('Hello <think>');
        expect(result, isTrue);
      });

      test('detects closing thinking tag', () {
        final result = ReasoningUtils.containsThinkingTags('</think> Hello');
        expect(result, isTrue);
      });

      test('detects both tags', () {
        final result =
            ReasoningUtils.containsThinkingTags('<think>thinking</think>');
        expect(result, isTrue);
      });

      test('returns false for content without tags', () {
        final result = ReasoningUtils.containsThinkingTags('Hello world');
        expect(result, isFalse);
      });

      test('returns false for empty string', () {
        final result = ReasoningUtils.containsThinkingTags('');
        expect(result, isFalse);
      });
    });

    group('extractContentWithoutThinking', () {
      test('filters content with thinking tags', () {
        final input = '<think>thinking</think>Hello world';
        final result = ReasoningUtils.extractContentWithoutThinking(input);
        expect(result, equals('Hello world'));
      });

      test('returns content unchanged when no thinking tags', () {
        final input = 'Hello world';
        final result = ReasoningUtils.extractContentWithoutThinking(input);
        expect(result, equals('Hello world'));
      });
    });
  });
}
