import 'package:llm_dart/models/chat_models.dart';
import 'package:llm_dart/src/compatibility/providers/openai/openai_reasoning_request_support.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAICompatReasoningRequestSupport', () {
    group('isOpenAIReasoningModel', () {
      test('detects o-series models', () {
        expect(
          OpenAICompatReasoningRequestSupport.isOpenAIReasoningModel(
            'o1-preview',
          ),
          isTrue,
        );
        expect(
          OpenAICompatReasoningRequestSupport.isOpenAIReasoningModel('o3-mini'),
          isTrue,
        );
        expect(
          OpenAICompatReasoningRequestSupport.isOpenAIReasoningModel(
            'o4-preview',
          ),
          isTrue,
        );
      });

      test('rejects non-reasoning chat models', () {
        expect(
          OpenAICompatReasoningRequestSupport.isOpenAIReasoningModel('gpt-4'),
          isFalse,
        );
        expect(
          OpenAICompatReasoningRequestSupport.isOpenAIReasoningModel(
            'gpt-3.5-turbo',
          ),
          isFalse,
        );
      });
    });

    group('isKnownReasoningModel', () {
      test('includes OpenAI reasoning models', () {
        expect(
          OpenAICompatReasoningRequestSupport.isKnownReasoningModel(
            'o1-preview',
          ),
          isTrue,
        );
      });

      test('includes OpenAI-compatible reasoning models', () {
        expect(
          OpenAICompatReasoningRequestSupport.isKnownReasoningModel(
            'deepseek-reasoner',
          ),
          isTrue,
        );
        expect(
          OpenAICompatReasoningRequestSupport.isKnownReasoningModel(
            'claude-sonnet-4',
          ),
          isTrue,
        );
        expect(
          OpenAICompatReasoningRequestSupport.isKnownReasoningModel(
            'model-thinking-v1',
          ),
          isTrue,
        );
      });

      test('rejects non-reasoning models', () {
        expect(
          OpenAICompatReasoningRequestSupport.isKnownReasoningModel('gpt-4'),
          isFalse,
        );
        expect(
          OpenAICompatReasoningRequestSupport.isKnownReasoningModel(
            'claude-3-opus',
          ),
          isFalse,
        );
      });
    });

    test('maps OpenRouter reasoning effort to nested reasoning options', () {
      expect(
        OpenAICompatReasoningRequestSupport.getReasoningEffortParams(
          providerId: 'openrouter',
          model: 'deepseek/deepseek-r1',
          reasoningEffort: ReasoningEffort.high,
        ),
        equals({
          'reasoning': {
            'effort': 'high',
          },
        }),
      );
    });

    test('maps Claude reasoning effort to thinking budget', () {
      expect(
        OpenAICompatReasoningRequestSupport.getReasoningEffortParams(
          providerId: 'openrouter',
          model: 'anthropic/claude-sonnet-4',
          reasoningEffort: ReasoningEffort.medium,
          maxTokens: 8000,
        ),
        equals({
          'reasoning': {
            'effort': 'medium',
          },
        }),
      );

      expect(
        OpenAICompatReasoningRequestSupport.getReasoningEffortParams(
          providerId: 'openai-compatible',
          model: 'claude-sonnet-4',
          reasoningEffort: ReasoningEffort.medium,
          maxTokens: 8000,
        ),
        equals({
          'thinking': {
            'type': 'enabled',
            'budget_tokens': 4000,
          },
        }),
      );
    });

    test('maps max token parameter by reasoning model policy', () {
      expect(
        OpenAICompatReasoningRequestSupport.getMaxTokensParams(
          model: 'o3-mini',
          maxTokens: 32,
        ),
        equals({'max_completion_tokens': 32}),
      );
      expect(
        OpenAICompatReasoningRequestSupport.getMaxTokensParams(
          model: 'gpt-4',
          maxTokens: 32,
        ),
        equals({'max_tokens': 32}),
      );
    });
  });
}
