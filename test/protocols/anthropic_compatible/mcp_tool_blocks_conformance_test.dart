import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

import '_fake_anthropic_compatible_json_client.dart';

void main() {
  group('Anthropic-compatible MCP tool blocks conformance', () {
    test(
        'preserves mcp_tool_* blocks but does not surface them as local toolCalls',
        () async {
      const config = AnthropicConfig(
        apiKey: 'k',
        model: 'test-model',
        providerId: 'anthropic',
      );

      final client = FakeAnthropicCompatibleJsonClient(
        config,
        responses: [
          {
            'id': 'msg_mcp',
            'model': 'test-model',
            'stop_reason': 'end_turn',
            'usage': {
              'input_tokens': 1,
              'output_tokens': 1,
            },
            'content': [
              {
                'type': 'mcp_tool_use',
                'id': 'mcp_1',
                'name': 'mcp.get_weather',
                'server_name': 'mcp-1',
                'input': {'city': 'London'},
              },
              {
                'type': 'mcp_tool_result',
                'tool_use_id': 'mcp_1',
                'is_error': false,
                'content': [
                  {'type': 'text', 'text': '{"temp":20}'}
                ],
              },
            ],
          },
        ],
      );

      final chat = AnthropicChat(client, config);
      final resp = await chat.chatWithTools([ChatMessage.user('Hi')], const []);

      // MCP connector tools are provider-executed; do not expose them as local
      // tool calls, otherwise tool loops could try to execute them.
      expect(resp.toolCalls, anyOf(isNull, isEmpty));

      expect(resp, isA<AnthropicChatResponse>());
      final typed = resp as AnthropicChatResponse;
      final uses = typed.mcpToolUses;
      expect(uses, isNotNull);
      expect(uses!, hasLength(1));
      expect(uses.single.serverName, equals('mcp-1'));

      final results = typed.mcpToolResults;
      expect(results, isNotNull);
      expect(results!, hasLength(1));
      expect(results.single.toolUseId, equals('mcp_1'));
      expect(results.single.isError, isFalse);
    });
  });
}
