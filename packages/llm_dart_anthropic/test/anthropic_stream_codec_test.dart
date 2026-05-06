import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  const codec = AnthropicStreamCodec();

  group('AnthropicStreamCodec', () {
    test('maps text, reasoning, tool input, and finish events', () {
      final state = AnthropicMessagesStreamState();
      final events = <TextStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'type': 'message_start',
          'message': {
            'id': 'msg_1',
            'model': 'claude-sonnet-4-5',
            'usage': {
              'input_tokens': 12,
              'output_tokens': 1,
            },
          },
        },
        {
          'type': 'content_block_start',
          'index': 0,
          'content_block': {
            'type': 'text',
            'text': '',
          },
        },
        {
          'type': 'content_block_delta',
          'index': 0,
          'delta': {
            'type': 'text_delta',
            'text': 'Hello',
          },
        },
        {
          'type': 'content_block_stop',
          'index': 0,
        },
        {
          'type': 'content_block_start',
          'index': 1,
          'content_block': {
            'type': 'thinking',
            'thinking': '',
          },
        },
        {
          'type': 'content_block_delta',
          'index': 1,
          'delta': {
            'type': 'thinking_delta',
            'thinking': 'Plan',
          },
        },
        {
          'type': 'content_block_delta',
          'index': 1,
          'delta': {
            'type': 'signature_delta',
            'signature': 'sig_1',
          },
        },
        {
          'type': 'content_block_stop',
          'index': 1,
        },
        {
          'type': 'content_block_start',
          'index': 2,
          'content_block': {
            'type': 'tool_use',
            'id': 'toolu_1',
            'name': 'weather',
          },
        },
        {
          'type': 'content_block_delta',
          'index': 2,
          'delta': {
            'type': 'input_json_delta',
            'partial_json': '{"city":"Hong Kong"}',
          },
        },
        {
          'type': 'content_block_stop',
          'index': 2,
        },
        {
          'type': 'message_delta',
          'delta': {
            'stop_reason': 'tool_use',
            'stop_sequence': null,
            'container': {
              'id': 'container_1',
              'expires_at': '2026-03-27T12:00:00Z',
            },
          },
          'usage': {
            'input_tokens': 12,
            'output_tokens': 34,
          },
        },
        {
          'type': 'message_stop',
        },
      ]) {
        events.addAll(codec.decodeChunk(chunk, state));
      }

      expect(events[0], isA<ResponseMetadataEvent>());
      expect(events[1], isA<TextStartEvent>());
      expect(events[2], isA<TextDeltaEvent>());
      expect(events[3], isA<TextEndEvent>());
      expect(events[4], isA<ReasoningStartEvent>());
      expect(events[5], isA<ReasoningDeltaEvent>());
      expect(events[6], isA<ReasoningDeltaEvent>());
      expect(events[7], isA<ReasoningEndEvent>());
      expect(events[8], isA<ToolInputStartEvent>());
      expect(events[9], isA<ToolInputDeltaEvent>());
      expect(events[10], isA<ToolInputEndEvent>());
      expect(events[11], isA<ToolCallEvent>());
      expect(events[12], isA<FinishEvent>());

      final toolCallEvent = events[11] as ToolCallEvent;
      expect(toolCallEvent.toolCall.toolCallId, 'toolu_1');
      expect(toolCallEvent.toolCall.toolName, 'weather');
      expect(
        toolCallEvent.toolCall.input,
        {
          'city': 'Hong Kong',
        },
      );

      final finishEvent = events[12] as FinishEvent;
      expect(finishEvent.finishReason, FinishReason.toolCalls);
      expect(finishEvent.rawFinishReason, 'tool_use');
      expect(finishEvent.usage?.inputTokens, 12);
      expect(finishEvent.usage?.outputTokens, 34);
      expect(
        finishEvent.providerMetadata?.values['anthropic'],
        {
          'usage': {
            'input_tokens': 12,
            'output_tokens': 34,
          },
          'container': {
            'id': 'container_1',
            'expiresAt': '2026-03-27T12:00:00Z',
          },
        },
      );
    });

    test('maps prepopulated tool calls from message_start', () {
      final state = AnthropicMessagesStreamState();
      final events = codec.decodeChunk(
        {
          'type': 'message_start',
          'message': {
            'id': 'msg_1',
            'model': 'claude-sonnet-4-5',
            'usage': {
              'input_tokens': 10,
              'output_tokens': 0,
            },
            'content': [
              {
                'type': 'tool_use',
                'id': 'toolu_2',
                'name': 'search',
                'input': {
                  'query': 'anthropic docs',
                },
                'caller': {
                  'type': 'direct',
                },
              },
            ],
          },
        },
        state,
      ).toList();

      expect(events[0], isA<ResponseMetadataEvent>());
      expect(events[1], isA<ToolInputStartEvent>());
      expect(events[2], isA<ToolInputDeltaEvent>());
      expect(events[3], isA<ToolInputEndEvent>());
      expect(events[4], isA<ToolCallEvent>());

      final toolCallEvent = events[4] as ToolCallEvent;
      expect(toolCallEvent.toolCall.toolName, 'search');
      expect(
        toolCallEvent.providerMetadata?.values['anthropic'],
        {
          'caller': {
            'type': 'direct',
          },
        },
      );
    });

    test('emits tool input errors for malformed tool input deltas', () {
      final state = AnthropicMessagesStreamState();
      final events = <TextStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'type': 'content_block_start',
          'index': 0,
          'content_block': {
            'type': 'tool_use',
            'id': 'toolu_bad_1',
            'name': 'weather',
          },
        },
        {
          'type': 'content_block_delta',
          'index': 0,
          'delta': {
            'type': 'input_json_delta',
            'partial_json': '{"city":',
          },
        },
        {
          'type': 'content_block_stop',
          'index': 0,
        },
      ]) {
        events.addAll(codec.decodeChunk(chunk, state));
      }

      expect(events[0], isA<ToolInputStartEvent>());
      expect(events[1], isA<ToolInputDeltaEvent>());
      expect(events[2], isA<ToolInputErrorEvent>());
      expect(events.whereType<ToolInputEndEvent>(), isEmpty);
      expect(events.whereType<ToolCallEvent>(), isEmpty);

      final errorEvent = events[2] as ToolInputErrorEvent;
      expect(errorEvent.toolCallId, 'toolu_bad_1');
      expect(errorEvent.toolName, 'weather');
      expect(errorEvent.input, '{"city":');
      expect(
        errorEvent.errorText,
        contains('Invalid JSON tool arguments for "weather"'),
      );
      expect(
        errorEvent.providerMetadata?.values['anthropic'],
        {
          'blockIndex': 0,
          'blockType': 'tool_use',
        },
      );
    });

    test(
        'maps mcp tool use and result blocks as dynamic provider-executed tools',
        () {
      final state = AnthropicMessagesStreamState();
      final events = <TextStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'type': 'content_block_start',
          'index': 0,
          'content_block': {
            'type': 'mcp_tool_use',
            'id': 'toolu_mcp_1',
            'name': 'search',
            'server_name': 'workspace',
            'input': {
              'query': 'dart sdk',
            },
          },
        },
        {
          'type': 'content_block_stop',
          'index': 0,
        },
        {
          'type': 'content_block_start',
          'index': 1,
          'content_block': {
            'type': 'mcp_tool_result',
            'tool_use_id': 'toolu_mcp_1',
            'is_error': false,
            'content': [
              {
                'type': 'text',
                'text': 'done',
              },
            ],
          },
        },
      ]) {
        events.addAll(codec.decodeChunk(chunk, state));
      }

      expect(events[0], isA<ToolInputStartEvent>());
      expect(events[1], isA<ToolInputDeltaEvent>());
      expect(events[2], isA<ToolInputEndEvent>());
      expect(events[3], isA<ToolCallEvent>());
      expect(events[4], isA<ToolResultEvent>());

      final toolCallEvent = events[3] as ToolCallEvent;
      expect(toolCallEvent.toolCall.toolName, 'mcp.search');
      expect(toolCallEvent.toolCall.providerExecuted, isTrue);
      expect(toolCallEvent.toolCall.isDynamic, isTrue);
      expect(toolCallEvent.toolCall.title, 'workspace');

      final toolResultEvent = events[4] as ToolResultEvent;
      expect(toolResultEvent.toolResult.toolName, 'mcp.search');
      expect(toolResultEvent.toolResult.isDynamic, isTrue);
      expect(
        toolResultEvent.providerMetadata?.values['anthropic'],
        {
          'blockIndex': 0,
          'serverName': 'workspace',
          'blockType': 'mcp_tool_result',
        },
      );
    });

    test('emits custom replay events for web-search tool results', () {
      final state = AnthropicMessagesStreamState();
      final events = <TextStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'type': 'content_block_start',
          'index': 0,
          'content_block': {
            'type': 'server_tool_use',
            'id': 'srvtoolu_1',
            'name': 'web_search',
            'input': {
              'query': 'dart sdk',
            },
          },
        },
        {
          'type': 'content_block_stop',
          'index': 0,
        },
        {
          'type': 'content_block_start',
          'index': 1,
          'content_block': {
            'type': 'web_search_tool_result',
            'tool_use_id': 'srvtoolu_1',
            'content': [
              {
                'url': 'https://dart.dev',
                'title': 'Dart',
                'type': 'web_search_result',
              },
            ],
          },
        },
      ]) {
        events.addAll(codec.decodeChunk(chunk, state));
      }

      expect(events[3], isA<ToolCallEvent>());
      expect(events[4], isA<ToolResultEvent>());
      expect(events[5], isA<CustomEvent>());
      expect(events[6], isA<SourceEvent>());

      final customEvent = events[5] as CustomEvent;
      expect(customEvent.kind, 'anthropic.result.web_search');
      expect(customEvent.data, {
        'replayRole': 'tool',
        'toolCallId': 'srvtoolu_1',
        'toolName': 'web_search',
        'block': {
          'type': 'web_search_tool_result',
          'tool_use_id': 'srvtoolu_1',
          'content': [
            {
              'url': 'https://dart.dev',
              'title': 'Dart',
              'type': 'web_search_result',
            },
          ],
        },
      });
    });

    test('emits custom replay events for web-fetch tool results', () {
      final state = AnthropicMessagesStreamState();
      final events = <TextStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'type': 'content_block_start',
          'index': 0,
          'content_block': {
            'type': 'server_tool_use',
            'id': 'srvtoolu_2',
            'name': 'web_fetch',
            'input': {
              'url': 'https://example.com/article',
            },
          },
        },
        {
          'type': 'content_block_stop',
          'index': 0,
        },
        {
          'type': 'content_block_start',
          'index': 1,
          'content_block': {
            'type': 'web_fetch_tool_result',
            'tool_use_id': 'srvtoolu_2',
            'content': {
              'type': 'web_fetch_result',
              'url': 'https://example.com/article',
              'content': {
                'type': 'document',
                'source': {
                  'type': 'text',
                  'media_type': 'text/plain',
                  'data': 'Article content',
                },
              },
            },
          },
        },
      ]) {
        events.addAll(codec.decodeChunk(chunk, state));
      }

      expect(events[3], isA<ToolCallEvent>());
      expect(events[4], isA<ToolResultEvent>());
      expect(events[5], isA<CustomEvent>());

      final customEvent = events[5] as CustomEvent;
      expect(customEvent.kind, 'anthropic.result.web_fetch');
      expect(customEvent.data, {
        'replayRole': 'tool',
        'toolCallId': 'srvtoolu_2',
        'toolName': 'web_fetch',
        'block': {
          'type': 'web_fetch_tool_result',
          'tool_use_id': 'srvtoolu_2',
          'content': {
            'type': 'web_fetch_result',
            'url': 'https://example.com/article',
            'content': {
              'type': 'document',
              'source': {
                'type': 'text',
                'media_type': 'text/plain',
                'data': 'Article content',
              },
            },
          },
        },
      });
    });

    test('emits custom replay events for code execution tool results', () {
      final state = AnthropicMessagesStreamState();
      final events = <TextStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'type': 'content_block_start',
          'index': 0,
          'content_block': {
            'type': 'server_tool_use',
            'id': 'srvtoolu_3',
            'name': 'bash_code_execution',
            'input': {
              'command': 'echo hi',
            },
          },
        },
        {
          'type': 'content_block_stop',
          'index': 0,
        },
        {
          'type': 'content_block_start',
          'index': 1,
          'content_block': {
            'type': 'bash_code_execution_tool_result',
            'tool_use_id': 'srvtoolu_3',
            'content': {
              'type': 'bash_code_execution_result',
              'stdout': 'hi\n',
              'stderr': '',
              'return_code': 0,
              'content': [
                {
                  'type': 'bash_code_execution_output',
                  'file_id': 'file_123',
                },
              ],
            },
          },
        },
      ]) {
        events.addAll(codec.decodeChunk(chunk, state));
      }

      expect(events[3], isA<ToolCallEvent>());
      expect(events[4], isA<ToolResultEvent>());
      expect(events[5], isA<CustomEvent>());

      final toolResultEvent = events[4] as ToolResultEvent;
      expect(toolResultEvent.toolResult.toolName, 'bash_code_execution');

      final customEvent = events[5] as CustomEvent;
      expect(customEvent.kind, 'anthropic.result.code_execution');
      expect(customEvent.data, {
        'schema': 'anthropic.execution.result.v1',
        'replayRole': 'tool',
        'toolCallId': 'srvtoolu_3',
        'toolName': 'code_execution',
        'blockType': 'bash_code_execution_tool_result',
        'block': {
          'type': 'bash_code_execution_tool_result',
          'tool_use_id': 'srvtoolu_3',
          'content': {
            'type': 'bash_code_execution_result',
            'stdout': 'hi\n',
            'stderr': '',
            'return_code': 0,
            'content': [
              {
                'type': 'bash_code_execution_output',
                'file_id': 'file_123',
              },
            ],
          },
        },
      });
    });

    test('emits custom replay events for tool-search tool results', () {
      final state = AnthropicMessagesStreamState();
      final events = <TextStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'type': 'content_block_start',
          'index': 0,
          'content_block': {
            'type': 'server_tool_use',
            'id': 'srvtoolu_4',
            'name': 'tool_search_tool_regex',
            'input': {
              'pattern': 'weather|forecast',
              'limit': 5,
            },
          },
        },
        {
          'type': 'content_block_stop',
          'index': 0,
        },
        {
          'type': 'content_block_start',
          'index': 1,
          'content_block': {
            'type': 'tool_search_tool_result',
            'tool_use_id': 'srvtoolu_4',
            'content': {
              'type': 'tool_search_tool_search_result',
              'tool_references': [
                {
                  'type': 'tool_reference',
                  'tool_name': 'get_weather',
                },
              ],
            },
          },
        },
      ]) {
        events.addAll(codec.decodeChunk(chunk, state));
      }

      expect(events[3], isA<ToolCallEvent>());
      expect(events[4], isA<ToolResultEvent>());
      expect(events[5], isA<CustomEvent>());

      final toolResultEvent = events[4] as ToolResultEvent;
      expect(toolResultEvent.toolResult.toolName, 'tool_search_tool_regex');

      final customEvent = events[5] as CustomEvent;
      expect(customEvent.kind, 'anthropic.result.tool_search');
      expect(customEvent.data, {
        'replayRole': 'tool',
        'toolCallId': 'srvtoolu_4',
        'toolName': 'tool_search_tool_regex',
        'block': {
          'type': 'tool_search_tool_result',
          'tool_use_id': 'srvtoolu_4',
          'content': {
            'type': 'tool_search_tool_search_result',
            'tool_references': [
              {
                'type': 'tool_reference',
                'tool_name': 'get_weather',
              },
            ],
          },
        },
      });
    });

    test('maps error chunks to ErrorEvent', () {
      final state = AnthropicMessagesStreamState();
      final events = codec.decodeChunk(
        {
          'type': 'error',
          'error': {
            'type': 'api_error',
            'message': 'overloaded',
          },
        },
        state,
      ).toList();

      expect(events, hasLength(1));
      expect(events.single, isA<ErrorEvent>());
      final error = (events.single as ErrorEvent).error;
      expect(error.kind, ModelErrorKind.provider);
      expect(error.code, 'api_error');
      expect(error.message, 'overloaded');
    });
  });
}
