import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_openai/src/responses/openai_responses_generate_result_codec.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI Responses generate result codec', () {
    test('decodes response metadata, usage, text, and warnings', () {
      const warning = ModelWarning(
        type: ModelWarningType.unsupported,
        message: 'ignored setting',
      );

      final result = decodeOpenAIResponsesGenerateResponse(
        {
          'id': 'resp_1',
          'model': 'gpt-5-mini',
          'created_at': 1710000000,
          'status': 'completed',
          'service_tier': 'default',
          'output': [
            {
              'id': 'msg_1',
              'type': 'message',
              'role': 'assistant',
              'content': [
                {
                  'type': 'output_text',
                  'text': 'Hello',
                  'annotations': [],
                },
              ],
            },
          ],
          'usage': {
            'input_tokens': 2,
            'output_tokens': 3,
            'total_tokens': 5,
            'output_tokens_details': {
              'reasoning_tokens': 1,
            },
          },
        },
        warnings: const [warning],
      );

      expect(result.content.whereType<TextContentPart>().single.text, 'Hello');
      expect(result.finishReason, FinishReason.stop);
      expect(result.responseMetadata?.id, 'resp_1');
      expect(result.responseMetadata?.modelId, 'gpt-5-mini');
      expect(
        result.responseMetadata?.timestamp,
        DateTime.utc(2024, 3, 9, 16),
      );
      expect(result.usage?.inputTokens, 2);
      expect(result.usage?.outputTokens, 3);
      expect(result.usage?.reasoningTokens, 1);
      expect(result.warnings, const [warning]);
      expect(
        result.providerMetadata?.namespace('openai'),
        containsPair('serviceTier', 'default'),
      );
    });

    test('throws provider response errors with type and code context', () {
      expect(
        () => decodeOpenAIResponsesGenerateResponse({
          'error': {
            'message': 'upstream failed',
            'type': 'server_error',
            'code': 'bad_gateway',
          },
        }),
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
