final class AnthropicMcpServer {
  final String name;
  final String type;
  final String url;
  final String? authorizationToken;
  final AnthropicMcpToolConfiguration? toolConfiguration;

  const AnthropicMcpServer({
    required this.name,
    required this.type,
    required this.url,
    this.authorizationToken,
    this.toolConfiguration,
  });

  const AnthropicMcpServer.url({
    required this.name,
    required this.url,
    this.authorizationToken,
    this.toolConfiguration,
  }) : type = 'url';

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'type': type,
      'url': url,
      if (authorizationToken != null) 'authorization_token': authorizationToken,
      if (toolConfiguration != null)
        'tool_configuration': toolConfiguration!.toJson(),
    };
  }

  factory AnthropicMcpServer.fromJson(Object? value) {
    final map = _asJsonMap(value, path: r'$');
    return AnthropicMcpServer(
      name: _asJsonString(map['name'], path: r'$.name'),
      type: _asJsonString(map['type'], path: r'$.type'),
      url: _asJsonString(map['url'], path: r'$.url'),
      authorizationToken: _asNullableJsonString(
        map['authorization_token'],
        path: r'$.authorization_token',
      ),
      toolConfiguration: map['tool_configuration'] == null
          ? null
          : AnthropicMcpToolConfiguration.fromJson(map['tool_configuration']),
    );
  }
}

final class AnthropicMcpToolConfiguration {
  final bool? enabled;
  final List<String>? allowedTools;

  const AnthropicMcpToolConfiguration({
    this.enabled,
    this.allowedTools,
  });

  Map<String, Object?> toJson() {
    return {
      if (enabled != null) 'enabled': enabled,
      if (allowedTools != null) 'allowed_tools': allowedTools,
    };
  }

  factory AnthropicMcpToolConfiguration.fromJson(Object? value) {
    final map = _asJsonMap(value, path: r'$');
    return AnthropicMcpToolConfiguration(
      enabled: _asNullableJsonBool(map['enabled'], path: r'$.enabled'),
      allowedTools: map['allowed_tools'] == null
          ? null
          : _asJsonList(map['allowed_tools'], path: r'$.allowed_tools')
              .asMap()
              .entries
              .map(
                (entry) => _asJsonString(
                  entry.value,
                  path: '\$.allowed_tools[${entry.key}]',
                ),
              )
              .toList(growable: false),
    );
  }
}

final class AnthropicMcpToolUse {
  final String id;
  final String name;
  final String serverName;
  final Map<String, Object?> input;

  AnthropicMcpToolUse({
    required this.id,
    required this.name,
    required this.serverName,
    required Map<String, Object?> input,
  }) : input = Map.unmodifiable(input);

  Map<String, Object?> toJson() {
    return {
      'type': 'mcp_tool_use',
      'id': id,
      'name': name,
      'server_name': serverName,
      'input': input,
    };
  }

  factory AnthropicMcpToolUse.fromJson(Object? value) {
    final map = _asJsonMap(value, path: r'$');
    return AnthropicMcpToolUse(
      id: _asJsonString(map['id'], path: r'$.id'),
      name: _asJsonString(map['name'], path: r'$.name'),
      serverName: _asJsonString(map['server_name'], path: r'$.server_name'),
      input: _asJsonMap(map['input'], path: r'$.input'),
    );
  }
}

final class AnthropicMcpToolResult {
  final String toolUseId;
  final bool isError;
  final List<Map<String, Object?>> content;

  AnthropicMcpToolResult({
    required this.toolUseId,
    this.isError = false,
    required List<Map<String, Object?>> content,
  }) : content = List.unmodifiable(
          content.map(Map<String, Object?>.unmodifiable),
        );

  Map<String, Object?> toJson() {
    return {
      'type': 'mcp_tool_result',
      'tool_use_id': toolUseId,
      'is_error': isError,
      'content': content,
    };
  }

  factory AnthropicMcpToolResult.fromJson(Object? value) {
    final map = _asJsonMap(value, path: r'$');
    final content = _asJsonList(map['content'], path: r'$.content')
        .asMap()
        .entries
        .map(
          (entry) => _asJsonMap(
            entry.value,
            path: '\$.content[${entry.key}]',
          ),
        )
        .toList(growable: false);

    return AnthropicMcpToolResult(
      toolUseId: _asJsonString(map['tool_use_id'], path: r'$.tool_use_id'),
      isError:
          _asNullableJsonBool(map['is_error'], path: r'$.is_error') ?? false,
      content: content,
    );
  }
}

Map<String, Object?> _asJsonMap(
  Object? value, {
  required String path,
}) {
  if (value is! Map) {
    throw FormatException('Expected JSON object at $path.');
  }

  return value.map((key, nestedValue) {
    if (key is! String) {
      throw FormatException('Expected string key at $path.');
    }

    return MapEntry(key, nestedValue);
  });
}

List<Object?> _asJsonList(
  Object? value, {
  required String path,
}) {
  if (value is! List) {
    throw FormatException('Expected JSON array at $path.');
  }

  return value.cast<Object?>();
}

String _asJsonString(
  Object? value, {
  required String path,
}) {
  if (value is! String) {
    throw FormatException('Expected string at $path.');
  }

  return value;
}

String? _asNullableJsonString(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  return _asJsonString(value, path: path);
}

bool? _asNullableJsonBool(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  if (value is bool) {
    return value;
  }

  throw FormatException('Expected bool at $path.');
}
