import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_openai/src/responses/openai_responses_finish_support.dart';
import 'package:llm_dart_openai/src/responses/openai_responses_usage_support.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI Responses finish support', () {
    test('maps failed status to error', () {
      expect(
        mapOpenAIResponsesFinishReason(
          rawReason: null,
          hasToolCalls: false,
          status: 'failed',
        ),
        FinishReason.error,
      );
    });

    test('maps missing raw reason based on tool call state', () {
      expect(
        mapOpenAIResponsesFinishReason(
          rawReason: null,
          hasToolCalls: false,
          status: 'completed',
        ),
        FinishReason.stop,
      );
      expect(
        mapOpenAIResponsesFinishReason(
          rawReason: null,
          hasToolCalls: true,
          status: 'completed',
        ),
        FinishReason.toolCalls,
      );
    });

    test('maps provider finish reasons', () {
      expect(
        mapOpenAIResponsesFinishReason(
          rawReason: 'max_output_tokens',
          hasToolCalls: false,
          status: 'incomplete',
        ),
        FinishReason.maxTokens,
      );
      expect(
        mapOpenAIResponsesFinishReason(
          rawReason: 'content_filter',
          hasToolCalls: false,
          status: 'incomplete',
        ),
        FinishReason.contentFilter,
      );
      expect(
        mapOpenAIResponsesFinishReason(
          rawReason: 'cancelled',
          hasToolCalls: false,
          status: 'cancelled',
        ),
        FinishReason.aborted,
      );
      expect(
        mapOpenAIResponsesFinishReason(
          rawReason: 'unknown_reason',
          hasToolCalls: false,
          status: 'completed',
        ),
        FinishReason.other,
      );
      expect(
        mapOpenAIResponsesFinishReason(
          rawReason: 'unknown_reason',
          hasToolCalls: true,
          status: 'completed',
        ),
        FinishReason.toolCalls,
      );
    });
  });

  group('OpenAI Responses usage support', () {
    test('returns null for missing usage', () {
      expect(decodeOpenAIResponsesUsage(null), isNull);
    });

    test('decodes usage and reasoning tokens', () {
      final usage = decodeOpenAIResponsesUsage({
        'input_tokens': 7,
        'output_tokens': 5,
        'total_tokens': 12,
        'output_tokens_details': {
          'reasoning_tokens': 3,
        },
      });

      expect(usage, isNotNull);
      expect(usage!.inputTokens, 7);
      expect(usage.outputTokens, 5);
      expect(usage.totalTokens, 12);
      expect(usage.reasoningTokens, 3);
    });

    test('derives total tokens when provider omits total', () {
      final usage = decodeOpenAIResponsesUsage({
        'input_tokens': 4,
        'output_tokens': 6,
      });

      expect(usage!.totalTokens, 10);
    });
  });
}
