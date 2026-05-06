import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  const codec = AnthropicMessagesResultCodec();

  group('AnthropicMessagesResultCodec', () {
    test('decodes text responses with citations', () {
      final result = codec.decodeResponse({
        'id': 'msg_1',
        'model': 'claude-sonnet-4-5',
        'content': [
          {
            'type': 'text',
            'text': 'Hello',
            'citations': [
              {
                'type': 'web_search_result_location',
                'cited_text': 'Hello',
                'url': 'https://example.com',
                'title': 'Example',
                'encrypted_index': 'enc_1',
              },
            ],
          },
        ],
        'stop_reason': 'end_turn',
        'stop_sequence': null,
        'usage': {
          'input_tokens': 12,
          'output_tokens': 34,
        },
      });

      expect(result.text, 'Hello');
      expect(result.finishReason, FinishReason.stop);
      expect(result.responseId, 'msg_1');
      expect(result.responseModelId, 'claude-sonnet-4-5');
      expect(result.usage?.inputTokens, 12);
      expect(result.usage?.outputTokens, 34);
      expect(result.content.length, 2);
      expect(result.content.first, isA<TextContentPart>());
      expect(result.content.last, isA<SourceContentPart>());

      final source = (result.content.last as SourceContentPart).source;
      expect(source.kind, SourceReferenceKind.url);
      expect(source.uri.toString(), 'https://example.com');
      expect(source.title, 'Example');
    });

    test('decodes mcp tool use and result content', () {
      final result = codec.decodeResponse({
        'id': 'msg_2',
        'model': 'claude-sonnet-4-5',
        'content': [
          {
            'type': 'mcp_tool_use',
            'id': 'mcptoolu_1',
            'name': 'echo',
            'server_name': 'workspace',
            'input': {
              'message': 'hello world',
            },
          },
          {
            'type': 'mcp_tool_result',
            'tool_use_id': 'mcptoolu_1',
            'is_error': false,
            'content': [
              {
                'type': 'text',
                'text': 'Tool echo: hello world',
              },
            ],
          },
          {
            'type': 'text',
            'text': 'done',
          },
        ],
        'stop_reason': 'end_turn',
        'usage': {
          'input_tokens': 20,
          'output_tokens': 10,
        },
      });

      final toolCall = result.content.whereType<ToolCallContentPart>().single;
      final toolResult =
          result.content.whereType<ToolResultContentPart>().single;

      expect(toolCall.toolCall.toolName, 'mcp.echo');
      expect(toolCall.toolCall.providerExecuted, isTrue);
      expect(toolCall.toolCall.isDynamic, isTrue);
      expect(toolCall.toolCall.title, 'workspace');

      expect(toolResult.toolResult.toolName, 'mcp.echo');
      expect(toolResult.toolResult.isDynamic, isTrue);
      expect(toolResult.toolResult.isError, isFalse);
      expect(
        toolResult.providerMetadata?.values['anthropic'],
        {
          'serverName': 'workspace',
          'partType': 'mcp_tool_result',
        },
      );
      expect(result.text, 'done');
    });

    test('decodes reasoning and provider-executed tool results', () {
      final result = codec.decodeResponse({
        'id': 'msg_3',
        'model': 'claude-sonnet-4-5',
        'content': [
          {
            'type': 'thinking',
            'thinking': 'plan',
            'signature': 'sig_1',
          },
          {
            'type': 'redacted_thinking',
            'data': 'secret',
          },
          {
            'type': 'server_tool_use',
            'id': 'srvtoolu_1',
            'name': 'web_search',
            'input': {
              'query': 'dart sdk',
            },
          },
          {
            'type': 'web_search_tool_result',
            'tool_use_id': 'srvtoolu_1',
            'content': [
              {
                'url': 'https://dart.dev',
                'title': 'Dart',
                'page_age': '1d',
                'encrypted_content': 'enc_1',
                'type': 'web_search_result',
              },
            ],
          },
        ],
        'stop_reason': 'end_turn',
        'usage': {
          'input_tokens': 30,
          'output_tokens': 15,
        },
      });

      final reasoningParts =
          result.content.whereType<ReasoningContentPart>().toList();
      final toolCall = result.content.whereType<ToolCallContentPart>().single;
      final toolResult =
          result.content.whereType<ToolResultContentPart>().single;
      final customPart = result.content.whereType<CustomContentPart>().single;
      final source = result.content.whereType<SourceContentPart>().single;

      expect(reasoningParts, hasLength(2));
      expect(reasoningParts.first.text, 'plan');
      expect(
        reasoningParts.first.providerMetadata?.values['anthropic'],
        {
          'signature': 'sig_1',
        },
      );
      expect(reasoningParts.last.text, '');
      expect(
        reasoningParts.last.providerMetadata?.values['anthropic'],
        {
          'redactedData': 'secret',
        },
      );

      expect(toolCall.toolCall.toolName, 'web_search');
      expect(toolCall.toolCall.providerExecuted, isTrue);
      expect(toolCall.toolCall.isDynamic, isTrue);

      expect(toolResult.toolResult.toolName, 'web_search');
      expect(toolResult.toolResult.isDynamic, isTrue);
      expect(customPart.kind, 'anthropic.result.web_search');
      expect(customPart.data, {
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
              'page_age': '1d',
              'encrypted_content': 'enc_1',
              'type': 'web_search_result',
            },
          ],
        },
      });
      expect(source.source.uri.toString(), 'https://dart.dev');
      expect(source.source.title, 'Dart');
    });

    test('decodes web fetch tool results into custom replay parts', () {
      final result = codec.decodeResponse({
        'id': 'msg_4',
        'model': 'claude-sonnet-4-5',
        'content': [
          {
            'type': 'server_tool_use',
            'id': 'srvtoolu_2',
            'name': 'web_fetch',
            'input': {
              'url': 'https://example.com/article',
            },
          },
          {
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
        ],
        'stop_reason': 'end_turn',
        'usage': {
          'input_tokens': 20,
          'output_tokens': 10,
        },
      });

      final toolResult =
          result.content.whereType<ToolResultContentPart>().single;
      final customPart = result.content.whereType<CustomContentPart>().single;

      expect(toolResult.toolResult.toolName, 'web_fetch');
      expect(toolResult.toolResult.isDynamic, isTrue);
      expect(toolResult.toolResult.output, {
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
      });
      expect(customPart.kind, 'anthropic.result.web_fetch');
      expect(customPart.data, {
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

    test('decodes code execution tool results into custom replay parts', () {
      final result = codec.decodeResponse({
        'id': 'msg_5',
        'model': 'claude-sonnet-4-5',
        'content': [
          {
            'type': 'server_tool_use',
            'id': 'srvtoolu_3',
            'name': 'bash_code_execution',
            'input': {
              'command': 'echo hi',
            },
          },
          {
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
        ],
        'stop_reason': 'end_turn',
        'usage': {
          'input_tokens': 20,
          'output_tokens': 10,
        },
      });

      final toolResult =
          result.content.whereType<ToolResultContentPart>().single;
      final customPart = result.content.whereType<CustomContentPart>().single;

      expect(toolResult.toolResult.toolName, 'bash_code_execution');
      expect(toolResult.toolResult.isDynamic, isTrue);
      expect(toolResult.toolResult.output, {
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
      });
      expect(customPart.kind, 'anthropic.result.code_execution');
      expect(customPart.data, {
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

    test('decodes tool-search tool results into custom replay parts', () {
      final result = codec.decodeResponse({
        'id': 'msg_6',
        'model': 'claude-sonnet-4-5',
        'content': [
          {
            'type': 'server_tool_use',
            'id': 'srvtoolu_4',
            'name': 'tool_search_tool_regex',
            'input': {
              'pattern': 'weather|forecast',
              'limit': 5,
            },
          },
          {
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
        ],
        'stop_reason': 'end_turn',
        'usage': {
          'input_tokens': 20,
          'output_tokens': 10,
        },
      });

      final toolResult =
          result.content.whereType<ToolResultContentPart>().single;
      final customPart = result.content.whereType<CustomContentPart>().single;

      expect(toolResult.toolResult.toolName, 'tool_search_tool_regex');
      expect(toolResult.toolResult.isDynamic, isTrue);
      expect(toolResult.toolResult.output, {
        'type': 'tool_search_tool_search_result',
        'tool_references': [
          {
            'type': 'tool_reference',
            'tool_name': 'get_weather',
          },
        ],
      });
      expect(customPart.kind, 'anthropic.result.tool_search');
      expect(customPart.data, {
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
  });
}
