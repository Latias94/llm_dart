import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('UsageInfo.fromProviderUsage (AI SDK v3 mapping)', () {
    test('maps cached/miss tokens into cacheRead/noCache', () {
      final usage = UsageInfo.fromProviderUsage({
        'prompt_tokens': 10,
        'completion_tokens': 5,
        'total_tokens': 15,
        'prompt_cache_hit_tokens': 4,
        'prompt_cache_miss_tokens': 6,
      });

      expect(usage.promptTokens, 10);
      expect(usage.completionTokens, 5);
      expect(usage.totalTokens, 15);
      expect(usage.promptTokensCacheRead, 4);
      expect(usage.promptTokensNoCache, 6);
      expect(usage.raw, isNotNull);
    });

    test('derives noCache from total - cacheRead when missing', () {
      final usage = UsageInfo.fromProviderUsage({
        'prompt_tokens': 10,
        'completion_tokens': 1,
        'total_tokens': 11,
        'prompt_tokens_details': {'cached_tokens': 7},
      });

      expect(usage.promptTokensCacheRead, 7);
      expect(usage.promptTokensNoCache, 3);
    });

    test('maps reasoning tokens and derives text tokens', () {
      final usage = UsageInfo.fromProviderUsage({
        'prompt_tokens': 1,
        'completion_tokens': 9,
        'total_tokens': 10,
        'completion_tokens_details': {'reasoning_tokens': 4},
      });

      expect(usage.reasoningTokens, 4);
      expect(usage.completionTokensText, 5);
    });

    test('maps cache write tokens when provided', () {
      final usage = UsageInfo.fromProviderUsage({
        'input_tokens': 10,
        'output_tokens': 1,
        'cache_creation_input_tokens': 2,
      });

      expect(usage.promptTokens, 10);
      expect(usage.promptTokensCacheWrite, 2);
    });
  });
}
