import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:test/test.dart';

void main() {
  group('AnthropicMcpServer', () {
    test('round-trips JSON-safe server configuration', () {
      final server = AnthropicMcpServer.url(
        name: 'workspace',
        url: 'https://mcp.example.com',
        authorizationToken: 'token-1',
        toolConfiguration: const AnthropicMcpToolConfiguration(
          enabled: true,
          allowedTools: ['search', 'fetch'],
        ),
      );

      final decoded = AnthropicMcpServer.fromJson(server.toJson());

      expect(decoded.name, 'workspace');
      expect(decoded.type, 'url');
      expect(decoded.url, 'https://mcp.example.com');
      expect(decoded.authorizationToken, 'token-1');
      expect(decoded.toolConfiguration?.enabled, isTrue);
      expect(decoded.toolConfiguration?.allowedTools, ['search', 'fetch']);
    });
  });

  group('AnthropicMcpToolUse', () {
    test('round-trips tool-use payloads', () {
      final toolUse = AnthropicMcpToolUse(
        id: 'toolu_1',
        name: 'search',
        serverName: 'workspace',
        input: {
          'query': 'anthropic docs',
        },
      );

      final decoded = AnthropicMcpToolUse.fromJson(toolUse.toJson());

      expect(decoded.id, 'toolu_1');
      expect(decoded.name, 'search');
      expect(decoded.serverName, 'workspace');
      expect(decoded.input, {
        'query': 'anthropic docs',
      });
    });
  });

  group('AnthropicMcpToolResult', () {
    test('round-trips tool-result payloads', () {
      final result = AnthropicMcpToolResult(
        toolUseId: 'toolu_1',
        isError: false,
        content: const [
          {
            'type': 'text',
            'text': 'done',
          },
        ],
      );

      final decoded = AnthropicMcpToolResult.fromJson(result.toJson());

      expect(decoded.toolUseId, 'toolu_1');
      expect(decoded.isError, isFalse);
      expect(decoded.content, [
        {
          'type': 'text',
          'text': 'done',
        },
      ]);
    });
  });
}
