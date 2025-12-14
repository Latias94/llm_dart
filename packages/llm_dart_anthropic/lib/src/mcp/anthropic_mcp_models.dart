/// Anthropic MCP Connector models (sub-package copy of main models)
class AnthropicMCPServer {
  final String name;
  final String type;
  final String url;
  final String? authorizationToken;
  final AnthropicMCPToolConfiguration? toolConfiguration;

  const AnthropicMCPServer({
    required this.name,
    required this.type,
    required this.url,
    this.authorizationToken,
    this.toolConfiguration,
  });

  const AnthropicMCPServer.url({
    required this.name,
    required this.url,
    this.authorizationToken,
    this.toolConfiguration,
  }) : type = 'url';

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'url': url,
        if (authorizationToken != null)
          'authorization_token': authorizationToken,
        if (toolConfiguration != null)
          'tool_configuration': toolConfiguration!.toJson(),
      };

  factory AnthropicMCPServer.fromJson(Map<String, dynamic> json) =>
      AnthropicMCPServer(
        name: json['name'] as String,
        type: json['type'] as String,
        url: json['url'] as String,
        authorizationToken: json['authorization_token'] as String?,
        toolConfiguration: json['tool_configuration'] != null
            ? AnthropicMCPToolConfiguration.fromJson(
                json['tool_configuration'] as Map<String, dynamic>,
              )
            : null,
      );
}

class AnthropicMCPToolConfiguration {
  final bool? enabled;
  final List<String>? allowedTools;

  const AnthropicMCPToolConfiguration({
    this.enabled,
    this.allowedTools,
  });

  Map<String, dynamic> toJson() => {
        if (enabled != null) 'enabled': enabled,
        if (allowedTools != null) 'allowed_tools': allowedTools,
      };

  factory AnthropicMCPToolConfiguration.fromJson(Map<String, dynamic> json) =>
      AnthropicMCPToolConfiguration(
        enabled: json['enabled'] as bool?,
        allowedTools: (json['allowed_tools'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
      );
}

class AnthropicMCPToolUse {
  final String id;
  final String name;
  final String serverName;
  final Map<String, dynamic> input;

  const AnthropicMCPToolUse({
    required this.id,
    required this.name,
    required this.serverName,
    required this.input,
  });

  Map<String, dynamic> toJson() => {
        'type': 'mcp_tool_use',
        'id': id,
        'name': name,
        'server_name': serverName,
        'input': input,
      };

  factory AnthropicMCPToolUse.fromJson(Map<String, dynamic> json) =>
      AnthropicMCPToolUse(
        id: json['id'] as String,
        name: json['name'] as String,
        serverName: json['server_name'] as String,
        input: Map<String, dynamic>.from(json['input'] as Map),
      );
}

class AnthropicMCPToolResult {
  final String toolUseId;
  final bool isError;
  final List<Map<String, dynamic>> content;

  const AnthropicMCPToolResult({
    required this.toolUseId,
    required this.isError,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'type': 'mcp_tool_result',
        'tool_use_id': toolUseId,
        'is_error': isError,
        'content': content,
      };

  factory AnthropicMCPToolResult.fromJson(Map<String, dynamic> json) =>
      AnthropicMCPToolResult(
        toolUseId: json['tool_use_id'] as String,
        isError: json['is_error'] as bool? ?? false,
        content: (json['content'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
}
