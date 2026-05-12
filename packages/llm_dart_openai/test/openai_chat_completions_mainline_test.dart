import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_test/llm_dart_test.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI chat-completions mainline', () {
    test(
        'OpenAI can opt out of Responses API and uses chat completions request encoding',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_1',
                'model': 'gpt-4.1-mini',
                'created': 1710000000,
                'service_tier': 'flex',
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'tool_calls',
                    'message': {
                      'role': 'assistant',
                      'reasoning_content': 'Plan first.',
                      'content': 'Here is the answer.',
                      'tool_calls': [
                        {
                          'id': 'call_1',
                          'type': 'function',
                          'function': {
                            'name': 'weather',
                            'arguments': '{"city":"Shanghai"}',
                          },
                        },
                      ],
                    },
                  },
                ],
                'usage': {
                  'prompt_tokens': 10,
                  'completion_tokens': 5,
                  'total_tokens': 15,
                  'completion_tokens_details': {
                    'reasoning_tokens': 2,
                  },
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      final result = await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            SystemPromptMessage.text('Be concise.'),
            UserPromptMessage.text('Use the weather tool and answer in JSON.'),
          ],
          options: const GenerateTextOptions(
            presencePenalty: 0.1,
            frequencyPenalty: 0.2,
            seed: 1234,
          ),
          tools: [
            FunctionToolDefinition(
              name: 'weather',
              description: 'Get the weather.',
              inputSchema: ToolJsonSchema.object(
                properties: {
                  'city': {'type': 'string'},
                },
                required: ['city'],
              ),
              strict: true,
            ),
          ],
          toolChoice: const SpecificToolChoice('weather'),
          callOptions: const CallOptions(
            providerOptions: OpenAIGenerateTextOptions(
              parallelToolCalls: true,
              serviceTier: 'priority',
              verbosity: 'low',
              user: 'user_123',
              responseFormat: OpenAIJsonSchemaResponseFormat(
                name: 'answer',
                schema: {
                  'type': 'object',
                  'properties': {
                    'value': {'type': 'string'},
                  },
                },
                strict: true,
              ),
            ),
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.uri.toString(), contains('/chat/completions'));

      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(requestBody['model'], 'gpt-4.1-mini');
      expect(requestBody['stream'], isFalse);
      expect(
        requestBody['messages'],
        [
          {
            'role': 'system',
            'content': 'Be concise.',
          },
          {
            'role': 'user',
            'content': 'Use the weather tool and answer in JSON.',
          },
        ],
      );
      expect(
        requestBody['tools'],
        [
          {
            'type': 'function',
            'function': {
              'name': 'weather',
              'description': 'Get the weather.',
              'parameters': {
                'type': 'object',
                'properties': {
                  'city': {'type': 'string'},
                },
                'required': ['city'],
              },
              'strict': true,
            },
          },
        ],
      );
      expect(
        requestBody['tool_choice'],
        {
          'type': 'function',
          'function': {'name': 'weather'},
        },
      );
      expect(requestBody['parallel_tool_calls'], isTrue);
      expect(requestBody['service_tier'], 'priority');
      expect(requestBody['verbosity'], 'low');
      expect(requestBody['user'], 'user_123');
      expect(requestBody['presence_penalty'], 0.1);
      expect(requestBody['frequency_penalty'], 0.2);
      expect(requestBody['seed'], 1234);
      expect(
        requestBody['response_format'],
        {
          'type': 'json_schema',
          'json_schema': {
            'name': 'answer',
            'schema': {
              'type': 'object',
              'properties': {
                'value': {'type': 'string'},
              },
              'additionalProperties': false,
            },
            'strict': true,
          },
        },
      );

      expect(result.finishReason, FinishReason.toolCalls);
      expect(result.rawFinishReason, 'tool_calls');
      expect(result.text, 'Here is the answer.');
      expect(result.reasoningText, 'Plan first.');
      expect(result.usage?.reasoningTokens, 2);

      final toolCall = result.content.whereType<ToolCallContentPart>().single;
      expect(toolCall.toolCall.toolCallId, 'call_1');
      expect(toolCall.toolCall.toolName, 'weather');
      expect(
        toolCall.toolCall.input,
        {
          'city': 'Shanghai',
        },
      );
    });

    test(
        'chat completions default system messages to developer for OpenAI reasoning models',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_reasoning_1',
                'model': 'gpt-5.4',
                'created': 1710000000,
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
                'usage': {
                  'prompt_tokens': 4,
                  'completion_tokens': 1,
                  'total_tokens': 5,
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-5.4',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      final result = await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            SystemPromptMessage.text('Think carefully.'),
            UserPromptMessage.text('Say done.'),
          ],
          options: const GenerateTextOptions(
            reasoning: GenerateTextReasoningOptions(
              effort: ReasoningEffort.high,
            ),
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['messages'],
        [
          {
            'role': 'developer',
            'content': 'Think carefully.',
          },
          {
            'role': 'user',
            'content': 'Say done.',
          },
        ],
      );
      expect(requestBody['reasoning_effort'], 'high');
      expect(result.warnings, isEmpty);
    });

    test('chat completions split think tags into reasoning and visible text',
        () async {
      final model = OpenAI(
        apiKey: 'test-key',
        profile: const DeepSeekProfile(),
        transport: _FakeTransportClient(
          onSend: (request) async {
            expect(request.uri.toString(), contains('/chat/completions'));
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_think_1',
                'model': 'deepseek-reasoner',
                'created': 1710000000,
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'stop',
                    'message': {
                      'role': 'assistant',
                      'content': '<think>Plan first.</think>Visible answer.',
                    },
                  },
                ],
                'usage': {
                  'prompt_tokens': 4,
                  'completion_tokens': 2,
                  'total_tokens': 6,
                  'completion_tokens_details': {
                    'reasoning_tokens': 1,
                  },
                },
              },
            );
          },
        ),
      ).chatModel(
        'deepseek-reasoner',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      final result = await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Think first, then answer.'),
          ],
        ),
      );

      expect(result.reasoningText, 'Plan first.');
      expect(result.text, 'Visible answer.');
      expect(result.usage?.reasoningTokens, 1);
    });

    test('chat completions encode typed DeepSeek provider options', () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        profile: const DeepSeekProfile(),
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_deepseek_options',
                'model': 'deepseek-chat',
                'created': 1710000001,
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'stop',
                    'message': {
                      'role': 'assistant',
                      'content': '{"value":"Done."}',
                    },
                  },
                ],
              },
            );
          },
        ),
      ).chatModel('deepseek-chat');

      final result = await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Return JSON.'),
          ],
          callOptions: const CallOptions(
            providerOptions: DeepSeekGenerateTextOptions(
              logprobs: false,
              topLogprobs: 2,
              frequencyPenalty: 0.1,
              presencePenalty: 0.2,
              responseFormat: {'type': 'json_object'},
            ),
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(requestBody['logprobs'], isFalse);
      expect(requestBody['top_logprobs'], 2);
      expect(requestBody['frequency_penalty'], 0.1);
      expect(requestBody['presence_penalty'], 0.2);
      expect(requestBody['response_format'], {'type': 'json_object'});
      expect(result.text, '{"value":"Done."}');
    });

    test('chat completions drop unsupported DeepSeek reasoner options',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        profile: const DeepSeekProfile(),
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_deepseek_reasoner_options',
                'model': 'deepseek-reasoner',
                'created': 1710000002,
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
            );
          },
        ),
      ).chatModel('deepseek-reasoner');

      final result = await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Think first.'),
          ],
          callOptions: const CallOptions(
            providerOptions: DeepSeekGenerateTextOptions(
              logprobs: true,
              topLogprobs: 2,
              frequencyPenalty: 0.1,
              presencePenalty: 0.2,
            ),
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(requestBody.containsKey('logprobs'), isFalse);
      expect(requestBody.containsKey('top_logprobs'), isFalse);
      expect(requestBody.containsKey('frequency_penalty'), isFalse);
      expect(requestBody.containsKey('presence_penalty'), isFalse);
      expect(
        result.warnings.map((warning) => warning.field),
        containsAll([
          'logprobs',
          'topLogprobs',
          'frequencyPenalty',
          'presencePenalty',
        ]),
      );
    });

    test('chat completions keep system messages for OpenAI gpt-5 chat variants',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_gpt5_chat_1',
                'model': 'gpt-5-chat-latest',
                'created': 1710000000,
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
                'usage': {
                  'prompt_tokens': 4,
                  'completion_tokens': 1,
                  'total_tokens': 5,
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-5-chat-latest',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      final result = await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            SystemPromptMessage.text('Think carefully.'),
            UserPromptMessage.text('Say done.'),
          ],
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['messages'],
        [
          {
            'role': 'system',
            'content': 'Think carefully.',
          },
          {
            'role': 'user',
            'content': 'Say done.',
          },
        ],
      );
      expect(result.warnings, isEmpty);
    });

    test(
        'chat completions can override reasoning-model system messages back to system',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_reasoning_override_1',
                'model': 'gpt-5.4',
                'created': 1710000000,
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
                'usage': {
                  'prompt_tokens': 4,
                  'completion_tokens': 1,
                  'total_tokens': 5,
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-5.4',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            SystemPromptMessage.text('Think carefully.'),
            UserPromptMessage.text('Say done.'),
          ],
          callOptions: const CallOptions(
            providerOptions: OpenAIGenerateTextOptions(
              systemMessageMode: OpenAISystemMessageMode.system,
            ),
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['messages'],
        [
          {
            'role': 'system',
            'content': 'Think carefully.',
          },
          {
            'role': 'user',
            'content': 'Say done.',
          },
        ],
      );
    });

    test('chat completions can remove system messages with a warning',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_system_remove_1',
                'model': 'gpt-4.1-mini',
                'created': 1710000000,
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
                'usage': {
                  'prompt_tokens': 3,
                  'completion_tokens': 1,
                  'total_tokens': 4,
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      final result = await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            SystemPromptMessage.text('Be concise.'),
            UserPromptMessage.text('Say done.'),
          ],
          callOptions: const CallOptions(
            providerOptions: OpenAIGenerateTextOptions(
              systemMessageMode: OpenAISystemMessageMode.remove,
            ),
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['messages'],
        [
          {
            'role': 'user',
            'content': 'Say done.',
          },
        ],
      );
      expect(
        result.warnings,
        contains(
          const ModelWarning(
            type: ModelWarningType.other,
            field: 'prompt.system',
            message: 'system messages are removed for this model',
          ),
        ),
      );
    });

    test(
        'chat completions map maxOutputTokens to max_completion_tokens for OpenAI reasoning models',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_reasoning_tokens_1',
                'model': 'o4-mini',
                'created': 1710000000,
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
                'usage': {
                  'prompt_tokens': 3,
                  'completion_tokens': 1,
                  'total_tokens': 4,
                },
              },
            );
          },
        ),
      ).chatModel(
        'o4-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      final result = await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Say done.'),
          ],
          options: const GenerateTextOptions(
            maxOutputTokens: 48,
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(requestBody['max_completion_tokens'], 48);
      expect(requestBody.containsKey('max_tokens'), isFalse);
      expect(result.warnings, isEmpty);
    });

    test(
        'chat completions let provider maxCompletionTokens override shared maxOutputTokens',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_reasoning_tokens_override_1',
                'model': 'o4-mini',
                'created': 1710000000,
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
                'usage': {
                  'prompt_tokens': 3,
                  'completion_tokens': 1,
                  'total_tokens': 4,
                },
              },
            );
          },
        ),
      ).chatModel(
        'o4-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      final result = await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Say done.'),
          ],
          options: const GenerateTextOptions(
            maxOutputTokens: 48,
          ),
          callOptions: const CallOptions(
            providerOptions: OpenAIGenerateTextOptions(
              maxCompletionTokens: 24,
            ),
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(requestBody['max_completion_tokens'], 24);
      expect(requestBody.containsKey('max_tokens'), isFalse);
      expect(result.warnings, isEmpty);
    });

    test(
        'chat completions forceReasoning defaults to developer and applies reasoning compatibility',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_force_reasoning_1',
                'model': 'stealth-reasoning-model',
                'created': 1710000000,
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
                'usage': {
                  'prompt_tokens': 6,
                  'completion_tokens': 1,
                  'total_tokens': 7,
                },
              },
            );
          },
        ),
      ).chatModel(
        'stealth-reasoning-model',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      final result = await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            SystemPromptMessage.text('Think carefully.'),
            UserPromptMessage.text('Say done.'),
          ],
          options: const GenerateTextOptions(
            maxOutputTokens: 48,
            temperature: 0.5,
            topP: 0.7,
          ),
          callOptions: const CallOptions(
            providerOptions: OpenAIGenerateTextOptions(
              forceReasoning: true,
              logprobs: OpenAILogProbs.top(2),
            ),
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['messages'],
        [
          {
            'role': 'developer',
            'content': 'Think carefully.',
          },
          {
            'role': 'user',
            'content': 'Say done.',
          },
        ],
      );
      expect(requestBody['max_completion_tokens'], 48);
      expect(requestBody.containsKey('max_tokens'), isFalse);
      expect(requestBody.containsKey('temperature'), isFalse);
      expect(requestBody.containsKey('top_p'), isFalse);
      expect(requestBody.containsKey('logprobs'), isFalse);
      expect(requestBody.containsKey('top_logprobs'), isFalse);
      expect(
        result.warnings,
        containsAll([
          const ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'temperature',
            message: 'temperature is not supported for reasoning models',
          ),
          const ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'topP',
            message: 'topP is not supported for reasoning models',
          ),
          const ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'logprobs',
            message: 'logprobs is not supported for reasoning models',
          ),
          const ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'topLogProbs',
            message: 'topLogprobs is not supported for reasoning models',
          ),
        ]),
      );
    });

    test(
        'chat completions allow non-reasoning parameters for gpt-5.4 when reasoningEffort is none',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_reasoning_none_1',
                'model': 'gpt-5.4',
                'created': 1710000000,
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
                'usage': {
                  'prompt_tokens': 3,
                  'completion_tokens': 1,
                  'total_tokens': 4,
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-5.4',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      final result = await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Say done.'),
          ],
          options: const GenerateTextOptions(
            maxOutputTokens: 48,
            temperature: 0.5,
            topP: 0.7,
          ),
          callOptions: const CallOptions(
            providerOptions: OpenAIGenerateTextOptions(
              reasoningEffort: OpenAIReasoningEffort.none,
              logprobs: OpenAILogProbs.top(2),
            ),
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(requestBody['reasoning_effort'], 'none');
      expect(requestBody['max_completion_tokens'], 48);
      expect(requestBody.containsKey('max_tokens'), isFalse);
      expect(requestBody['temperature'], 0.5);
      expect(requestBody['top_p'], 0.7);
      expect(requestBody['logprobs'], isTrue);
      expect(requestBody['top_logprobs'], 2);
      expect(result.warnings, isEmpty);
    });

    test('chat completions warning-drop unsupported OpenAI flex service tiers',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_service_tier_1',
                'model': 'gpt-4o-mini',
                'created': 1710000000,
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
                'usage': {
                  'prompt_tokens': 3,
                  'completion_tokens': 1,
                  'total_tokens': 4,
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-4o-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      final result = await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Say done.'),
          ],
          callOptions: const CallOptions(
            providerOptions: OpenAIGenerateTextOptions(
              serviceTier: 'flex',
            ),
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(requestBody.containsKey('service_tier'), isFalse);
      expect(
        result.warnings,
        contains(
          const ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'serviceTier',
            message:
                'flex processing is only available for o3, o4-mini, and gpt-5 models',
          ),
        ),
      );
    });

    test('chat completions encode and decode text logprobs', () async {
      TransportRequest? capturedRequest;
      const responseLogprobs = [
        {
          'token': 'Hello',
          'logprob': -0.1,
          'top_logprobs': [
            {
              'token': 'Hello',
              'logprob': -0.1,
            },
            {
              'token': 'Hi',
              'logprob': -0.4,
            },
          ],
        },
      ];

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_logprobs_1',
                'model': 'gpt-4.1-mini',
                'created': 1710000000,
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'stop',
                    'logprobs': {
                      'content': responseLogprobs,
                    },
                    'message': {
                      'role': 'assistant',
                      'content': 'Hello',
                    },
                  },
                ],
                'usage': {
                  'prompt_tokens': 4,
                  'completion_tokens': 1,
                  'total_tokens': 5,
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      final result = await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Say hello.'),
          ],
          callOptions: const CallOptions(
            providerOptions: OpenAIGenerateTextOptions(
              logprobs: OpenAILogProbs.top(3),
            ),
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(requestBody['logprobs'], isTrue);
      expect(requestBody['top_logprobs'], 3);

      final textPart = result.content.whereType<TextContentPart>().single;
      expect(
        textPart.providerMetadata?['openai'],
        allOf(
          containsPair('finishReason', 'stop'),
          containsPair('logprobs', responseLogprobs),
        ),
      );
      expect(
        result.providerMetadata?['openai'],
        containsPair('logprobs', responseLogprobs),
      );
    });

    test(
        'chat completions encode PDF file prompt parts with a default filename',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_pdf_1',
                'model': 'gpt-4.1-mini',
                'created': 1710000000,
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
                'usage': {
                  'prompt_tokens': 4,
                  'completion_tokens': 1,
                  'total_tokens': 5,
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage(
              parts: const [
                TextPromptPart('Summarize this document.'),
                FilePromptPart(
                  mediaType: 'application/pdf',
                  data: FileBytesData.constBytes([1, 2, 3, 4, 5]),
                ),
              ],
            ),
          ],
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['messages'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'Summarize this document.',
              },
              {
                'type': 'file',
                'file': {
                  'filename': 'part-1.pdf',
                  'file_data': 'data:application/pdf;base64,AQIDBAU=',
                },
              },
            ],
          },
        ],
      );
    });

    test(
        'chat completions encode OpenAI-owned PDF file handles through provider references',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_pdf_file_id_1',
                'model': 'gpt-4.1-mini',
                'created': 1710000000,
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
                'usage': {
                  'prompt_tokens': 4,
                  'completion_tokens': 1,
                  'total_tokens': 5,
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage(
              parts: const [
                FilePromptPart(
                  mediaType: 'application/pdf',
                  data: FileProviderReferenceData(
                    ProviderReference({'openai': 'file-pdf-12345'}),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['messages'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'file',
                'file': {
                  'file_id': 'file-pdf-12345',
                },
              },
            ],
          },
        ],
      );
    });

    test('chat completions encode OpenAI provider reference PDF handles',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_pdf_provider_ref_1',
                'model': 'gpt-4.1-mini',
                'created': 1710000000,
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
                'usage': {
                  'prompt_tokens': 4,
                  'completion_tokens': 1,
                  'total_tokens': 5,
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage(
              parts: const [
                FilePromptPart(
                  mediaType: 'application/pdf',
                  data: FileProviderReferenceData(
                    ProviderReference({'openai': 'file-pdf-12345'}),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['messages'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'file',
                'file': {
                  'file_id': 'file-pdf-12345',
                },
              },
            ],
          },
        ],
      );
    });

    test(
        'chat completions encode OpenAI image detail through prompt part options',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_image_detail_1',
                'model': 'gpt-4.1-mini',
                'created': 1710000000,
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
                'usage': {
                  'prompt_tokens': 4,
                  'completion_tokens': 1,
                  'total_tokens': 5,
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage(
              parts: const [
                ImagePromptPart(
                  mediaType: 'image/png',
                  data: FileBytesData.constBytes([0, 1, 2, 3]),
                  providerOptions: OpenAIPromptPartOptions(
                    imageDetail: 'low',
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['messages'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/png;base64,AAECAw==',
                  'detail': 'low',
                },
              },
            ],
          },
        ],
      );
    });

    test('chat completions reject legacy metadata fileId for PDF identity',
        () async {
      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (_) async => TransportResponse(
            statusCode: 200,
            body: const {},
          ),
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      await expectLater(
        model.doGenerate(
          GenerateTextRequest(
            prompt: [
              UserPromptMessage(
                parts: const [
                  FilePromptPart(
                    mediaType: 'application/pdf',
                    data: FileTextData('legacy-metadata-only'),
                    providerMetadata: ProviderMetadata({
                      'openai': {
                        'fileId': 'file-pdf-123',
                      },
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            contains('PDF file prompt parts need bytes'),
          ),
        ),
      );
    });

    test('chat completions encode audio file prompt parts', () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_audio_1',
                'model': 'gpt-4.1-mini',
                'created': 1710000000,
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
                'usage': {
                  'prompt_tokens': 4,
                  'completion_tokens': 1,
                  'total_tokens': 5,
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage(
              parts: const [
                FilePromptPart(
                  mediaType: 'audio/mpeg',
                  data: FileBytesData.constBytes([1, 2, 3, 4]),
                ),
              ],
            ),
          ],
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['messages'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_audio',
                'input_audio': {
                  'data': 'AQIDBA==',
                  'format': 'mp3',
                },
              },
            ],
          },
        ],
      );
    });

    test('chat completions encode image file prompt parts as image_url',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_image_1',
                'model': 'gpt-4.1-mini',
                'created': 1710000000,
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
                'usage': {
                  'prompt_tokens': 4,
                  'completion_tokens': 1,
                  'total_tokens': 5,
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage(
              parts: const [
                FilePromptPart(
                  mediaType: 'image/png',
                  data: FileBytesData.constBytes([0, 1, 2, 3]),
                ),
              ],
            ),
          ],
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['messages'],
        [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/png;base64,AAECAw==',
                },
              },
            ],
          },
        ],
      );
    });

    test('chat completions reject unsupported file media types before send',
        () async {
      var sendCount = 0;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            sendCount += 1;
            return TransportResponse(statusCode: 200, body: const {});
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      await expectLater(
        model.doGenerate(
          GenerateTextRequest(
            prompt: [
              UserPromptMessage(
                parts: const [
                  FilePromptPart(
                    mediaType: 'text/plain',
                    data: FileBytesData.constBytes([1, 2, 3]),
                  ),
                ],
              ),
            ],
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            contains('file prompt media type text/plain'),
          ),
        ),
      );

      await expectLater(
        model.doGenerate(
          GenerateTextRequest(
            prompt: [
              UserPromptMessage.text('hello'),
            ],
            callOptions: const CallOptions(
              providerOptions: OpenAIGenerateTextOptions(
                instructions: 'Override the conversation framing.',
              ),
            ),
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            contains('instructions'),
          ),
        ),
      );

      await expectLater(
        model.doGenerate(
          GenerateTextRequest(
            prompt: [
              UserPromptMessage.text('hello'),
            ],
            callOptions: const CallOptions(
              providerOptions: OpenAIGenerateTextOptions(
                maxToolCalls: 2,
              ),
            ),
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            contains('maxToolCalls'),
          ),
        ),
      );

      await expectLater(
        model.doGenerate(
          GenerateTextRequest(
            prompt: [
              UserPromptMessage.text('hello'),
            ],
            callOptions: const CallOptions(
              providerOptions: OpenAIGenerateTextOptions(
                metadata: {
                  'traceId': 'trace_123',
                },
              ),
            ),
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            contains('metadata'),
          ),
        ),
      );

      await expectLater(
        model.doGenerate(
          GenerateTextRequest(
            prompt: [
              UserPromptMessage.text('hello'),
            ],
            callOptions: const CallOptions(
              providerOptions: OpenAIGenerateTextOptions(
                truncation: OpenAIResponseTruncation.disabled,
              ),
            ),
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            contains('truncation'),
          ),
        ),
      );

      await expectLater(
        model.doGenerate(
          GenerateTextRequest(
            prompt: [
              UserPromptMessage.text('hello'),
            ],
            callOptions: const CallOptions(
              providerOptions: OpenAIGenerateTextOptions(
                include: [
                  OpenAIResponsesInclude.reasoningEncryptedContent,
                ],
              ),
            ),
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            contains('include'),
          ),
        ),
      );

      await expectLater(
        model.doGenerate(
          GenerateTextRequest(
            prompt: [
              UserPromptMessage.text('hello'),
            ],
            callOptions: const CallOptions(
              providerOptions: OpenAIGenerateTextOptions(
                promptCacheKey: 'cache_key_123',
              ),
            ),
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            contains('promptCacheKey'),
          ),
        ),
      );

      await expectLater(
        model.doGenerate(
          GenerateTextRequest(
            prompt: [
              UserPromptMessage.text('hello'),
            ],
            callOptions: const CallOptions(
              providerOptions: OpenAIGenerateTextOptions(
                promptCacheRetention:
                    OpenAIPromptCacheRetention.twentyFourHours,
              ),
            ),
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            contains('promptCacheRetention'),
          ),
        ),
      );

      await expectLater(
        model.doGenerate(
          GenerateTextRequest(
            prompt: [
              UserPromptMessage.text('hello'),
            ],
            callOptions: const CallOptions(
              providerOptions: OpenAIGenerateTextOptions(
                safetyIdentifier: 'safe_user_123',
              ),
            ),
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            contains('safetyIdentifier'),
          ),
        ),
      );

      expect(sendCount, 0);
    });

    test('chat completions reject PDF file URIs before send', () async {
      var sendCount = 0;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            sendCount += 1;
            return TransportResponse(statusCode: 200, body: const {});
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      await expectLater(
        model.doGenerate(
          GenerateTextRequest(
            prompt: [
              UserPromptMessage(
                parts: [
                  FilePromptPart(
                    mediaType: 'application/pdf',
                    data: FileUrlData(
                      Uri.parse('https://example.com/document.pdf'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            contains('PDF file prompt parts do not support URIs'),
          ),
        ),
      );

      expect(sendCount, 0);
    });

    test('chat completions stream maps reasoning, text, and tool-call deltas',
        () async {
      final model = OpenAI(
        apiKey: 'test-key',
        profile: const DeepSeekProfile(),
        transport: _FakeTransportClient(
          onSendStream: (request) async {
            expect(request.uri.toString(), contains('/chat/completions'));

            return StreamingTransportResponse(
              statusCode: 200,
              stream: Stream.fromIterable([
                utf8.encode(
                  'data: {"id":"chatcmpl_1","object":"chat.completion.chunk","created":1710000000,"model":"deepseek-reasoner","choices":[{"index":0,"delta":{"role":"assistant","reasoning_content":"Plan"},"finish_reason":null}]}\n\n',
                ),
                utf8.encode(
                  'data: {"id":"chatcmpl_1","object":"chat.completion.chunk","created":1710000000,"model":"deepseek-reasoner","choices":[{"index":0,"delta":{"content":"Hello"},"finish_reason":null}]}\n\n',
                ),
                utf8.encode(
                  'data: {"id":"chatcmpl_1","object":"chat.completion.chunk","created":1710000000,"model":"deepseek-reasoner","choices":[{"index":0,"delta":{"tool_calls":[{"index":0,"id":"call_1","type":"function","function":{"name":"weather","arguments":"{\\"city\\":\\"Sh"}}]},"finish_reason":null}]}\n\n',
                ),
                utf8.encode(
                  'data: {"id":"chatcmpl_1","object":"chat.completion.chunk","created":1710000000,"model":"deepseek-reasoner","choices":[{"index":0,"delta":{"tool_calls":[{"index":0,"function":{"arguments":"anghai\\"}"}}]},"finish_reason":null}]}\n\n',
                ),
                utf8.encode(
                  'data: {"id":"chatcmpl_1","object":"chat.completion.chunk","created":1710000000,"model":"deepseek-reasoner","system_fingerprint":"fp_1","choices":[{"index":0,"delta":{},"finish_reason":"tool_calls"}],"usage":{"prompt_tokens":12,"completion_tokens":8,"total_tokens":20,"completion_tokens_details":{"reasoning_tokens":3}}}\n\n',
                ),
                utf8.encode('data: [DONE]\n\n'),
              ]),
            );
          },
        ),
      ).chatModel('deepseek-reasoner');

      final events = await model
          .doStream(
            GenerateTextRequest(
              prompt: [
                UserPromptMessage.text('Think and call the weather tool.'),
              ],
            ),
          )
          .toList();

      expect(events.first, isA<StartEvent>());

      final responseMetadata = events.whereType<ResponseMetadataEvent>().single;
      expect(responseMetadata.responseId, 'chatcmpl_1');
      expect(responseMetadata.modelId, 'deepseek-reasoner');
      expect(
        responseMetadata.providerMetadata?['deepseek'],
        containsPair('responseId', 'chatcmpl_1'),
      );

      expect(events.whereType<ReasoningStartEvent>().single.id, 'reasoning_0');
      expect(events.whereType<ReasoningDeltaEvent>().single.delta, 'Plan');
      expect(events.whereType<ReasoningEndEvent>().single.id, 'reasoning_0');

      expect(events.whereType<TextStartEvent>().single.id, 'text_0');
      expect(events.whereType<TextDeltaEvent>().single.delta, 'Hello');
      expect(events.whereType<TextEndEvent>().single.id, 'text_0');

      final toolInputStart = events.whereType<ToolInputStartEvent>().single;
      expect(toolInputStart.toolCallId, 'call_1');
      expect(toolInputStart.toolName, 'weather');

      final toolInputDeltas =
          events.whereType<ToolInputDeltaEvent>().map((event) => event.delta);
      expect(toolInputDeltas, ['{"city":"Sh', 'anghai"}']);

      expect(events.whereType<ToolInputEndEvent>().single.toolCallId, 'call_1');

      final toolCall = events.whereType<ToolCallEvent>().single.toolCall;
      expect(toolCall.toolCallId, 'call_1');
      expect(toolCall.toolName, 'weather');
      expect(
        toolCall.input,
        {
          'city': 'Shanghai',
        },
      );

      final finish = events.whereType<FinishEvent>().single;
      expect(finish.finishReason, FinishReason.toolCalls);
      expect(finish.rawFinishReason, 'tool_calls');
      expect(finish.usage?.reasoningTokens, 3);
      expect(finish.usage?.totalTokens, 20);
      expect(
        finish.providerMetadata?['deepseek'],
        allOf(
          containsPair('responseId', 'chatcmpl_1'),
          containsPair('systemFingerprint', 'fp_1'),
        ),
      );
    });

    test('chat completions stream maps logprobs to text event metadata',
        () async {
      TransportRequest? capturedRequest;
      const responseLogprobs = [
        {
          'token': 'Hello',
          'logprob': -0.1,
          'top_logprobs': [
            {
              'token': 'Hello',
              'logprob': -0.1,
            },
            {
              'token': 'Hi',
              'logprob': -0.4,
            },
          ],
        },
      ];

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSendStream: (request) async {
            capturedRequest = request;

            return StreamingTransportResponse(
              statusCode: 200,
              stream: Stream.fromIterable([
                utf8.encode(
                  'data: ${jsonEncode({
                        'id': 'chatcmpl_logprobs_stream_1',
                        'object': 'chat.completion.chunk',
                        'created': 1710000000,
                        'model': 'gpt-4.1-mini',
                        'choices': [
                          {
                            'index': 0,
                            'delta': {
                              'content': 'Hello',
                            },
                            'logprobs': {
                              'content': responseLogprobs,
                            },
                            'finish_reason': null,
                          },
                        ],
                      })}\n\n',
                ),
                utf8.encode(
                  'data: ${jsonEncode({
                        'id': 'chatcmpl_logprobs_stream_1',
                        'object': 'chat.completion.chunk',
                        'created': 1710000000,
                        'model': 'gpt-4.1-mini',
                        'choices': [
                          {
                            'index': 0,
                            'delta': <String, Object?>{},
                            'finish_reason': 'stop',
                          },
                        ],
                        'usage': {
                          'prompt_tokens': 4,
                          'completion_tokens': 1,
                          'total_tokens': 5,
                        },
                      })}\n\n',
                ),
                utf8.encode('data: [DONE]\n\n'),
              ]),
            );
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      final events = await model
          .doStream(
            GenerateTextRequest(
              prompt: [
                UserPromptMessage.text('Say hello.'),
              ],
              callOptions: const CallOptions(
                providerOptions: OpenAIGenerateTextOptions(
                  logprobs: OpenAILogProbs.enabled(),
                ),
              ),
            ),
          )
          .toList();

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(requestBody['logprobs'], isTrue);
      expect(requestBody['top_logprobs'], 0);

      final textDelta = events.whereType<TextDeltaEvent>().single;
      expect(
        textDelta.providerMetadata?['openai'],
        allOf(
          containsPair('responseId', 'chatcmpl_logprobs_stream_1'),
          containsPair('logprobs', responseLogprobs),
        ),
      );

      final textEnd = events.whereType<TextEndEvent>().single;
      expect(
        textEnd.providerMetadata?['openai'],
        containsPair('responseId', 'chatcmpl_logprobs_stream_1'),
      );

      final finish = events.whereType<FinishEvent>().single;
      expect(
        finish.providerMetadata?['openai'],
        allOf(
          containsPair('responseId', 'chatcmpl_logprobs_stream_1'),
          containsPair('logprobs', responseLogprobs),
        ),
      );
    });

    test(
        'chat completions mainline rejects Responses-only provider options before sending',
        () async {
      var sendCount = 0;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            sendCount += 1;
            return TransportResponse(statusCode: 200, body: const {});
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      await expectLater(
        model.doGenerate(
          GenerateTextRequest(
            prompt: [
              UserPromptMessage.text('hello'),
            ],
            callOptions: const CallOptions(
              providerOptions: OpenAIGenerateTextOptions(
                previousResponseId: 'resp_prev',
              ),
            ),
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            contains('previousResponseId'),
          ),
        ),
      );

      await expectLater(
        model.doGenerate(
          GenerateTextRequest(
            prompt: [
              UserPromptMessage.text('hello'),
            ],
            callOptions: const CallOptions(
              providerOptions: OpenAIGenerateTextOptions(
                builtInTools: [
                  OpenAIWebSearchTool(),
                ],
              ),
            ),
          ),
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'message',
            contains('built-in tools'),
          ),
        ),
      );

      expect(sendCount, 0);
    });

    test(
        'chat completions replay drops provider-native approval continuation with warnings',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_approval_1',
                'model': 'gpt-4.1-mini',
                'created': 1710000100,
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'stop',
                    'message': {
                      'role': 'assistant',
                      'content': 'Fallback answer.',
                    },
                  },
                ],
                'usage': {
                  'prompt_tokens': 4,
                  'completion_tokens': 2,
                  'total_tokens': 6,
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      final result = await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Continue after approval.'),
            AssistantPromptMessage(
              parts: const [
                ToolCallPromptPart(
                  toolCallId: 'approval-1',
                  toolName: 'mcp.create_short_url',
                  input: {
                    'url': 'https://ai-sdk.dev',
                  },
                  providerExecuted: true,
                  isDynamic: true,
                ),
                ToolApprovalRequestPromptPart(
                  approvalId: 'approval-1',
                  toolCallId: 'approval-1',
                ),
              ],
            ),
            ToolPromptMessage(
              toolName: 'mcp.create_short_url',
              parts: [
                const ToolApprovalResponsePromptPart(
                  approvalId: 'approval-1',
                  toolCallId: 'approval-1',
                  approved: true,
                  reason: 'User approved the MCP action.',
                ),
                ToolResultPromptPart(
                  toolCallId: 'approval-1',
                  toolName: 'mcp.create_short_url',
                  output: {
                    'shortUrl': 'https://zip1.dev/abc123',
                  },
                ),
              ],
            ),
          ],
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['messages'],
        [
          {
            'role': 'user',
            'content': 'Continue after approval.',
          },
        ],
      );

      expect(result.text, 'Fallback answer.');
      expect(
        result.warnings.map((warning) => warning.message),
        containsAll([
          'Chat-completions replay drops provider-executed or dynamic assistant tool calls.',
          'Chat-completions replay does not support tool approval responses.',
          'Chat-completions replay drops provider-native MCP tool results.',
        ]),
      );
      expect(
        result.warnings
            .where((warning) => warning.field == 'prompt.assistant.parts'),
        isNotEmpty,
      );
      expect(
        result.warnings
            .where((warning) => warning.field == 'prompt.tool.parts'),
        isNotEmpty,
      );
    });

    test(
        'chat completions replay keeps assistant text and common tool calls while warning-dropping unsupported assistant parts',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_assistant_replay_1',
                'model': 'gpt-4.1-mini',
                'created': 1710000101,
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'stop',
                    'message': {
                      'role': 'assistant',
                      'content': 'Replay accepted.',
                    },
                  },
                ],
                'usage': {
                  'prompt_tokens': 4,
                  'completion_tokens': 2,
                  'total_tokens': 6,
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      final result = await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Continue the conversation.'),
            AssistantPromptMessage(
              parts: const [
                TextPromptPart('I will continue.'),
                ToolCallPromptPart(
                  toolCallId: 'call_1',
                  toolName: 'weather',
                  input: {
                    'city': 'Hong Kong',
                  },
                ),
                ReasoningPromptPart('private reasoning'),
                CustomPromptPart(
                  kind: 'openai.custom_note',
                  data: {'state': 'hidden'},
                ),
                ImagePromptPart(
                  mediaType: 'image/png',
                  data: FileBytesData.constBytes([0, 1, 2, 3]),
                ),
                FilePromptPart(
                  mediaType: 'application/pdf',
                  data: FileBytesData.constBytes([1, 2, 3, 4]),
                ),
              ],
            ),
          ],
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['messages'],
        [
          {
            'role': 'user',
            'content': 'Continue the conversation.',
          },
          {
            'role': 'assistant',
            'content': 'I will continue.',
            'tool_calls': [
              {
                'id': 'call_1',
                'type': 'function',
                'function': {
                  'name': 'weather',
                  'arguments': '{"city":"Hong Kong"}',
                },
              },
            ],
          },
        ],
      );

      expect(result.text, 'Replay accepted.');
      expect(
        result.warnings.map((warning) => warning.message),
        containsAll([
          'Chat-completions replay dropped unsupported assistant part: ReasoningPromptPart.',
          'Chat-completions replay dropped unsupported assistant part: CustomPromptPart.',
          'Chat-completions replay dropped unsupported assistant part: ImagePromptPart.',
          'Chat-completions replay dropped unsupported assistant part: FilePromptPart.',
        ]),
      );
    });

    test(
        'chat completions replay keeps assistant tool-only turns with empty content and encodes common tool results',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_tool_only_replay_1',
                'model': 'gpt-4.1-mini',
                'created': 1710000102,
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'stop',
                    'message': {
                      'role': 'assistant',
                      'content': 'Replay accepted.',
                    },
                  },
                ],
                'usage': {
                  'prompt_tokens': 5,
                  'completion_tokens': 2,
                  'total_tokens': 7,
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      final result = await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Continue after the tool call.'),
            AssistantPromptMessage(
              parts: [
                ToolCallPromptPart(
                  toolCallId: 'call_1',
                  toolName: 'weather',
                  input: {
                    'city': 'Hong Kong',
                  },
                ),
              ],
            ),
            ToolPromptMessage(
              toolName: 'weather',
              parts: [
                ToolResultPromptPart(
                  toolCallId: 'call_1',
                  toolName: 'weather',
                  output: {
                    'temperatureC': 26,
                    'condition': 'Cloudy',
                  },
                ),
              ],
            ),
          ],
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['messages'],
        [
          {
            'role': 'user',
            'content': 'Continue after the tool call.',
          },
          {
            'role': 'assistant',
            'content': '',
            'tool_calls': [
              {
                'id': 'call_1',
                'type': 'function',
                'function': {
                  'name': 'weather',
                  'arguments': '{"city":"Hong Kong"}',
                },
              },
            ],
          },
          {
            'role': 'tool',
            'tool_call_id': 'call_1',
            'content': '{"temperatureC":26,"condition":"Cloudy"}',
          },
        ],
      );
      expect(result.text, 'Replay accepted.');
      expect(result.warnings, isEmpty);
    });

    test('chat completions replay stringifies structured common tool results',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_structured_tool_replay_1',
                'model': 'gpt-4.1-mini',
                'created': 1710000104,
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'stop',
                    'message': {
                      'role': 'assistant',
                      'content': 'Replay accepted.',
                    },
                  },
                ],
                'usage': {
                  'prompt_tokens': 5,
                  'completion_tokens': 2,
                  'total_tokens': 7,
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      final result = await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Continue after the tool call.'),
            AssistantPromptMessage(
              parts: [
                ToolCallPromptPart(
                  toolCallId: 'call_1',
                  toolName: 'weather',
                  input: {
                    'city': 'Hong Kong',
                  },
                ),
              ],
            ),
            ToolPromptMessage(
              toolName: 'weather',
              parts: [
                ToolResultPromptPart(
                  toolCallId: 'call_1',
                  toolName: 'weather',
                  toolOutput: ContentToolOutput(
                    parts: [
                      const TextToolOutputContentPart('forecast'),
                      const JsonToolOutputContentPart({
                        'summary': 'ok',
                      }),
                      const FileToolOutputContentPart(
                        mediaType: 'text/plain',
                        filename: 'notes.txt',
                        data: FileTextData('hello'),
                      ),
                      const CustomToolOutputContentPart(
                        kind: 'demo.custom',
                        data: {
                          'flag': true,
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['messages'],
        [
          {
            'role': 'user',
            'content': 'Continue after the tool call.',
          },
          {
            'role': 'assistant',
            'content': '',
            'tool_calls': [
              {
                'id': 'call_1',
                'type': 'function',
                'function': {
                  'name': 'weather',
                  'arguments': '{"city":"Hong Kong"}',
                },
              },
            ],
          },
          {
            'role': 'tool',
            'tool_call_id': 'call_1',
            'content':
                '[{"type":"text","text":"forecast"},{"type":"json","value":{"summary":"ok"}},{"type":"file","mediaType":"text/plain","filename":"notes.txt","data":{"type":"text","text":"hello"}},{"type":"custom","kind":"demo.custom","data":{"flag":true}}]',
          },
        ],
      );
      expect(result.text, 'Replay accepted.');
      expect(result.warnings, isEmpty);
    });

    test(
        'chat completions replay encodes failed common tool results as fallback text',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_tool_error_replay_1',
                'model': 'gpt-4.1-mini',
                'created': 1710000103,
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'stop',
                    'message': {
                      'role': 'assistant',
                      'content': 'Handled the failure.',
                    },
                  },
                ],
                'usage': {
                  'prompt_tokens': 5,
                  'completion_tokens': 2,
                  'total_tokens': 7,
                },
              },
            );
          },
        ),
      ).chatModel(
        'gpt-4.1-mini',
        settings: const OpenAIChatModelSettings(
          useResponsesApi: false,
        ),
      );

      final result = await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Continue after the failed tool call.'),
            AssistantPromptMessage(
              parts: [
                ToolCallPromptPart(
                  toolCallId: 'call_1',
                  toolName: 'weather',
                  input: {
                    'city': 'Hong Kong',
                  },
                ),
              ],
            ),
            ToolPromptMessage(
              toolName: 'weather',
              parts: [
                ToolResultPromptPart(
                  toolCallId: 'call_1',
                  toolName: 'weather',
                  output: null,
                  isError: true,
                ),
              ],
            ),
          ],
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['messages'],
        [
          {
            'role': 'user',
            'content': 'Continue after the failed tool call.',
          },
          {
            'role': 'assistant',
            'content': '',
            'tool_calls': [
              {
                'id': 'call_1',
                'type': 'function',
                'function': {
                  'name': 'weather',
                  'arguments': '{"city":"Hong Kong"}',
                },
              },
            ],
          },
          {
            'role': 'tool',
            'tool_call_id': 'call_1',
            'content': 'Tool execution failed',
          },
        ],
      );
      expect(result.text, 'Handled the failure.');
      expect(result.warnings, isEmpty);
    });

    test(
        'xAI chat completions encode typed live-search options and decode citations',
        () async {
      TransportRequest? capturedRequest;

      final model = OpenAI(
        apiKey: 'test-key',
        profile: const XAIProfile(),
        transport: _FakeTransportClient(
          onSend: (request) async {
            capturedRequest = request;
            return TransportResponse(
              statusCode: 200,
              body: {
                'id': 'chatcmpl_xai_1',
                'model': 'grok-3',
                'created': 1710000200,
                'citations': [
                  'https://example.com/news',
                  'https://x.ai/blog',
                ],
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'stop',
                    'message': {
                      'role': 'assistant',
                      'content': 'Here is the summary.',
                    },
                  },
                ],
                'usage': {
                  'prompt_tokens': 9,
                  'completion_tokens': 6,
                  'total_tokens': 15,
                  'completion_tokens_details': {
                    'reasoning_tokens': 0,
                  },
                },
              },
            );
          },
        ),
      ).chatModel('grok-3');

      final result = await model.doGenerate(
        GenerateTextRequest(
          prompt: [
            UserPromptMessage.text('Search the latest xAI news.'),
          ],
          callOptions: CallOptions(
            providerOptions: XAIGenerateTextOptions(
              search: XAILiveSearchOptions(
                mode: XAISearchMode.on,
                maxSearchResults: 7,
                fromDate: DateTime.utc(2026, 3, 1),
                toDate: DateTime.utc(2026, 3, 30),
                sources: const [
                  XAIWebSearchSource(
                    countryCode: 'US',
                    excludedWebsites: ['spam.example'],
                  ),
                  XAINewsSearchSource(countryCode: 'US'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(capturedRequest, isNotNull);
      final requestBody = capturedRequest!.body as Map<String, Object?>;
      expect(
        requestBody['search_parameters'],
        {
          'mode': 'on',
          'return_citations': true,
          'from_date': '2026-03-01',
          'to_date': '2026-03-30',
          'max_search_results': 7,
          'sources': [
            {
              'type': 'web',
              'country': 'US',
              'excluded_websites': ['spam.example'],
            },
            {
              'type': 'news',
              'country': 'US',
            },
          ],
        },
      );

      final sources = result.content.whereType<SourceContentPart>().toList();
      expect(sources, hasLength(2));
      expect(sources[0].source.sourceId, 'https://example.com/news');
      expect(sources[0].source.kind, SourceReferenceKind.url);
      expect(
        sources[0].source.providerMetadata?['xai'],
        containsPair('citationIndex', 0),
      );
      expect(sources[1].source.sourceId, 'https://x.ai/blog');
      expect(result.text, 'Here is the summary.');
    });

    test('xAI chat completions stream emits source events from citations',
        () async {
      final model = OpenAI(
        apiKey: 'test-key',
        profile: const XAIProfile(),
        transport: _FakeTransportClient(
          onSendStream: (request) async {
            expect(request.uri.toString(), contains('/chat/completions'));

            return StreamingTransportResponse(
              statusCode: 200,
              stream: Stream.fromIterable([
                utf8.encode(
                  'data: {"id":"chatcmpl_xai_stream_1","object":"chat.completion.chunk","created":1710000200,"model":"grok-3","choices":[{"index":0,"delta":{"content":"Latest summary"},"finish_reason":null}]}\n\n',
                ),
                utf8.encode(
                  'data: {"id":"chatcmpl_xai_stream_1","object":"chat.completion.chunk","created":1710000200,"model":"grok-3","citations":["https://example.com/news"],"choices":[{"index":0,"delta":{},"finish_reason":"stop"}],"usage":{"prompt_tokens":4,"completion_tokens":3,"total_tokens":7,"completion_tokens_details":{"reasoning_tokens":0}}}\n\n',
                ),
                utf8.encode('data: [DONE]\n\n'),
              ]),
            );
          },
        ),
      ).chatModel('grok-3');

      final events = await model
          .doStream(
            GenerateTextRequest(
              prompt: [
                UserPromptMessage.text('Search the latest news.'),
              ],
              callOptions: const CallOptions(
                providerOptions: XAIGenerateTextOptions(
                  search: XAILiveSearchOptions.autoWeb(),
                ),
              ),
            ),
          )
          .toList();

      final sourceEvent = events.whereType<SourceEvent>().single;
      expect(sourceEvent.source.sourceId, 'https://example.com/news');
      expect(sourceEvent.source.kind, SourceReferenceKind.url);
      expect(
        sourceEvent.source.providerMetadata?['xai'],
        allOf(
          containsPair('responseId', 'chatcmpl_xai_stream_1'),
          containsPair('citationIndex', 0),
        ),
      );

      final finish = events.whereType<FinishEvent>().single;
      expect(finish.finishReason, FinishReason.stop);
      expect(finish.usage?.totalTokens, 7);
    });

    test('xAI typed provider options are rejected on non-xAI profiles',
        () async {
      var sendCount = 0;

      final model = OpenAI(
        apiKey: 'test-key',
        profile: const OpenRouterProfile(),
        transport: _FakeTransportClient(
          onSend: (request) async {
            sendCount += 1;
            return TransportResponse(statusCode: 200, body: const {});
          },
        ),
      ).chatModel('openai/gpt-4o-mini');

      await expectLater(
        model.doGenerate(
          GenerateTextRequest(
            prompt: [
              UserPromptMessage.text('hello'),
            ],
            callOptions: const CallOptions(
              providerOptions: XAIGenerateTextOptions(
                search: XAILiveSearchOptions.autoWeb(),
              ),
            ),
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('only valid for xAI'),
          ),
        ),
      );

      expect(sendCount, 0);
    });

    test(
        'DeepSeek typed provider options are rejected on non-DeepSeek profiles',
        () async {
      var sendCount = 0;

      final model = OpenAI(
        apiKey: 'test-key',
        profile: const OpenRouterProfile(),
        transport: _FakeTransportClient(
          onSend: (request) async {
            sendCount += 1;
            return TransportResponse(statusCode: 200, body: const {});
          },
        ),
      ).chatModel('openai/gpt-4o-mini');

      await expectLater(
        model.doGenerate(
          GenerateTextRequest(
            prompt: [
              UserPromptMessage.text('hello'),
            ],
            callOptions: const CallOptions(
              providerOptions: DeepSeekGenerateTextOptions(
                responseFormat: {'type': 'json_object'},
              ),
            ),
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('only valid for DeepSeek'),
          ),
        ),
      );

      expect(sendCount, 0);
    });
  });
}

typedef _FakeTransportClient = FakeTransportClient;
