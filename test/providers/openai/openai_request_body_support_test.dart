import 'package:llm_dart/legacy.dart';
import 'package:llm_dart/providers/openai/chat.dart' as openai_chat;
import 'package:llm_dart/providers/openai/client.dart' as openai_client;
import 'package:llm_dart/providers/openai/config.dart' as openai_config;
import 'package:llm_dart/providers/openai/responses.dart' as openai_responses;
import 'package:llm_dart/src/config/legacy_config_keys.dart';
import 'package:llm_dart/src/config/legacy_provider_options.dart';
import 'package:llm_dart_transport/dio.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI request body support', () {
    test('OpenAIChat preserves shared request fields after helper extraction',
        () async {
      Map<String, dynamic>? capturedBody;
      final dio = Dio();
      dio.options.baseUrl = 'https://api.openai.com/v1/';
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedBody = Map<String, dynamic>.from(
              options.data as Map<String, dynamic>,
            );
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 'chatcmpl_1',
                  'choices': [
                    {
                      'index': 0,
                      'finish_reason': 'stop',
                      'message': {
                        'role': 'assistant',
                        'content': 'Done.',
                      },
                    },
                  ],
                },
              ),
            );
          },
        ),
      );

      final config = _buildConfig(
        dio: dio,
        useResponsesApi: false,
      );
      final client = openai_client.OpenAIClient(config);
      final chat = openai_chat.OpenAIChat(client, config);

      await chat.chatWithTools(
        [ChatMessage.user('Return JSON.')],
        [_weatherTool()],
      );

      expect(capturedBody, isNotNull);
      expect(capturedBody!['messages'], isA<List>());
      expect(
        (capturedBody!['messages'] as List).first,
        {
          'role': 'system',
          'content': 'Be concise.',
        },
      );
      expect(capturedBody!['service_tier'], equals('priority'));
      expect(capturedBody!['frequency_penalty'], equals(0.2));
      expect(capturedBody!['presence_penalty'], equals(0.3));
      expect(capturedBody!['logit_bias'], equals({'42': 1.5}));
      expect(capturedBody!['seed'], equals(7));
      expect(capturedBody!['parallel_tool_calls'], isTrue);
      expect(capturedBody!['logprobs'], isTrue);
      expect(capturedBody!['top_logprobs'], equals(3));
      expect(capturedBody!['verbosity'], equals('high'));
      expect(capturedBody!['tool_choice'], equals({'type': 'auto'}));
      expect(
        (capturedBody!['response_format']
                as Map<String, dynamic>)['json_schema']['schema']
            ['additionalProperties'],
        isFalse,
      );
    });

    test(
        'OpenAIResponses preserves shared request fields and response extras after helper extraction',
        () async {
      Map<String, dynamic>? capturedBody;
      final dio = Dio();
      dio.options.baseUrl = 'https://api.openai.com/v1/';
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedBody = Map<String, dynamic>.from(
              options.data as Map<String, dynamic>,
            );
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 'resp_1',
                  'status': 'completed',
                  'output': [
                    {
                      'id': 'msg_1',
                      'type': 'message',
                      'status': 'completed',
                      'role': 'assistant',
                      'content': [
                        {
                          'type': 'output_text',
                          'text': 'Done.',
                          'annotations': [],
                        },
                      ],
                    },
                  ],
                },
              ),
            );
          },
        ),
      );

      final config = _buildConfig(
        dio: dio,
        useResponsesApi: true,
      );
      final client = openai_client.OpenAIClient(config);
      final responses = openai_responses.OpenAIResponses(client, config);

      await responses.chatWithTools(
        [ChatMessage.user('Return JSON.')],
        [_weatherTool()],
      );

      expect(capturedBody, isNotNull);
      expect(capturedBody!['input'], isA<List>());
      expect(
        (capturedBody!['input'] as List).first,
        {
          'role': 'system',
          'content': 'Be concise.',
        },
      );
      expect(capturedBody!['previous_response_id'], equals('resp_123'));
      expect(capturedBody!['service_tier'], equals('priority'));
      expect(capturedBody!['frequency_penalty'], equals(0.2));
      expect(capturedBody!['presence_penalty'], equals(0.3));
      expect(capturedBody!['logit_bias'], equals({'42': 1.5}));
      expect(capturedBody!['seed'], equals(7));
      expect(capturedBody!['parallel_tool_calls'], isTrue);
      expect(capturedBody!['logprobs'], isTrue);
      expect(capturedBody!['top_logprobs'], equals(3));
      expect(capturedBody!.containsKey('verbosity'), isFalse);
      expect(capturedBody!['tool_choice'], equals({'type': 'auto'}));
      expect((capturedBody!['tools'] as List), hasLength(2));
      expect(
        (capturedBody!['response_format']
                as Map<String, dynamic>)['json_schema']['schema']
            ['additionalProperties'],
        isFalse,
      );
    });

    test('OpenAIResponsesResponse remains available on the legacy export path',
        () {
      final response = openai_responses.OpenAIResponsesResponse(
        {
          'id': 'resp_legacy_1',
          'output': [
            {
              'type': 'message',
              'content': [
                {
                  'type': 'output_text',
                  'text': 'Done.',
                },
              ],
            },
            {
              'type': 'function_call',
              'call_id': 'call_1',
              'name': 'weather',
              'arguments': '{"city":"Hong Kong"}',
            },
          ],
          'usage': {
            'prompt_tokens': 1,
            'completion_tokens': 2,
            'total_tokens': 3,
          },
        },
        'Need search',
      );

      expect(response.responseId, equals('resp_legacy_1'));
      expect(response.text, equals('Done.'));
      expect(response.thinking, equals('Need search'));
      expect(response.toolCalls, hasLength(1));
      expect(response.toolCalls!.single.id, equals('call_1'));
      expect(response.usage?.totalTokens, equals(3));
    });
  });
}

openai_config.OpenAIConfig _buildConfig({
  required Dio dio,
  required bool useResponsesApi,
}) {
  final originalConfig = LLMConfig(
    apiKey: 'test-key',
    baseUrl: 'https://api.openai.com/v1/',
    model: 'gpt-4.1-mini',
  ).withExtensions({
    LegacyExtensionKeys.customDio: dio,
    legacyProviderOptionsBagKey: {
      LegacyProviderOptionNamespaces.openai: {
        LegacyExtensionKeys.frequencyPenalty: 0.2,
        LegacyExtensionKeys.presencePenalty: 0.3,
        LegacyExtensionKeys.logitBias: {'42': 1.5},
        LegacyExtensionKeys.seed: 7,
        LegacyExtensionKeys.parallelToolCalls: true,
        LegacyExtensionKeys.logprobs: true,
        LegacyExtensionKeys.topLogprobs: 3,
        LegacyExtensionKeys.verbosity: 'high',
      },
    },
  });

  return openai_config.OpenAIConfig(
    apiKey: 'test-key',
    baseUrl: 'https://api.openai.com/v1/',
    model: 'gpt-4.1-mini',
    systemPrompt: 'Be concise.',
    serviceTier: ServiceTier.priority,
    useResponsesAPI: useResponsesApi,
    previousResponseId: useResponsesApi ? 'resp_123' : null,
    builtInTools: useResponsesApi ? [OpenAIBuiltInTools.webSearch()] : null,
    toolChoice: const AutoToolChoice(),
    jsonSchema: const StructuredOutputFormat(
      name: 'answer',
      description: 'Structured answer payload.',
      strict: true,
      schema: {
        'type': 'object',
        'properties': {
          'value': {'type': 'string'},
        },
        'required': ['value'],
      },
    ),
    originalConfig: originalConfig,
  );
}

Tool _weatherTool() => Tool.function(
      name: 'weather',
      description: 'Get weather information.',
      parameters: const ParametersSchema(
        schemaType: 'object',
        properties: {
          'city': ParameterProperty(
            propertyType: 'string',
            description: 'City name.',
          ),
        },
        required: ['city'],
      ),
    );
