import 'dart:convert';
import 'dart:io';

import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_openai/src/openai_chat_completions_codec.dart';
import 'package:llm_dart_openai/src/openai_responses_codec.dart';
import 'package:llm_dart_openai/src/resolved_openai_options.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI fixture contracts', () {
    test('Responses request body matches golden fixture', () {
      const codec = OpenAIResponsesCodec();

      final request = codec.encodeRequest(
        modelId: 'gpt-5-mini',
        prompt: [
          UserPromptMessage(
            parts: [
              const TextPromptPart('Summarize the attached inputs.'),
              const ImagePromptPart(
                mediaType: 'image/png',
                data: FileProviderReferenceData(
                  ProviderReference({'openai': 'file-img-123'}),
                ),
                providerOptions: OpenAIPromptPartOptions(
                  imageDetail: 'high',
                ),
              ),
              FilePromptPart(
                mediaType: 'application/pdf',
                data: FileUrlData(
                  Uri.parse('https://example.com/report.pdf'),
                ),
              ),
            ],
          ),
          AssistantPromptMessage(
            parts: const [
              TextPromptPart(
                'Earlier answer.',
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'itemId': 'msg_prev',
                      'phase': 'final_answer',
                    },
                  }),
                ),
              ),
              ReasoningPromptPart(
                'Prior reasoning.',
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'itemId': 'rs_prev',
                      'reasoningEncryptedContent': 'enc_reason',
                    },
                  }),
                ),
              ),
              ToolCallPromptPart(
                toolCallId: 'call_weather',
                toolName: 'weather',
                input: {
                  'city': 'Hong Kong',
                },
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'itemId': 'fc_weather',
                    },
                  }),
                ),
              ),
              CustomPromptPart(
                kind: 'openai.compaction',
                data: {
                  'encryptedContent': 'enc_compaction',
                  'compact_threshold': 50000,
                },
                providerOptions: ProviderReplayPromptPartOptions(
                  ProviderMetadata({
                    'openai': {
                      'itemId': 'cmp_prev',
                    },
                  }),
                ),
              ),
            ],
          ),
          ToolPromptMessage(
            toolName: 'mcp.create_short_url',
            parts: const [
              ToolApprovalResponsePromptPart(
                approvalId: 'approval-1',
                toolCallId: 'approval-1',
                approved: true,
              ),
            ],
          ),
        ],
        tools: [
          FunctionToolDefinition(
            name: 'weather',
            description: 'Get current weather.',
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
        options: const GenerateTextOptions(
          maxOutputTokens: 128,
          reasoning: GenerateTextReasoningOptions(
            effort: ReasoningEffort.high,
          ),
        ),
        providerOptions: OpenAIGenerateTextOptions(
          store: false,
          builtInTools: [
            OpenAIBuiltInTools.mcp(
              serverLabel: 'zip1',
              serverUrl: Uri.parse('https://mcp.example.com'),
              allowedTools: const OpenAIMcpAllowedTools.filter(
                readOnly: true,
              ),
            ),
          ],
          responseFormat: const OpenAIJsonSchemaResponseFormat(
            name: 'summary',
            schema: {
              'type': 'object',
              'properties': {
                'summary': {'type': 'string'},
              },
            },
            strict: true,
          ),
          logprobs: const OpenAILogProbs.enabled(),
          serviceTier: 'priority',
          metadata: const {
            'suite': 'fixture-contract',
          },
        ),
        stream: false,
      );

      expect(request.warnings, isEmpty);
      expectJsonFixture(
        'openai/responses_request_body_golden.json',
        request.body,
      );
    });

    test('Chat Completions request body matches golden fixture', () {
      const codec = OpenAIChatCompletionsCodec();

      final request = codec.encodeRequest(
        modelId: 'gpt-4.1-mini',
        prompt: [
          SystemPromptMessage.text('Be precise.'),
          UserPromptMessage(
            parts: const [
              TextPromptPart('Use the weather tool.'),
              ImagePromptPart(
                mediaType: 'image/*',
                data: FileBytesData.constBytes([0, 1, 2, 3]),
                providerOptions: OpenAIPromptPartOptions(
                  imageDetail: 'low',
                ),
              ),
              FilePromptPart(
                mediaType: 'application/pdf',
                filename: 'brief.pdf',
                data: FileBytesData.constBytes([1, 2, 3, 4]),
              ),
            ],
          ),
          AssistantPromptMessage(
            parts: const [
              ToolCallPromptPart(
                toolCallId: 'call_weather',
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
                toolCallId: 'call_weather',
                toolName: 'weather',
                toolOutput: ContentToolOutput(
                  parts: const [
                    TextToolOutputContentPart('forecast'),
                    JsonToolOutputContentPart({
                      'condition': 'Cloudy',
                      'temperatureC': 26,
                    }),
                  ],
                ),
              ),
            ],
          ),
        ],
        tools: [
          FunctionToolDefinition(
            name: 'weather',
            description: 'Get current weather.',
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
        options: const GenerateTextOptions(
          maxOutputTokens: 96,
          temperature: 0.3,
          presencePenalty: 0.1,
          frequencyPenalty: 0.2,
          seed: 1234,
        ),
        providerOptions: const ResolvedOpenAIGenerateTextOptions(
          common: OpenAIGenerateTextOptions(
            parallelToolCalls: true,
            serviceTier: 'priority',
            verbosity: 'low',
            user: 'user_123',
            responseFormat: OpenAIJsonSchemaResponseFormat(
              name: 'weather_answer',
              schema: {
                'type': 'object',
                'properties': {
                  'answer': {'type': 'string'},
                },
              },
              strict: true,
            ),
          ),
        ),
        stream: false,
      );

      expect(request.warnings, isEmpty);
      expectJsonFixture(
        'openai/chat_completions_request_body_golden.json',
        request.body,
      );
    });

    test('Responses stream events match golden fixture', () {
      const codec = OpenAIResponsesCodec();
      final state = OpenAIResponsesStreamState();
      final events = <LanguageModelStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'type': 'response.created',
          'response': {
            'id': 'resp_fixture',
            'model': 'gpt-4.1-mini',
            'created_at': 1710000000,
            'service_tier': 'default',
          },
        },
        {
          'type': 'response.reasoning_summary_part.added',
          'item_id': 'rs_1',
          'output_index': 0,
          'summary_index': 0,
        },
        {
          'type': 'response.reasoning_summary_text.delta',
          'item_id': 'rs_1',
          'output_index': 0,
          'summary_index': 0,
          'delta': 'Plan',
        },
        {
          'type': 'response.output_item.added',
          'output_index': 1,
          'item': {
            'id': 'msg_1',
            'type': 'message',
            'status': 'in_progress',
          },
        },
        {
          'type': 'response.output_text.delta',
          'item_id': 'msg_1',
          'output_index': 1,
          'content_index': 0,
          'delta': 'Hello',
        },
        {
          'type': 'response.output_item.added',
          'output_index': 2,
          'item': {
            'id': 'fc_1',
            'type': 'function_call',
            'call_id': 'call_weather',
            'name': 'weather',
            'arguments': '',
            'status': 'in_progress',
          },
        },
        {
          'type': 'response.function_call_arguments.delta',
          'output_index': 2,
          'delta': '{"city":"Hong Kong"}',
        },
        {
          'type': 'response.output_item.done',
          'output_index': 2,
          'item': {
            'id': 'fc_1',
            'type': 'function_call',
            'call_id': 'call_weather',
            'name': 'weather',
            'arguments': '{"city":"Hong Kong"}',
            'status': 'completed',
          },
        },
        {
          'type': 'response.output_text.annotation.added',
          'item_id': 'msg_1',
          'output_index': 1,
          'content_index': 0,
          'annotation_index': 0,
          'annotation': {
            'type': 'url_citation',
            'url': 'https://example.com',
            'title': 'Example URL',
            'start_index': 0,
            'end_index': 5,
          },
        },
        {
          'type': 'response.output_item.done',
          'output_index': 3,
          'item': {
            'id': 'approval-1',
            'type': 'mcp_approval_request',
            'name': 'create_short_url',
            'arguments': '{"url":"https://ai-sdk.dev"}',
            'server_label': 'zip1',
          },
        },
        {
          'type': 'response.output_item.done',
          'output_index': 4,
          'item': {
            'id': 'mcp-call-1',
            'type': 'mcp_call',
            'approval_request_id': 'approval-1',
            'name': 'create_short_url',
            'arguments': '{"url":"https://ai-sdk.dev"}',
            'server_label': 'zip1',
            'output': {
              'shortUrl': 'https://zip1.dev/abc123',
            },
          },
        },
        {
          'type': 'response.output_item.done',
          'output_index': 5,
          'item': {
            'id': 'ws_1',
            'type': 'web_search_call',
            'status': 'completed',
            'action': {
              'type': 'search',
              'query': 'hello',
            },
          },
        },
        {
          'type': 'response.completed',
          'response': {
            'id': 'resp_fixture',
            'model': 'gpt-4.1-mini',
            'created_at': 1710000000,
            'status': 'completed',
            'service_tier': 'default',
            'usage': {
              'input_tokens': 10,
              'output_tokens': 8,
              'total_tokens': 18,
              'output_tokens_details': {
                'reasoning_tokens': 3,
              },
            },
          },
        },
      ]) {
        events.addAll(codec.decodeStreamChunk(chunk, state));
      }

      expectJsonFixture(
        'openai/responses_stream_events_golden.json',
        const LanguageModelStreamEventJsonCodec().encodeEvents(events),
      );
    });

    test('Chat Completions stream events match golden fixture', () {
      const codec = OpenAIChatCompletionsCodec(providerNamespace: 'xai');
      final state = OpenAIChatCompletionsStreamState();
      final events = <LanguageModelStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'id': 'chatcmpl_fixture',
          'object': 'chat.completion.chunk',
          'created': 1710000200,
          'model': 'grok-3',
          'choices': [
            {
              'index': 0,
              'delta': {
                'role': 'assistant',
                'reasoning_content': 'Plan',
              },
              'finish_reason': null,
            },
          ],
        },
        {
          'id': 'chatcmpl_fixture',
          'object': 'chat.completion.chunk',
          'created': 1710000200,
          'model': 'grok-3',
          'choices': [
            {
              'index': 0,
              'delta': {
                'content': 'Hello',
              },
              'finish_reason': null,
            },
          ],
        },
        {
          'id': 'chatcmpl_fixture',
          'object': 'chat.completion.chunk',
          'created': 1710000200,
          'model': 'grok-3',
          'choices': [
            {
              'index': 0,
              'delta': {
                'tool_calls': [
                  {
                    'index': 0,
                    'id': 'call_weather',
                    'type': 'function',
                    'function': {
                      'name': 'weather',
                      'arguments': '{"city":"Hong',
                    },
                  },
                ],
              },
              'finish_reason': null,
            },
          ],
        },
        {
          'id': 'chatcmpl_fixture',
          'object': 'chat.completion.chunk',
          'created': 1710000200,
          'model': 'grok-3',
          'citations': [
            'https://example.com/news',
          ],
          'choices': [
            {
              'index': 0,
              'delta': {
                'tool_calls': [
                  {
                    'index': 0,
                    'function': {
                      'arguments': ' Kong"}',
                    },
                  },
                ],
              },
              'finish_reason': null,
            },
          ],
        },
        {
          'id': 'chatcmpl_fixture',
          'object': 'chat.completion.chunk',
          'created': 1710000200,
          'model': 'grok-3',
          'system_fingerprint': 'fp_fixture',
          'choices': [
            {
              'index': 0,
              'delta': const {},
              'finish_reason': 'tool_calls',
            },
          ],
          'usage': {
            'prompt_tokens': 12,
            'completion_tokens': 8,
            'total_tokens': 20,
            'completion_tokens_details': {
              'reasoning_tokens': 2,
            },
          },
        },
      ]) {
        events.addAll(codec.decodeStreamChunk(chunk, state));
      }

      expectJsonFixture(
        'openai/chat_completions_stream_events_golden.json',
        const LanguageModelStreamEventJsonCodec().encodeEvents(events),
      );
    });
  });
}

void expectJsonFixture(String relativePath, Object? actual) {
  final fixture = readJsonFixture(relativePath);
  expect(actual, fixture);
}

Object? readJsonFixture(String relativePath) {
  for (final basePath in const [
    'packages/llm_dart_openai/test/fixtures',
    'test/fixtures',
  ]) {
    final file = File('$basePath/$relativePath');
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Object?;
    }
  }

  throw FileSystemException('Fixture not found.', relativePath);
}
