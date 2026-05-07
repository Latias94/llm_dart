import 'package:llm_dart/providers/anthropic/anthropic.dart';
import 'package:test/test.dart';

void main() {
  group('AnthropicChatResponse', () {
    test('projects text, thinking, tools, MCP blocks, and usage', () {
      final response = AnthropicChatResponse({
        'content': [
          {
            'type': 'thinking',
            'thinking': 'Plan carefully.',
          },
          {
            'type': 'redacted_thinking',
          },
          {
            'type': 'text',
            'text': 'First answer.',
          },
          {
            'type': 'text',
            'text': 'Second answer.',
          },
          {
            'type': 'tool_use',
            'id': 'toolu_1',
            'name': 'get_weather',
            'input': {'city': 'Hong Kong'},
          },
          {
            'type': 'mcp_tool_use',
            'id': 'mcptoolu_1',
            'name': 'read_doc',
            'server_name': 'docs',
            'input': {'path': '/guide'},
          },
          {
            'type': 'mcp_tool_result',
            'tool_use_id': 'mcptoolu_1',
            'is_error': false,
            'content': [
              {'type': 'text', 'text': 'Document content.'},
            ],
          },
        ],
        'usage': {
          'input_tokens': 12,
          'output_tokens': 8,
        },
      });

      expect(response.text, 'First answer.\nSecond answer.');
      expect(
        response.thinking,
        'Plan carefully.\n\n'
        '[Redacted thinking content - encrypted for safety]',
      );

      final toolCalls = response.toolCalls!;
      expect(toolCalls, hasLength(2));
      expect(toolCalls[0].id, 'toolu_1');
      expect(toolCalls[0].callType, 'function');
      expect(toolCalls[0].function.name, 'get_weather');
      expect(toolCalls[0].function.arguments, '{"city":"Hong Kong"}');
      expect(toolCalls[1].id, 'mcptoolu_1');
      expect(toolCalls[1].callType, 'mcp_function');
      expect(toolCalls[1].function.name, 'read_doc');
      expect(toolCalls[1].function.arguments, '{"path":"/guide"}');

      final mcpToolUse = response.mcpToolUses!.single;
      expect(mcpToolUse.id, 'mcptoolu_1');
      expect(mcpToolUse.name, 'read_doc');
      expect(mcpToolUse.serverName, 'docs');

      final mcpToolResult = response.mcpToolResults!.single;
      expect(mcpToolResult.toolUseId, 'mcptoolu_1');
      expect(mcpToolResult.isError, isFalse);
      expect(mcpToolResult.content.single['text'], 'Document content.');

      expect(response.usage?.promptTokens, 12);
      expect(response.usage?.completionTokens, 8);
      expect(response.usage?.totalTokens, 20);
    });

    test('returns null projections for empty response content', () {
      final response = AnthropicChatResponse({
        'content': [],
      });

      expect(response.text, isNull);
      expect(response.thinking, isNull);
      expect(response.toolCalls, isNull);
      expect(response.mcpToolUses, isNull);
      expect(response.mcpToolResults, isNull);
      expect(response.usage, isNull);
      expect(response.toString(), isEmpty);
    });
  });
}
