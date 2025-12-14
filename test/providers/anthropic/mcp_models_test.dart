import 'package:test/test.dart';
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';

void main() {
  group('AnthropicMCPServer', () {
    test('should create server with required fields', () {
      const server = AnthropicMCPServer(
        name: 'test-server',
        type: 'url',
        url: 'https://example.com/mcp',
      );

      expect(server.name, equals('test-server'));
      expect(server.type, equals('url'));
      expect(server.url, equals('https://example.com/mcp'));
      expect(server.authorizationToken, isNull);
      expect(server.toolConfiguration, isNull);
    });

    test('should create server with convenience constructor', () {
      const server = AnthropicMCPServer.url(
        name: 'test-server',
        url: 'https://example.com/mcp',
      );

      expect(server.name, equals('test-server'));
      expect(server.type, equals('url'));
      expect(server.url, equals('https://example.com/mcp'));
    });

    test('should serialize to JSON correctly', () {
      const server = AnthropicMCPServer.url(
        name: 'test-server',
        url: 'https://example.com/mcp',
        authorizationToken: 'token123',
        toolConfiguration: AnthropicMCPToolConfiguration(
          enabled: true,
          allowedTools: ['tool1', 'tool2'],
        ),
      );

      final json = server.toJson();

      expect(
          json,
          equals({
            'name': 'test-server',
            'type': 'url',
            'url': 'https://example.com/mcp',
            'authorization_token': 'token123',
            'tool_configuration': {
              'enabled': true,
              'allowed_tools': ['tool1', 'tool2'],
            },
          }));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'name': 'test-server',
        'type': 'url',
        'url': 'https://example.com/mcp',
        'authorization_token': 'token123',
        'tool_configuration': {
          'enabled': true,
          'allowed_tools': ['tool1', 'tool2'],
        },
      };

      final server = AnthropicMCPServer.fromJson(json);

      expect(server.name, equals('test-server'));
      expect(server.type, equals('url'));
      expect(server.url, equals('https://example.com/mcp'));
      expect(server.authorizationToken, equals('token123'));
      expect(server.toolConfiguration, isNotNull);
      expect(server.toolConfiguration!.enabled, isTrue);
      expect(
          server.toolConfiguration!.allowedTools, equals(['tool1', 'tool2']));
    });
  });

  group('AnthropicMCPToolConfiguration', () {
    test('should create with default values', () {
      const config = AnthropicMCPToolConfiguration();

      expect(config.enabled, isNull);
      expect(config.allowedTools, isNull);
    });

    test('should serialize to JSON correctly', () {
      const config = AnthropicMCPToolConfiguration(
        enabled: false,
        allowedTools: ['tool1'],
      );

      final json = config.toJson();

      expect(
          json,
          equals({
            'enabled': false,
            'allowed_tools': ['tool1'],
          }));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'enabled': false,
        'allowed_tools': ['tool1', 'tool2'],
      };

      final config = AnthropicMCPToolConfiguration.fromJson(json);

      expect(config.enabled, isFalse);
      expect(config.allowedTools, equals(['tool1', 'tool2']));
    });
  });

  group('AnthropicMCPToolUse', () {
    test('should create and serialize correctly', () {
      const toolUse = AnthropicMCPToolUse(
        id: 'tool_123',
        name: 'calculate',
        serverName: 'math-server',
        input: {'expression': '2 + 2'},
      );

      final json = toolUse.toJson();

      expect(
          json,
          equals({
            'type': 'mcp_tool_use',
            'id': 'tool_123',
            'name': 'calculate',
            'server_name': 'math-server',
            'input': {'expression': '2 + 2'},
          }));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'type': 'mcp_tool_use',
        'id': 'tool_123',
        'name': 'calculate',
        'server_name': 'math-server',
        'input': {'expression': '2 + 2'},
      };

      final toolUse = AnthropicMCPToolUse.fromJson(json);

      expect(toolUse.id, equals('tool_123'));
      expect(toolUse.name, equals('calculate'));
      expect(toolUse.serverName, equals('math-server'));
      expect(toolUse.input, equals({'expression': '2 + 2'}));
    });
  });

  group('AnthropicMCPToolResult', () {
    test('should create and serialize correctly', () {
      const toolResult = AnthropicMCPToolResult(
        toolUseId: 'tool_123',
        isError: false,
        content: [
          {'type': 'text', 'text': 'Result: 4'}
        ],
      );

      final json = toolResult.toJson();

      expect(
          json,
          equals({
            'type': 'mcp_tool_result',
            'tool_use_id': 'tool_123',
            'is_error': false,
            'content': [
              {'type': 'text', 'text': 'Result: 4'}
            ],
          }));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'type': 'mcp_tool_result',
        'tool_use_id': 'tool_123',
        'is_error': true,
        'content': [
          {'type': 'text', 'text': 'Error: Invalid input'}
        ],
      };

      final toolResult = AnthropicMCPToolResult.fromJson(json);

      expect(toolResult.toolUseId, equals('tool_123'));
      expect(toolResult.isError, isTrue);
      expect(
          toolResult.content,
          equals([
            {'type': 'text', 'text': 'Error: Invalid input'}
          ]));
    });

    test('should default isError to false when not provided', () {
      final json = {
        'type': 'mcp_tool_result',
        'tool_use_id': 'tool_123',
        'content': [
          {'type': 'text', 'text': 'Success'}
        ],
      };

      final toolResult = AnthropicMCPToolResult.fromJson(json);

      expect(toolResult.isError, isFalse);
    });
  });
}
