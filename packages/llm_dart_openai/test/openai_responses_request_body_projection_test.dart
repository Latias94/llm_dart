import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_openai/src/openai_responses_request_body_projection.dart';
import 'package:llm_dart_openai/src/openai_responses_request_context.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI Responses request body projection', () {
    test('encodes Responses body fields and warnings', () {
      const projection = OpenAIResponsesRequestBodyProjection();
      final warnings = <ModelWarning>[];
      final context = resolveOpenAIResponsesRequestContext(
        modelId: 'gpt-5-mini',
        providerOptions: const OpenAIGenerateTextOptions(
          conversation: 'conv_1',
          previousResponseId: 'resp_prev',
          store: false,
          parallelToolCalls: true,
          serviceTier: 'priority',
          verbosity: 'high',
          instructions: 'Use JSON.',
          maxToolCalls: 3,
          metadata: {'tenant': 'demo'},
          truncation: OpenAIResponseTruncation.auto,
          user: 'user_1',
          include: [
            OpenAIResponsesInclude.fileSearchCallResults,
            OpenAIResponsesInclude.webSearchCallActionSources,
          ],
          builtInTools: [OpenAIWebSearchTool.current()],
          promptCacheKey: 'cache_key',
          promptCacheRetention: OpenAIPromptCacheRetention.inMemory,
          safetyIdentifier: 'safe_1',
          logprobs: OpenAILogProbs.top(2),
          reasoningEffort: OpenAIReasoningEffort.high,
          responseFormat: OpenAIJsonSchemaResponseFormat(
            name: 'answer',
            schema: {'type': 'object'},
            strict: true,
          ),
        ),
      );

      final body = projection.encodeBody(
        modelId: 'gpt-5-mini',
        input: const [
          {'role': 'user', 'content': 'Hi'},
        ],
        options: const GenerateTextOptions(
          maxOutputTokens: 100,
          temperature: 0.7,
          topP: 0.9,
          reasoning: GenerateTextReasoningOptions(
            effort: ReasoningEffort.low,
          ),
        ),
        providerOptions: const OpenAIGenerateTextOptions(
          conversation: 'conv_1',
          previousResponseId: 'resp_prev',
          store: false,
          parallelToolCalls: true,
          serviceTier: 'priority',
          verbosity: 'high',
          instructions: 'Use JSON.',
          maxToolCalls: 3,
          metadata: {'tenant': 'demo'},
          truncation: OpenAIResponseTruncation.auto,
          user: 'user_1',
          include: [
            OpenAIResponsesInclude.fileSearchCallResults,
            OpenAIResponsesInclude.webSearchCallActionSources,
          ],
          builtInTools: [OpenAIWebSearchTool.current()],
          promptCacheKey: 'cache_key',
          promptCacheRetention: OpenAIPromptCacheRetention.inMemory,
          safetyIdentifier: 'safe_1',
          logprobs: OpenAILogProbs.top(2),
          reasoningEffort: OpenAIReasoningEffort.high,
          responseFormat: OpenAIJsonSchemaResponseFormat(
            name: 'answer',
            schema: {'type': 'object'},
            strict: true,
          ),
        ),
        stream: true,
        context: context,
        warnings: warnings,
      );

      expect(body['model'], 'gpt-5-mini');
      expect(body['input'], [
        {'role': 'user', 'content': 'Hi'},
      ]);
      expect(body['stream'], isTrue);
      expect(body['max_output_tokens'], 100);
      expect(body['temperature'], isNull);
      expect(body['top_p'], isNull);
      expect(body['conversation'], 'conv_1');
      expect(body['previous_response_id'], 'resp_prev');
      expect(body['store'], isFalse);
      expect(body['parallel_tool_calls'], isTrue);
      expect(body['service_tier'], 'priority');
      expect(body['instructions'], 'Use JSON.');
      expect(body['max_tool_calls'], 3);
      expect(body['metadata'], {'tenant': 'demo'});
      expect(body['truncation'], 'auto');
      expect(body['user'], 'user_1');
      expect(
        body['include'],
        [
          'file_search_call.results',
          'web_search_call.action.sources',
          'message.output_text.logprobs',
          'reasoning.encrypted_content',
        ],
      );
      expect(body['prompt_cache_key'], 'cache_key');
      expect(body['prompt_cache_retention'], 'in_memory');
      expect(body['safety_identifier'], 'safe_1');
      expect(body['top_logprobs'], 2);
      expect(body['reasoning'], {'effort': 'high'});
      expect(body['text'], {'verbosity': 'high'});
      expect(
        body['response_format'],
        {
          'type': 'json_schema',
          'json_schema': {
            'name': 'answer',
            'schema': {
              'type': 'object',
              'additionalProperties': false,
            },
            'strict': true,
          },
        },
      );
      expect(
        warnings.map((warning) => warning.field),
        containsAll([
          'conversation',
          'options.reasoning',
          'temperature',
          'topP',
        ]),
      );
    });

    test('auto-includes provider-native tool response fields', () {
      const projection = OpenAIResponsesRequestBodyProjection();
      final warnings = <ModelWarning>[];
      final context = resolveOpenAIResponsesRequestContext(
        modelId: 'gpt-4.1-mini',
        providerOptions: const OpenAIGenerateTextOptions(
          include: [OpenAIResponsesInclude.webSearchCallActionSources],
          builtInTools: [
            OpenAIWebSearchTool.current(),
            OpenAICodeInterpreterTool(),
          ],
        ),
      );

      final body = projection.encodeBody(
        modelId: 'gpt-4.1-mini',
        input: const [],
        options: const GenerateTextOptions(),
        providerOptions: const OpenAIGenerateTextOptions(
          include: [OpenAIResponsesInclude.webSearchCallActionSources],
          builtInTools: [
            OpenAIWebSearchTool.current(),
            OpenAICodeInterpreterTool(),
          ],
        ),
        stream: false,
        context: context,
        warnings: warnings,
      );

      expect(
        body['include'],
        [
          'web_search_call.action.sources',
          'code_interpreter_call.outputs',
        ],
      );
      expect(warnings, isEmpty);
    });

    test('warns and drops unsupported service tiers', () {
      const projection = OpenAIResponsesRequestBodyProjection();
      final warnings = <ModelWarning>[];
      final context = resolveOpenAIResponsesRequestContext(
        modelId: 'gpt-4.1-mini',
        providerOptions: const OpenAIGenerateTextOptions(
          serviceTier: 'flex',
        ),
      );

      final body = projection.encodeBody(
        modelId: 'gpt-4.1-mini',
        input: const [],
        options: const GenerateTextOptions(),
        providerOptions: const OpenAIGenerateTextOptions(
          serviceTier: 'flex',
        ),
        stream: false,
        context: context,
        warnings: warnings,
      );

      expect(body.containsKey('service_tier'), isFalse);
      expect(
        warnings,
        contains(
          isA<ModelWarning>().having(
            (warning) => warning.field,
            'field',
            'serviceTier',
          ),
        ),
      );
    });
  });
}
