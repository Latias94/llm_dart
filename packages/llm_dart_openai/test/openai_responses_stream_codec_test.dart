import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_openai/src/responses/openai_responses_codec.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIResponsesCodec stream decoding', () {
    test(
        'maps reasoning, text, function calls, sources, custom outputs, and finish events',
        () {
      const codec = OpenAIResponsesCodec();
      final state = OpenAIResponsesStreamState();
      final events = <LanguageModelStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'type': 'response.created',
          'response': {
            'id': 'resp_1',
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
          'type': 'response.reasoning_summary_part.done',
          'item_id': 'rs_1',
          'output_index': 0,
          'summary_index': 0,
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
          'type': 'response.output_text.done',
          'item_id': 'msg_1',
          'output_index': 1,
          'content_index': 0,
          'text': 'Hello',
        },
        {
          'type': 'response.output_item.added',
          'output_index': 2,
          'item': {
            'id': 'fc_1',
            'type': 'function_call',
            'call_id': 'call_1',
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
            'call_id': 'call_1',
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
            'id': 'resp_1',
            'model': 'gpt-4.1-mini',
            'created_at': 1710000000,
            'status': 'completed',
            'service_tier': 'default',
            'usage': {
              'input_tokens': 1,
              'output_tokens': 1,
              'total_tokens': 2,
              'output_tokens_details': {
                'reasoning_tokens': 0,
              },
            },
          },
        },
      ]) {
        events.addAll(codec.decodeStreamChunk(chunk, state));
      }

      final responseMetadata = events.whereType<ResponseMetadataEvent>().single;
      expect(responseMetadata.responseId, 'resp_1');
      expect(responseMetadata.modelId, 'gpt-4.1-mini');
      expect(
        responseMetadata.providerMetadata?.values['openai'],
        containsPair('serviceTier', 'default'),
      );

      expect(events.whereType<ReasoningStartEvent>().single.id, 'rs_1:0');
      expect(events.whereType<ReasoningDeltaEvent>().single.delta, 'Plan');
      expect(events.whereType<ReasoningEndEvent>().single.id, 'rs_1:0');

      expect(events.whereType<TextStartEvent>().single.id, 'msg_1');
      expect(events.whereType<TextDeltaEvent>().single.delta, 'Hello');
      expect(events.whereType<TextEndEvent>().single.id, 'msg_1');

      final toolInputStart =
          events.whereType<ToolInputStartEvent>().singleWhere(
                (event) => event.toolName == 'weather',
              );
      expect(toolInputStart.toolCallId, 'call_1');
      expect(toolInputStart.toolName, 'weather');
      expect(events.whereType<ToolInputDeltaEvent>().single.delta,
          '{"city":"Hong Kong"}');
      expect(
        events
            .whereType<ToolInputEndEvent>()
            .singleWhere((event) => event.toolCallId == 'call_1')
            .toolCallId,
        'call_1',
      );

      final toolCall = events
          .whereType<ToolCallEvent>()
          .singleWhere((event) => event.toolCall.toolName == 'weather')
          .toolCall;
      expect(toolCall.toolCallId, 'call_1');
      expect(toolCall.toolName, 'weather');
      expect(
        toolCall.input,
        {
          'city': 'Hong Kong',
        },
      );

      final source = events.whereType<SourceEvent>().single.source;
      expect(source.kind, SourceReferenceKind.url);
      expect(source.sourceId, 'https://example.com');
      expect(source.uri, Uri.parse('https://example.com'));
      expect(source.title, 'Example URL');

      final webSearchCall = events
          .whereType<ToolCallEvent>()
          .singleWhere((event) => event.toolCall.toolName == 'web_search')
          .toolCall;
      expect(webSearchCall.toolCallId, 'ws_1');
      expect(webSearchCall.providerExecuted, isTrue);
      expect(webSearchCall.input, isEmpty);

      final webSearchResult = events.whereType<ToolResultEvent>().single;
      expect(webSearchResult.toolResult.toolCallId, 'ws_1');
      expect(webSearchResult.toolResult.toolName, 'web_search');
      expect(webSearchResult.toolResult.output, {
        'action': {
          'type': 'search',
          'query': 'hello',
        },
      });
      expect(events.whereType<CustomEvent>(), isEmpty);

      final finish = events.whereType<FinishEvent>().single;
      expect(finish.finishReason, FinishReason.toolCalls);
      expect(finish.rawFinishReason, isNull);
      expect(finish.usage?.totalTokens, 2);
      expect(
        finish.providerMetadata?.values['openai'],
        allOf(
          containsPair('status', 'completed'),
          containsPair('serviceTier', 'default'),
        ),
      );
    });

    test('maps approval requests and provider-executed MCP results', () {
      const codec = OpenAIResponsesCodec();
      final state = OpenAIResponsesStreamState();
      final events = <LanguageModelStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'type': 'response.created',
          'response': {
            'id': 'resp_mcp',
            'model': 'gpt-4.1-mini',
            'created_at': 1710000000,
          },
        },
        {
          'type': 'response.output_item.done',
          'output_index': 0,
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
          'output_index': 1,
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
          'type': 'response.completed',
          'response': {
            'id': 'resp_mcp',
            'model': 'gpt-4.1-mini',
            'created_at': 1710000000,
            'status': 'completed',
            'usage': {
              'input_tokens': 1,
              'output_tokens': 1,
              'total_tokens': 2,
              'output_tokens_details': {
                'reasoning_tokens': 0,
              },
            },
          },
        },
      ]) {
        events.addAll(codec.decodeStreamChunk(chunk, state));
      }

      final toolCalls = events.whereType<ToolCallEvent>().toList();
      expect(toolCalls, hasLength(2));
      expect(toolCalls[0].toolCall.toolCallId, 'approval-1');
      expect(toolCalls[0].toolCall.toolName, 'mcp.create_short_url');
      expect(toolCalls[0].toolCall.providerExecuted, isTrue);
      expect(toolCalls[0].toolCall.isDynamic, isTrue);
      expect(toolCalls[0].toolCall.title, 'zip1');

      final approval = events.whereType<ToolApprovalRequestEvent>().single;
      expect(approval.approvalId, 'approval-1');
      expect(approval.toolCallId, 'approval-1');

      final toolResult = events.whereType<ToolResultEvent>().single.toolResult;
      expect(toolResult.toolCallId, 'approval-1');
      expect(toolResult.toolName, 'mcp.create_short_url');
      expect(toolResult.isDynamic, isTrue);
      expect(toolResult.isError, isFalse);
      expect(toolResult.toolOutput, isA<JsonToolOutput>());
      expect(
        (toolResult.output as Map<String, Object?>)['type'],
        'mcp_call',
      );
      expect(
        ((toolResult.output as Map<String, Object?>)['output']
            as Map<String, Object?>)['shortUrl'],
        'https://zip1.dev/abc123',
      );

      final finish = events.whereType<FinishEvent>().single;
      expect(finish.finishReason, FinishReason.toolCalls);
      expect(finish.usage?.totalTokens, 2);
    });

    test('maps malformed function-call arguments to tool input errors', () {
      const codec = OpenAIResponsesCodec();
      final state = OpenAIResponsesStreamState();
      final events = <LanguageModelStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'type': 'response.output_item.added',
          'output_index': 0,
          'item': {
            'id': 'fc_1',
            'type': 'function_call',
            'call_id': 'call_1',
            'name': 'weather',
            'arguments': '',
            'status': 'in_progress',
          },
        },
        {
          'type': 'response.function_call_arguments.delta',
          'output_index': 0,
          'delta': '{"city":',
        },
        {
          'type': 'response.output_item.done',
          'output_index': 0,
          'item': {
            'id': 'fc_1',
            'type': 'function_call',
            'call_id': 'call_1',
            'name': 'weather',
            'arguments': '{"city":',
            'status': 'completed',
          },
        },
        {
          'type': 'response.completed',
          'response': {
            'id': 'resp_invalid_tool',
            'model': 'gpt-4.1-mini',
            'created_at': 1710000000,
            'status': 'completed',
            'usage': {
              'input_tokens': 1,
              'output_tokens': 1,
              'total_tokens': 2,
            },
          },
        },
      ]) {
        events.addAll(codec.decodeStreamChunk(chunk, state));
      }

      expect(
          events.whereType<ToolInputStartEvent>().single.toolCallId, 'call_1');
      expect(events.whereType<ToolInputDeltaEvent>().single.delta, '{"city":');
      expect(events.whereType<ToolInputEndEvent>(), isEmpty);
      expect(events.whereType<ToolCallEvent>(), isEmpty);

      final toolInputError = events.whereType<ToolInputErrorEvent>().single;
      expect(toolInputError.toolCallId, 'call_1');
      expect(toolInputError.toolName, 'weather');
      expect(toolInputError.input, '{"city":');
      expect(
        toolInputError.errorText,
        contains('Invalid JSON tool arguments for "weather"'),
      );

      final finish = events.whereType<FinishEvent>().single;
      expect(finish.finishReason, FinishReason.toolCalls);
    });

    test('maps failed responses to metadata, error, and finish events', () {
      const codec = OpenAIResponsesCodec();
      final state = OpenAIResponsesStreamState();

      final events = codec.decodeStreamChunk(
        {
          'type': 'response.failed',
          'response': {
            'id': 'resp_failed',
            'model': 'gpt-4.1-mini',
            'created_at': 1710000200,
            'status': 'failed',
            'error': {
              'type': 'server_error',
              'message': 'upstream failed',
            },
            'usage': {
              'input_tokens': 2,
              'output_tokens': 0,
              'total_tokens': 2,
              'output_tokens_details': {
                'reasoning_tokens': 0,
              },
            },
          },
        },
        state,
      ).toList();

      final responseMetadata = events.whereType<ResponseMetadataEvent>().single;
      expect(responseMetadata.responseId, 'resp_failed');
      expect(responseMetadata.modelId, 'gpt-4.1-mini');

      final errorEvent = events.whereType<ErrorEvent>().single;
      expect(errorEvent.error.kind, ModelErrorKind.provider);
      expect(errorEvent.error.code, 'server_error');
      expect(errorEvent.error.message, 'upstream failed');

      final finish = events.whereType<FinishEvent>().single;
      expect(finish.finishReason, FinishReason.error);
      expect(finish.usage?.totalTokens, 2);
      expect(
        finish.providerMetadata?.values['openai'],
        containsPair('status', 'failed'),
      );
    });

    test('maps image generation partial images to preliminary tool results',
        () {
      const codec = OpenAIResponsesCodec();
      final state = OpenAIResponsesStreamState()
        ..responseId = 'resp_img'
        ..serviceTier = 'default';

      final events = codec.decodeStreamChunk(
        {
          'type': 'response.image_generation_call.partial_image',
          'item_id': 'img_1',
          'output_index': 1,
          'partial_image_b64': 'AQID',
        },
        state,
      ).toList();

      final result = events.whereType<ToolResultEvent>().single;
      expect(result.toolResult.toolCallId, 'img_1');
      expect(result.toolResult.toolName, 'image_generation');
      expect(result.toolResult.preliminary, isTrue);
      expect(
        result.toolResult.output,
        {
          'result': 'AQID',
        },
      );
      expect(
        result.providerMetadata?.namespace('openai'),
        allOf(
          containsPair('responseId', 'resp_img'),
          containsPair('itemId', 'img_1'),
          containsPair('itemType', 'image_generation_call.partial_image'),
          containsPair('outputIndex', 1),
          containsPair('serviceTier', 'default'),
        ),
      );
    });

    test('maps image generation output items to provider-executed tool events',
        () {
      const codec = OpenAIResponsesCodec();
      final state = OpenAIResponsesStreamState()
        ..responseId = 'resp_img'
        ..serviceTier = 'default';
      final events = <LanguageModelStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'type': 'response.output_item.added',
          'output_index': 1,
          'item': {
            'id': 'img_1',
            'type': 'image_generation_call',
            'status': 'in_progress',
          },
        },
        {
          'type': 'response.output_item.done',
          'output_index': 1,
          'item': {
            'id': 'img_1',
            'type': 'image_generation_call',
            'status': 'completed',
            'result': 'AAEC',
          },
        },
      ]) {
        events.addAll(codec.decodeStreamChunk(chunk, state));
      }

      final toolCall = events.whereType<ToolCallEvent>().single.toolCall;
      expect(toolCall.toolCallId, 'img_1');
      expect(toolCall.toolName, 'image_generation');
      expect(toolCall.providerExecuted, isTrue);
      expect(toolCall.input, isEmpty);

      final toolResult = events.whereType<ToolResultEvent>().single.toolResult;
      expect(toolResult.toolCallId, 'img_1');
      expect(toolResult.toolName, 'image_generation');
      expect(toolResult.output, {
        'result': 'AAEC',
      });
    });

    test('maps code interpreter streams to provider-executed tool events', () {
      const codec = OpenAIResponsesCodec();
      final state = OpenAIResponsesStreamState()
        ..responseId = 'resp_ci'
        ..serviceTier = 'default';
      final events = <LanguageModelStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'type': 'response.output_item.added',
          'output_index': 1,
          'item': {
            'id': 'ci_1',
            'type': 'code_interpreter_call',
            'status': 'in_progress',
            'code': '',
            'container_id': 'cntr_1',
            'outputs': const [],
          },
        },
        {
          'type': 'response.code_interpreter_call_code.delta',
          'output_index': 1,
          'item_id': 'ci_1',
          'delta': 'print("hi")',
        },
        {
          'type': 'response.code_interpreter_call_code.done',
          'output_index': 1,
          'item_id': 'ci_1',
          'code': 'print("hi")',
        },
        {
          'type': 'response.output_item.done',
          'output_index': 1,
          'item': {
            'id': 'ci_1',
            'type': 'code_interpreter_call',
            'status': 'completed',
            'code': 'print("hi")',
            'container_id': 'cntr_1',
            'outputs': [
              {
                'type': 'logs',
                'logs': 'hi',
              },
            ],
          },
        },
      ]) {
        events.addAll(codec.decodeStreamChunk(chunk, state));
      }

      final start = events.whereType<ToolInputStartEvent>().single;
      expect(start.toolCallId, 'ci_1');
      expect(start.toolName, 'code_interpreter');
      expect(start.providerExecuted, isTrue);

      expect(
        events.whereType<ToolInputDeltaEvent>().map((event) => event.delta),
        [
          '{"containerId":"cntr_1","code":"',
          'print(\\"hi\\")',
          '"}',
        ],
      );
      expect(events.whereType<ToolInputEndEvent>().single.toolCallId, 'ci_1');

      final toolCall = events.whereType<ToolCallEvent>().single.toolCall;
      expect(toolCall.toolCallId, 'ci_1');
      expect(toolCall.toolName, 'code_interpreter');
      expect(toolCall.providerExecuted, isTrue);
      expect(toolCall.input, {
        'containerId': 'cntr_1',
        'code': 'print("hi")',
      });

      final toolResult = events.whereType<ToolResultEvent>().single.toolResult;
      expect(toolResult.toolCallId, 'ci_1');
      expect(toolResult.toolName, 'code_interpreter');
      expect(toolResult.output, {
        'outputs': [
          {
            'type': 'logs',
            'logs': 'hi',
          },
        ],
      });
    });

    test('maps file search streams to provider-executed tool events', () {
      const codec = OpenAIResponsesCodec();
      final state = OpenAIResponsesStreamState()
        ..responseId = 'resp_file_search'
        ..serviceTier = 'default';
      final events = <LanguageModelStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'type': 'response.output_item.added',
          'output_index': 1,
          'item': {
            'id': 'fs_1',
            'type': 'file_search_call',
            'status': 'in_progress',
            'queries': const [],
          },
        },
        {
          'type': 'response.output_item.done',
          'output_index': 1,
          'item': {
            'id': 'fs_1',
            'type': 'file_search_call',
            'status': 'completed',
            'queries': ['architecture notes'],
            'results': [
              {
                'attributes': {
                  'source': 'adr',
                },
                'file_id': 'file_1',
                'filename': 'ADR-001.md',
                'score': 0.91,
                'text': 'Provider-local projection keeps OpenAI details local.',
              },
            ],
          },
        },
      ]) {
        events.addAll(codec.decodeStreamChunk(chunk, state));
      }

      final toolCall = events.whereType<ToolCallEvent>().single.toolCall;
      expect(toolCall.toolCallId, 'fs_1');
      expect(toolCall.toolName, 'file_search');
      expect(toolCall.providerExecuted, isTrue);
      expect(toolCall.input, isEmpty);

      final toolResult = events.whereType<ToolResultEvent>().single.toolResult;
      expect(toolResult.toolCallId, 'fs_1');
      expect(toolResult.toolName, 'file_search');
      expect(toolResult.output, {
        'queries': ['architecture notes'],
        'results': [
          {
            'attributes': {
              'source': 'adr',
            },
            'fileId': 'file_1',
            'filename': 'ADR-001.md',
            'score': 0.91,
            'text': 'Provider-local projection keeps OpenAI details local.',
          },
        ],
      });
    });

    test('maps web search streams to provider-executed tool events', () {
      const codec = OpenAIResponsesCodec();
      final state = OpenAIResponsesStreamState()
        ..responseId = 'resp_web_search'
        ..serviceTier = 'default';
      final events = <LanguageModelStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'type': 'response.output_item.added',
          'output_index': 1,
          'item': {
            'id': 'ws_1',
            'type': 'web_search_call',
            'status': 'in_progress',
            'action': {
              'type': 'search',
              'query': 'Vercel AI SDK',
            },
          },
        },
        {
          'type': 'response.output_item.done',
          'output_index': 1,
          'item': {
            'id': 'ws_1',
            'type': 'web_search_call',
            'status': 'completed',
            'action': {
              'type': 'search',
              'query': 'Vercel AI SDK',
              'sources': [
                {
                  'type': 'url',
                  'url': 'https://ai-sdk.dev',
                },
                {
                  'type': 'api',
                  'name': 'oai-search',
                },
              ],
            },
          },
        },
      ]) {
        events.addAll(codec.decodeStreamChunk(chunk, state));
      }

      final inputStart = events.whereType<ToolInputStartEvent>().single;
      expect(inputStart.toolCallId, 'ws_1');
      expect(inputStart.toolName, 'web_search');
      expect(inputStart.providerExecuted, isTrue);
      expect(events.whereType<ToolInputEndEvent>().single.toolCallId, 'ws_1');

      final toolCall = events.whereType<ToolCallEvent>().single.toolCall;
      expect(toolCall.toolCallId, 'ws_1');
      expect(toolCall.toolName, 'web_search');
      expect(toolCall.providerExecuted, isTrue);
      expect(toolCall.input, isEmpty);

      final toolResult = events.whereType<ToolResultEvent>().single.toolResult;
      expect(toolResult.toolCallId, 'ws_1');
      expect(toolResult.toolName, 'web_search');
      expect(toolResult.output, {
        'action': {
          'type': 'search',
          'query': 'Vercel AI SDK',
        },
        'sources': [
          {
            'type': 'url',
            'url': 'https://ai-sdk.dev',
          },
          {
            'type': 'api',
            'name': 'oai-search',
          },
        ],
      });
    });

    test('maps tool search streams using the final call id', () {
      const codec = OpenAIResponsesCodec();
      final state = OpenAIResponsesStreamState()
        ..responseId = 'resp_tool_search'
        ..serviceTier = 'default';
      final events = <LanguageModelStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'type': 'response.output_item.added',
          'output_index': 0,
          'item': {
            'id': 'tsc_client_1',
            'type': 'tool_search_call',
            'execution': 'client',
            'call_id': 'call_provisional',
            'status': 'completed',
            'arguments': {
              'goal': 'Find the weather tool',
            },
          },
        },
        {
          'type': 'response.output_item.done',
          'output_index': 0,
          'item': {
            'id': 'tsc_client_1',
            'type': 'tool_search_call',
            'execution': 'client',
            'call_id': 'call_final',
            'status': 'completed',
            'arguments': {
              'goal': 'Find the weather tool',
            },
          },
        },
        {
          'type': 'response.output_item.done',
          'output_index': 1,
          'item': {
            'id': 'tso_client_1',
            'type': 'tool_search_output',
            'execution': 'client',
            'call_id': 'call_final',
            'status': 'completed',
            'tools': [
              {
                'type': 'function',
                'name': 'get_weather',
              },
            ],
          },
        },
      ]) {
        events.addAll(codec.decodeStreamChunk(chunk, state));
      }

      final start = events.whereType<ToolInputStartEvent>().single;
      expect(start.toolCallId, 'call_final');
      expect(start.toolName, 'tool_search');
      expect(start.providerExecuted, isFalse);
      expect(events.whereType<ToolInputDeltaEvent>(), isEmpty);
      expect(
        events.whereType<ToolInputEndEvent>().single.toolCallId,
        'call_final',
      );

      final toolCall = events.whereType<ToolCallEvent>().single.toolCall;
      expect(toolCall.toolCallId, 'call_final');
      expect(toolCall.toolName, 'tool_search');
      expect(toolCall.providerExecuted, isFalse);
      expect(toolCall.input, {
        'arguments': {
          'goal': 'Find the weather tool',
        },
        'call_id': 'call_final',
      });

      final toolResult = events.whereType<ToolResultEvent>().single.toolResult;
      expect(toolResult.toolCallId, 'call_final');
      expect(toolResult.toolName, 'tool_search');
      expect(toolResult.output, {
        'tools': [
          {
            'type': 'function',
            'name': 'get_weather',
          },
        ],
      });
    });

    test('maps shell and apply patch streams to native tool events', () {
      const codec = OpenAIResponsesCodec();
      final state = OpenAIResponsesStreamState()
        ..responseId = 'resp_shell'
        ..serviceTier = 'default';
      final events = <LanguageModelStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'type': 'response.output_item.done',
          'output_index': 0,
          'item': {
            'id': 'sh_1',
            'type': 'shell_call',
            'call_id': 'call_shell_1',
            'status': 'completed',
            'action': {
              'commands': ['ls -la'],
            },
            'environment': {
              'type': 'container_reference',
              'container_id': 'cntr_1',
            },
          },
        },
        {
          'type': 'response.output_item.done',
          'output_index': 1,
          'item': {
            'id': 'sho_1',
            'type': 'shell_call_output',
            'call_id': 'call_shell_1',
            'status': 'completed',
            'output': [
              {
                'stdout': 'ok',
                'stderr': '',
                'outcome': {
                  'type': 'exit',
                  'exit_code': 0,
                },
              },
            ],
          },
        },
        {
          'type': 'response.output_item.added',
          'output_index': 2,
          'item': {
            'id': 'apc_1',
            'type': 'apply_patch_call',
            'call_id': 'call_patch_1',
            'status': 'in_progress',
            'operation': {
              'type': 'delete_file',
              'path': 'old.txt',
            },
          },
        },
        {
          'type': 'response.output_item.done',
          'output_index': 2,
          'item': {
            'id': 'apc_1',
            'type': 'apply_patch_call',
            'call_id': 'call_patch_1',
            'status': 'completed',
            'operation': {
              'type': 'delete_file',
              'path': 'old.txt',
            },
          },
        },
        {
          'type': 'response.output_item.added',
          'output_index': 3,
          'item': {
            'id': 'apc_2',
            'type': 'apply_patch_call',
            'call_id': 'call_patch_2',
            'status': 'in_progress',
            'operation': {
              'type': 'update_file',
              'path': 'lib/main.dart',
              'diff': '',
            },
          },
        },
        {
          'type': 'response.apply_patch_call_operation_diff.delta',
          'item_id': 'apc_2',
          'output_index': 3,
          'delta': '+void main() {',
        },
        {
          'type': 'response.apply_patch_call_operation_diff.done',
          'item_id': 'apc_2',
          'output_index': 3,
          'diff': '+void main() {\\n}',
        },
        {
          'type': 'response.output_item.done',
          'output_index': 3,
          'item': {
            'id': 'apc_2',
            'type': 'apply_patch_call',
            'call_id': 'call_patch_2',
            'status': 'completed',
            'operation': {
              'type': 'update_file',
              'path': 'lib/main.dart',
              'diff': '+void main() {\\n}',
            },
          },
        },
      ]) {
        events.addAll(codec.decodeStreamChunk(chunk, state));
      }

      final toolCalls = events.whereType<ToolCallEvent>().toList();
      expect(toolCalls, hasLength(3));
      expect(toolCalls[0].toolCall.toolCallId, 'call_shell_1');
      expect(toolCalls[0].toolCall.toolName, 'shell');
      expect(toolCalls[0].toolCall.providerExecuted, isTrue);
      expect(toolCalls[0].toolCall.input, {
        'action': {
          'commands': ['ls -la'],
        },
      });
      expect(toolCalls[1].toolCall.toolCallId, 'call_patch_1');
      expect(toolCalls[1].toolCall.toolName, 'apply_patch');
      expect(toolCalls[1].toolCall.input, {
        'callId': 'call_patch_1',
        'operation': {
          'type': 'delete_file',
          'path': 'old.txt',
        },
      });
      expect(toolCalls[2].toolCall.toolCallId, 'call_patch_2');
      expect(toolCalls[2].toolCall.toolName, 'apply_patch');
      expect(toolCalls[2].toolCall.input, {
        'callId': 'call_patch_2',
        'operation': {
          'type': 'update_file',
          'path': 'lib/main.dart',
          'diff': '+void main() {\\n}',
        },
      });

      final applyPatchStarts = events
          .whereType<ToolInputStartEvent>()
          .where((event) => event.toolName == 'apply_patch')
          .toList();
      expect(applyPatchStarts.map((event) => event.toolCallId), [
        'call_patch_1',
        'call_patch_2',
      ]);
      expect(
        events
            .whereType<ToolInputDeltaEvent>()
            .where((event) => event.toolCallId == 'call_patch_1')
            .map((event) => event.delta)
            .toList(),
        [
          '{"callId":"call_patch_1","operation":{"type":"delete_file","path":"old.txt"}}',
        ],
      );
      expect(
        events
            .whereType<ToolInputDeltaEvent>()
            .where((event) => event.toolCallId == 'call_patch_2')
            .map((event) => event.delta)
            .toList(),
        [
          '{"callId":"call_patch_2","operation":{"type":"update_file","path":"lib/main.dart","diff":"',
          '+void main() {',
          '"}}',
        ],
      );
      expect(
        events
            .whereType<ToolInputEndEvent>()
            .map((event) => event.toolCallId)
            .where((id) => id.startsWith('call_patch_'))
            .toList(),
        ['call_patch_1', 'call_patch_2'],
      );

      final toolResult = events.whereType<ToolResultEvent>().single.toolResult;
      expect(toolResult.toolCallId, 'call_shell_1');
      expect(toolResult.toolName, 'shell');
      expect(toolResult.output, {
        'output': [
          {
            'stdout': 'ok',
            'stderr': '',
            'outcome': {
              'type': 'exit',
              'exitCode': 0,
            },
          },
        ],
      });
      expect(events.whereType<CustomEvent>(), isEmpty);
    });

    test('maps computer call streams to provider-executed tool events', () {
      const codec = OpenAIResponsesCodec();
      final state = OpenAIResponsesStreamState()
        ..responseId = 'resp_computer'
        ..serviceTier = 'default';
      final events = <LanguageModelStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'type': 'response.output_item.added',
          'output_index': 0,
          'item': {
            'id': 'cu_1',
            'type': 'computer_call',
            'status': 'in_progress',
          },
        },
        {
          'type': 'response.output_item.done',
          'output_index': 0,
          'item': {
            'id': 'cu_1',
            'type': 'computer_call',
            'status': 'completed',
          },
        },
      ]) {
        events.addAll(codec.decodeStreamChunk(chunk, state));
      }

      final inputStart = events.whereType<ToolInputStartEvent>().single;
      expect(inputStart.toolCallId, 'cu_1');
      expect(inputStart.toolName, 'computer_use');
      expect(inputStart.providerExecuted, isTrue);
      expect(events.whereType<ToolInputEndEvent>().single.toolCallId, 'cu_1');
      final toolCall = events.whereType<ToolCallEvent>().single.toolCall;
      expect(toolCall.toolCallId, 'cu_1');
      expect(toolCall.toolName, 'computer_use');
      expect(toolCall.providerExecuted, isTrue);
      expect(toolCall.input, '');

      final toolResult = events.whereType<ToolResultEvent>().single.toolResult;
      expect(toolResult.toolCallId, 'cu_1');
      expect(toolResult.toolName, 'computer_use');
      expect(toolResult.output, {
        'type': 'computer_use_tool_result',
        'status': 'completed',
      });
      expect(events.whereType<CustomEvent>(), isEmpty);
    });

    test('maps custom tool streams to unified tool events', () {
      const codec = OpenAIResponsesCodec();
      final state = OpenAIResponsesStreamState()
        ..responseId = 'resp_custom_tool'
        ..serviceTier = 'default';
      final events = <LanguageModelStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'type': 'response.output_item.added',
          'output_index': 0,
          'item': {
            'id': 'ct_1',
            'type': 'custom_tool_call',
            'call_id': 'call_custom_1',
            'name': 'write_sql',
            'input': '',
          },
        },
        {
          'type': 'response.custom_tool_call_input.delta',
          'item_id': 'ct_1',
          'output_index': 0,
          'delta': 'SELECT * ',
        },
        {
          'type': 'response.custom_tool_call_input.delta',
          'item_id': 'ct_1',
          'output_index': 0,
          'delta': 'FROM users',
        },
        {
          'type': 'response.output_item.done',
          'output_index': 0,
          'item': {
            'id': 'ct_1',
            'type': 'custom_tool_call',
            'call_id': 'call_custom_1',
            'name': 'write_sql',
            'input': 'SELECT * FROM users',
            'status': 'completed',
          },
        },
        {
          'type': 'response.output_item.done',
          'output_index': 1,
          'item': {
            'type': 'custom_tool_call_output',
            'call_id': 'call_custom_1',
            'output': 'ok',
          },
        },
      ]) {
        events.addAll(codec.decodeStreamChunk(chunk, state));
      }

      final inputStart = events.whereType<ToolInputStartEvent>().single;
      expect(inputStart.toolCallId, 'call_custom_1');
      expect(inputStart.toolName, 'write_sql');
      expect(inputStart.providerExecuted, isFalse);
      expect(
        events.whereType<ToolInputDeltaEvent>().map((event) => event.delta),
        ['SELECT * ', 'FROM users'],
      );
      expect(
        events.whereType<ToolInputEndEvent>().single.toolCallId,
        'call_custom_1',
      );

      final toolCall = events.whereType<ToolCallEvent>().single.toolCall;
      expect(toolCall.toolCallId, 'call_custom_1');
      expect(toolCall.toolName, 'write_sql');
      expect(toolCall.input, 'SELECT * FROM users');

      final toolResult = events.whereType<ToolResultEvent>().single.toolResult;
      expect(toolResult.toolCallId, 'call_custom_1');
      expect(toolResult.toolName, 'write_sql');
      expect(toolResult.output, 'ok');
      expect(events.whereType<CustomEvent>(), isEmpty);
    });

    test('maps message output item completion to text end without custom event',
        () {
      const codec = OpenAIResponsesCodec();
      final state = OpenAIResponsesStreamState();
      final events = <LanguageModelStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'type': 'response.output_item.added',
          'output_index': 0,
          'item': {
            'id': 'msg_done',
            'type': 'message',
            'status': 'in_progress',
          },
        },
        {
          'type': 'response.output_item.done',
          'output_index': 0,
          'item': {
            'id': 'msg_done',
            'type': 'message',
            'status': 'completed',
          },
        },
      ]) {
        events.addAll(codec.decodeStreamChunk(chunk, state));
      }

      expect(events.whereType<TextStartEvent>().single.id, 'msg_done');
      expect(events.whereType<TextEndEvent>().single.id, 'msg_done');
      expect(events.whereType<CustomEvent>(), isEmpty);
    });

    test('collects content_part.done logprobs into finish metadata', () {
      const codec = OpenAIResponsesCodec();
      final state = OpenAIResponsesStreamState();
      final events = <LanguageModelStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'type': 'response.content_part.done',
          'item_id': 'msg_logprobs',
          'output_index': 0,
          'content_index': 0,
          'part': {
            'type': 'output_text',
            'text': 'Hello',
            'logprobs': [
              {
                'token': 'Hello',
                'logprob': -0.1,
              },
            ],
          },
        },
        {
          'type': 'response.completed',
          'response': {
            'id': 'resp_logprobs',
            'model': 'gpt-4.1-mini',
            'created_at': 1710000000,
            'status': 'completed',
            'usage': {
              'input_tokens': 1,
              'output_tokens': 1,
              'total_tokens': 2,
            },
          },
        },
      ]) {
        events.addAll(codec.decodeStreamChunk(chunk, state));
      }

      final textEnd = events.whereType<TextEndEvent>().single;
      expect(textEnd.id, 'msg_logprobs');
      expect(
        textEnd.providerMetadata?.namespace('openai'),
        containsPair('logprobs', [
          {
            'token': 'Hello',
            'logprob': -0.1,
          },
        ]),
      );

      final finish = events.whereType<FinishEvent>().single;
      expect(
        finish.providerMetadata?.namespace('openai'),
        containsPair('logprobs', [
          {
            'token': 'Hello',
            'logprob': -0.1,
          },
        ]),
      );
    });

    test(
        'maps content_part.done annotations without duplicate sources and preserves annotation metadata on text-end',
        () {
      const codec = OpenAIResponsesCodec();
      final state = OpenAIResponsesStreamState();
      final events = <LanguageModelStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'type': 'response.output_text.annotation.added',
          'item_id': 'msg_123',
          'output_index': 0,
          'content_index': 0,
          'annotation_index': 0,
          'annotation': {
            'type': 'url_citation',
            'url': 'https://example.com',
            'title': 'Example URL',
            'start_index': 0,
            'end_index': 10,
          },
        },
        {
          'type': 'response.output_text.annotation.added',
          'item_id': 'msg_123',
          'output_index': 0,
          'content_index': 0,
          'annotation_index': 1,
          'annotation': {
            'type': 'file_citation',
            'file_id': 'file-abc123',
            'filename': 'resource1.json',
            'index': 123,
          },
        },
        {
          'type': 'response.content_part.done',
          'item_id': 'msg_123',
          'output_index': 0,
          'content_index': 0,
          'part': {
            'type': 'output_text',
            'text': 'Based on web search and file content.',
            'annotations': [
              {
                'type': 'url_citation',
                'url': 'https://example.com',
                'title': 'Example URL',
                'start_index': 0,
                'end_index': 10,
              },
              {
                'type': 'file_citation',
                'file_id': 'file-abc123',
                'filename': 'resource1.json',
                'index': 123,
              },
            ],
          },
        },
      ]) {
        events.addAll(codec.decodeStreamChunk(chunk, state));
      }

      final sources =
          events.whereType<SourceEvent>().map((event) => event.source).toList();
      expect(sources, hasLength(2));
      expect(sources[0].kind, SourceReferenceKind.url);
      expect(sources[0].sourceId, 'https://example.com');
      expect(sources[1].kind, SourceReferenceKind.document);
      expect(sources[1].sourceId, 'file-abc123');

      final textEnd = events.whereType<TextEndEvent>().single;
      expect(textEnd.id, 'msg_123');
      expect(
        textEnd.providerMetadata?.namespace('openai'),
        containsPair('annotations', [
          {
            'type': 'url_citation',
            'url': 'https://example.com',
            'title': 'Example URL',
            'start_index': 0,
            'end_index': 10,
          },
          {
            'type': 'file_citation',
            'file_id': 'file-abc123',
            'filename': 'resource1.json',
            'index': 123,
          },
        ]),
      );
    });
  });
}
