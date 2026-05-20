import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_openai/src/chat_completions/openai_chat_completions_generate_result_codec.dart';
import 'package:llm_dart_openai/src/chat_completions/openai_chat_completions_support.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI Chat Completions generate result codec', () {
    const support = OpenAIChatCompletionsSupport(
      providerNamespace: 'deepseek',
    );

    test('decodes text, reasoning, usage, metadata, and warnings', () {
      const warning = ModelWarning(
        type: ModelWarningType.unsupported,
        message: 'ignored setting',
      );

      final result = decodeOpenAIChatCompletionsGenerateResponse(
        {
          'id': 'chatcmpl_1',
          'created': 1710000000,
          'model': 'deepseek-reasoner',
          'system_fingerprint': 'fp_1',
          'choices': [
            {
              'index': 0,
              'finish_reason': 'stop',
              'message': {
                'role': 'assistant',
                'reasoning_content': 'Plan',
                'content': 'Hello',
              },
            },
          ],
          'usage': {
            'prompt_tokens': 4,
            'completion_tokens': 6,
            'total_tokens': 10,
            'completion_tokens_details': {
              'reasoning_tokens': 2,
            },
          },
        },
        support: support,
        warnings: const [warning],
      );

      expect(
        result.content.whereType<ReasoningContentPart>().single.text,
        'Plan',
      );
      expect(result.content.whereType<TextContentPart>().single.text, 'Hello');
      expect(result.finishReason, FinishReason.stop);
      expect(result.rawFinishReason, 'stop');
      expect(result.responseMetadata?.id, 'chatcmpl_1');
      expect(result.responseMetadata?.modelId, 'deepseek-reasoner');
      expect(result.usage?.inputTokens, 4);
      expect(result.usage?.outputTokens, 6);
      expect(result.usage?.reasoningTokens, 2);
      expect(result.warnings, const [warning]);
      expect(
        result.providerMetadata?.namespace('deepseek'),
        allOf(
          containsPair('systemFingerprint', 'fp_1'),
          containsPair('finishReason', 'stop'),
        ),
      );
    });

    test('throws provider response errors with type and code context', () {
      expect(
        () => decodeOpenAIChatCompletionsGenerateResponse(
          {
            'error': {
              'message': 'upstream failed',
              'type': 'server_error',
              'code': 'bad_gateway',
            },
          },
          support: support,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('upstream failed'),
              contains('server_error'),
              contains('bad_gateway'),
            ),
          ),
        ),
      );
    });
  });
}
