/// Anthropic MCP Connector models
///
/// This file contains models for Anthropic's MCP connector feature, which allows
/// connecting to remote MCP servers directly from the Messages API without a
/// separate MCP client. This is distinct from general MCP protocol implementations.
///
/// Reference: https://docs.anthropic.com/en/docs/agents-and-tools/mcp-connector
library;

/// Anthropic MCP server configuration for the MCP connector feature
class AnthropicMCPServer {
  /// Server name/identifier
  final String name;

  /// Server type (currently only 'url' is supported)
  final String type;

  /// Server URL (must start with https://)
  final String url;

  /// Optional OAuth authorization token
  final String? authorizationToken;

  /// Tool configuration for this server
  final AnthropicMCPToolConfiguration? toolConfiguration;

  const AnthropicMCPServer({
    required this.name,
    required this.type,
    required this.url,
    this.authorizationToken,
    this.toolConfiguration,
  });

  /// Create a URL-based MCP server (convenience constructor)
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
                json['tool_configuration'] as Map<String, dynamic>)
            : null,
      );

  @override
  String toString() =>
      'AnthropicMCPServer(name: $name, type: $type, url: $url)';
}

/// Tool configuration for Anthropic MCP servers
class AnthropicMCPToolConfiguration {
  /// Whether to enable tools from this server (default: true)
  final bool? enabled;

  /// List of allowed tools (null means all tools are allowed)
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
        allowedTools: json['allowed_tools'] != null
            ? List<String>.from(json['allowed_tools'] as List)
            : null,
      );

  @override
  String toString() =>
      'AnthropicMCPToolConfiguration(enabled: $enabled, allowedTools: $allowedTools)';
}

/// Anthropic MCP Tool Use content block
class AnthropicMCPToolUse {
  /// Unique identifier for this tool use
  final String id;

  /// Name of the tool being used
  final String name;

  /// Name of the MCP server providing this tool
  final String serverName;

  /// Input parameters for the tool
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
        input: json['input'] as Map<String, dynamic>,
      );

  @override
  String toString() =>
      'AnthropicMCPToolUse(id: $id, name: $name, server: $serverName)';
}

/// Anthropic MCP Tool Result content block
class AnthropicMCPToolResult {
  /// ID of the tool use this result corresponds to
  final String toolUseId;

  /// Whether this result represents an error
  final bool isError;

  /// Content of the result
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
        content: List<Map<String, dynamic>>.from(json['content'] as List),
      );

  @override
  String toString() =>
      'AnthropicMCPToolResult(toolUseId: $toolUseId, isError: $isError)';
}
