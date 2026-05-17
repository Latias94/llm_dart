import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_openai/src/openai_responses_codec.dart';
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

      final toolInputStart = events.whereType<ToolInputStartEvent>().single;
      expect(toolInputStart.toolCallId, 'call_1');
      expect(toolInputStart.toolName, 'weather');
      expect(events.whereType<ToolInputDeltaEvent>().single.delta,
          '{"city":"Hong Kong"}');
      expect(events.whereType<ToolInputEndEvent>().single.toolCallId, 'call_1');

      final toolCall = events.whereType<ToolCallEvent>().single.toolCall;
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

      final custom = events.whereType<CustomEvent>().single;
      expect(custom.kind, 'openai.web_search_call');
      expect(
        custom.data,
        containsPair('id', 'ws_1'),
      );

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

    test('maps image generation partial images to custom events', () {
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

      final custom = events.whereType<CustomEvent>().single;
      expect(custom.kind, 'openai.image_generation_call.partial_image');
      expect(
        custom.data,
        {
          'item_id': 'img_1',
          'output_index': 1,
          'partial_image_b64': 'AQID',
        },
      );
      expect(
        custom.providerMetadata?.namespace('openai'),
        allOf(
          containsPair('responseId', 'resp_img'),
          containsPair('itemId', 'img_1'),
          containsPair('itemType', 'image_generation_call.partial_image'),
          containsPair('outputIndex', 1),
          containsPair('serviceTier', 'default'),
        ),
      );
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
