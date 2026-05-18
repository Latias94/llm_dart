import 'package:llm_dart_anthropic/src/anthropic_custom_tool_replay_encoder.dart';
import 'package:llm_dart_anthropic/src/anthropic_tool_result_replay_encoder.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic tool replay encoders', () {
    test('encodes common tool results through Anthropic tool_result blocks',
        () {
      final block = const AnthropicToolResultReplayEncoder().encode(
        ToolResultPromptPart(
          toolCallId: 'toolu_1',
          toolName: 'weather',
          output: {
            'temp': 72,
          },
        ),
      );

      expect(
        block,
        {
          'type': 'tool_result',
          'tool_use_id': 'toolu_1',
          'content': '{"temp":72}',
        },
      );
    });

    test('encodes MCP tool results with JSON content', () {
      final block = const AnthropicToolResultReplayEncoder().encode(
        ToolResultPromptPart(
          toolCallId: 'mcpu_1',
          toolName: 'mcp.search',
          toolOutput: ErrorJsonToolOutput({
            'results': [
              'doc',
            ],
          }),
        ),
      );

      expect(
        block,
        {
          'type': 'mcp_tool_result',
          'tool_use_id': 'mcpu_1',
          'content': {
            'results': [
              'doc',
            ],
          },
          'is_error': true,
        },
      );
    });

    test('validates custom provider-executed web search replay blocks', () {
      final block = const AnthropicCustomToolReplayEncoder().encode(
        const CustomPromptPart(
          kind: 'anthropic.result.web_search',
          data: {
            'replayRole': 'tool',
            'block': {
              'type': 'web_search_tool_result',
              'tool_use_id': 'srv_1',
              'content': [
                {
                  'type': 'web_search_result',
                  'url': 'https://example.com',
                  'title': 'Example',
                },
              ],
            },
          },
        ),
      );

      expect(
        block,
        {
          'type': 'web_search_tool_result',
          'tool_use_id': 'srv_1',
          'content': [
            {
              'type': 'web_search_result',
              'url': 'https://example.com',
              'title': 'Example',
            },
          ],
        },
      );
    });

    test('validates custom provider-executed web fetch replay blocks', () {
      final block = const AnthropicCustomToolReplayEncoder().encode(
        const CustomPromptPart(
          kind: 'anthropic.result.web_fetch',
          data: {
            'replayRole': 'tool',
            'block': {
              'type': 'web_fetch_tool_result',
              'tool_use_id': 'srv_2',
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
        ),
      );

      expect(
        block,
        {
          'type': 'web_fetch_tool_result',
          'tool_use_id': 'srv_2',
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
      );
    });

    test('validates custom provider-executed tool-search replay blocks', () {
      final block = const AnthropicCustomToolReplayEncoder().encode(
        const CustomPromptPart(
          kind: 'anthropic.result.tool_search',
          data: {
            'replayRole': 'tool',
            'block': {
              'type': 'tool_search_tool_result',
              'tool_use_id': 'srv_3',
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
        ),
      );

      expect(
        block,
        {
          'type': 'tool_search_tool_result',
          'tool_use_id': 'srv_3',
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
      );
    });

    test('replays custom code execution blocks through the typed parser', () {
      final block = const AnthropicCustomToolReplayEncoder().encode(
        const CustomPromptPart(
          kind: 'anthropic.result.code_execution',
          data: {
            'schema': 'anthropic.execution.result.v1',
            'replayRole': 'tool',
            'toolCallId': 'srv_4',
            'toolName': 'code_execution',
            'blockType': 'bash_code_execution_tool_result',
            'block': {
              'type': 'bash_code_execution_tool_result',
              'tool_use_id': 'srv_4',
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
        ),
      );

      expect(
        block,
        {
          'type': 'bash_code_execution_tool_result',
          'tool_use_id': 'srv_4',
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
      );
    });

    test('rejects custom replay with the wrong block type', () {
      expect(
        () => const AnthropicCustomToolReplayEncoder().encode(
          const CustomPromptPart(
            kind: 'anthropic.result.web_fetch',
            data: {
              'replayRole': 'tool',
              'block': {
                'type': 'web_search_tool_result',
                'tool_use_id': 'srv_1',
              },
            },
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
