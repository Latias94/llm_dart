import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('UsageStats', () {
    test('preserves unknown counts when merging partial usage', () {
      const left = UsageStats(
        inputTokens: 10,
      );
      const right = UsageStats(
        outputTokens: 4,
        totalTokens: 14,
      );

      expect(
        left + right,
        const UsageStats(
          inputTokens: 10,
          outputTokens: 4,
          totalTokens: 14,
        ),
      );
    });

    test('adds counts only when both sides are known', () {
      const left = UsageStats(
        outputTokens: 3,
        reasoningTokens: 2,
      );
      const right = UsageStats(
        outputTokens: 4,
        reasoningTokens: 1,
      );

      expect(
        left + right,
        const UsageStats(
          outputTokens: 7,
          reasoningTokens: 3,
        ),
      );
    });

    test('keeps unknown counts unknown instead of inventing zeroes', () {
      final merged = const UsageStats() + const UsageStats();

      expect(merged, const UsageStats());
      expect(merged.inputTokens, isNull);
      expect(merged.totalTokens, isNull);
    });

    test('supports nullable merge helper', () {
      expect(UsageStats.mergeNullable(null, null), isNull);
      expect(
        UsageStats.mergeNullable(
          null,
          const UsageStats(outputTokens: 2),
        ),
        const UsageStats(outputTokens: 2),
      );
      expect(
        UsageStats.mergeNullable(
          const UsageStats(inputTokens: 3),
          const UsageStats(outputTokens: 2),
        ),
        const UsageStats(
          inputTokens: 3,
          outputTokens: 2,
        ),
      );
    });
  });
}
