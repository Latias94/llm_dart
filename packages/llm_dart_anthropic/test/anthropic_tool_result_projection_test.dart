import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_anthropic/src/anthropic_tool_result_projection.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic tool result projection', () {
    test('recognizes provider-executed result block types', () {
      expect(isAnthropicToolResultBlockType('mcp_tool_result'), isTrue);
      expect(isAnthropicToolResultBlockType('web_fetch_tool_result'), isTrue);
      expect(isAnthropicToolResultBlockType('web_search_tool_result'), isTrue);
      expect(
        isAnthropicToolResultBlockType('code_execution_tool_result'),
        isTrue,
      );
      expect(
        isAnthropicToolResultBlockType('bash_code_execution_tool_result'),
        isTrue,
      );
      expect(
        isAnthropicToolResultBlockType(
          'text_editor_code_execution_tool_result',
        ),
        isTrue,
      );
      expect(isAnthropicToolResultBlockType('tool_search_tool_result'), isTrue);
      expect(isAnthropicToolResultBlockType('tool_result'), isFalse);
      expect(isAnthropicToolResultBlockType(null), isFalse);
    });

    test('maps fallback names and dynamic result defaults', () {
      expect(anthropicFallbackToolResultName('mcp_tool_result'), 'mcp.unknown');
      expect(anthropicFallbackToolResultName('web_fetch_tool_result'),
          'web_fetch');
      expect(
        anthropicFallbackToolResultName('web_search_tool_result'),
        'web_search',
      );
      expect(
        anthropicFallbackToolResultName('code_execution_tool_result'),
        'code_execution',
      );
      expect(
        anthropicFallbackToolResultName('bash_code_execution_tool_result'),
        'code_execution',
      );
      expect(
        anthropicFallbackToolResultName(
          'text_editor_code_execution_tool_result',
        ),
        'code_execution',
      );
      expect(
        anthropicFallbackToolResultName('tool_search_tool_result'),
        'tool_search',
      );
      expect(anthropicFallbackToolResultName('unknown_tool_result'), 'tool');
      expect(
        isAnthropicDynamicToolResultBlock('web_search_tool_result'),
        isTrue,
      );
      expect(isAnthropicDynamicToolResultBlock('unknown_tool_result'), isFalse);
    });

    test('projects MCP tool result errors from is_error', () {
      final output = anthropicToolResultOutput(
        'mcp_tool_result',
        {
          'type': 'mcp_tool_result',
          'tool_use_id': 'mcptoolu_1',
          'is_error': true,
          'content': [
            {
              'type': 'text',
              'text': 'failed',
            },
          ],
        },
      );

      expect(output, isA<ErrorJsonToolOutput>());
      expect(output.isError, isTrue);
      expect(output.value, [
        {
          'type': 'text',
          'text': 'failed',
        },
      ]);
    });

    test('projects execution tool result errors from result content type', () {
      final output = anthropicToolResultOutput(
        'bash_code_execution_tool_result',
        {
          'type': 'bash_code_execution_tool_result',
          'tool_use_id': 'srvtoolu_1',
          'content': {
            'type': 'bash_code_execution_error',
            'error_code': 'permission_denied',
          },
        },
      );

      expect(output, isA<ErrorJsonToolOutput>());
      expect(output.isError, isTrue);
      expect(output.value, {
        'type': 'bash_code_execution_error',
        'error_code': 'permission_denied',
      });
    });

    test('maps custom replay kinds', () {
      expect(
        anthropicToolResultCustomKind('web_fetch_tool_result'),
        'anthropic.result.web_fetch',
      );
      expect(
        anthropicToolResultCustomKind('web_search_tool_result'),
        'anthropic.result.web_search',
      );
      expect(
        anthropicToolResultCustomKind('tool_search_tool_result'),
        'anthropic.result.tool_search',
      );
      expect(
        anthropicToolResultCustomKind('code_execution_tool_result'),
        'anthropic.result.code_execution',
      );
      expect(anthropicToolResultCustomKind('mcp_tool_result'), isNull);
    });

    test('normalizes code execution replay payloads', () {
      final payload = anthropicToolResultReplayPayload(
        blockType: 'text_editor_code_execution_tool_result',
        toolCallId: 'srvtoolu_2',
        toolName: 'str_replace_based_edit_tool',
        block: {
          'type': 'text_editor_code_execution_tool_result',
          'tool_use_id': 'srvtoolu_2',
          'content': {
            'type': 'text_editor_code_execution_result',
            'stdout': 'done',
          },
        },
      );

      expect(payload, {
        'schema': AnthropicCodeExecutionReplay.schema,
        'replayRole': 'tool',
        'toolCallId': 'srvtoolu_2',
        'toolName': AnthropicCodeExecutionReplay.canonicalToolName,
        'blockType': 'text_editor_code_execution_tool_result',
        'block': {
          'type': 'text_editor_code_execution_tool_result',
          'tool_use_id': 'srvtoolu_2',
          'content': {
            'type': 'text_editor_code_execution_result',
            'stdout': 'done',
          },
        },
      });
    });

    test('preserves non-execution replay tool names', () {
      final payload = anthropicToolResultReplayPayload(
        blockType: 'web_fetch_tool_result',
        toolCallId: 'srvtoolu_3',
        toolName: 'web_fetch',
        block: {
          'type': 'web_fetch_tool_result',
          'tool_use_id': 'srvtoolu_3',
          'content': {
            'type': 'web_fetch_result',
            'url': 'https://example.com',
          },
        },
      );

      expect(payload, {
        'replayRole': 'tool',
        'toolCallId': 'srvtoolu_3',
        'toolName': 'web_fetch',
        'block': {
          'type': 'web_fetch_tool_result',
          'tool_use_id': 'srvtoolu_3',
          'content': {
            'type': 'web_fetch_result',
            'url': 'https://example.com',
          },
        },
      });
    });
  });
}
