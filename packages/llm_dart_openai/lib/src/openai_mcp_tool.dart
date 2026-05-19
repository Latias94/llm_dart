import 'openai_builtin_tool.dart';

enum OpenAIMcpAllowedToolsType {
  names,
  filter,
}

final class OpenAIMcpAllowedTools {
  final OpenAIMcpAllowedToolsType type;
  final List<String>? toolNames;
  final bool? readOnly;

  const OpenAIMcpAllowedTools.names(this.toolNames)
      : type = OpenAIMcpAllowedToolsType.names,
        readOnly = null;

  const OpenAIMcpAllowedTools.filter({
    this.readOnly,
    this.toolNames,
  })  : type = OpenAIMcpAllowedToolsType.filter,
        assert(
          readOnly != null || toolNames != null,
          'OpenAIMcpAllowedTools.filter requires readOnly or toolNames.',
        );

  Object toJson() {
    return switch (type) {
      OpenAIMcpAllowedToolsType.names =>
        List<String>.unmodifiable(toolNames ?? const []),
      OpenAIMcpAllowedToolsType.filter => {
          if (readOnly != null) 'read_only': readOnly,
          if (toolNames != null && toolNames!.isNotEmpty)
            'tool_names': List<String>.unmodifiable(toolNames!),
        },
    };
  }
}

enum OpenAIMcpApprovalPolicyType {
  always,
  never,
  neverForTools,
}

final class OpenAIMcpApprovalPolicy {
  final OpenAIMcpApprovalPolicyType type;
  final List<String>? toolNames;

  const OpenAIMcpApprovalPolicy.always()
      : type = OpenAIMcpApprovalPolicyType.always,
        toolNames = null;

  const OpenAIMcpApprovalPolicy.never()
      : type = OpenAIMcpApprovalPolicyType.never,
        toolNames = null;

  const OpenAIMcpApprovalPolicy.neverForTools(this.toolNames)
      : type = OpenAIMcpApprovalPolicyType.neverForTools,
        assert(
          toolNames != null,
          'OpenAIMcpApprovalPolicy.neverForTools requires tool names.',
        );

  Object toJson() {
    return switch (type) {
      OpenAIMcpApprovalPolicyType.always => 'always',
      OpenAIMcpApprovalPolicyType.never => 'never',
      OpenAIMcpApprovalPolicyType.neverForTools => {
          'never': {
            'tool_names': List<String>.unmodifiable(toolNames!),
          },
        },
    };
  }
}

final class OpenAIMcpTool implements OpenAIBuiltInTool {
  final String serverLabel;
  final OpenAIMcpAllowedTools? allowedTools;
  final String? authorization;
  final String? connectorId;
  final Map<String, String>? headers;
  final OpenAIMcpApprovalPolicy? requireApproval;
  final String? serverDescription;
  final Uri? serverUrl;
  final Map<String, Object?>? parameters;

  const OpenAIMcpTool({
    required this.serverLabel,
    this.allowedTools,
    this.authorization,
    this.connectorId,
    this.headers,
    this.requireApproval,
    this.serverDescription,
    this.serverUrl,
    this.parameters,
  }) : assert(
          connectorId != null || serverUrl != null,
          'OpenAIMcpTool requires either a connectorId or a serverUrl.',
        );

  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.mcp;

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'mcp',
      'server_label': serverLabel,
      if (allowedTools != null) 'allowed_tools': allowedTools!.toJson(),
      if (authorization != null) 'authorization': authorization,
      if (connectorId != null) 'connector_id': connectorId,
      if (headers != null && headers!.isNotEmpty)
        'headers': Map<String, String>.unmodifiable(headers!),
      'require_approval': requireApproval?.toJson() ?? 'never',
      if (serverDescription != null) 'server_description': serverDescription,
      if (serverUrl != null) 'server_url': serverUrl.toString(),
      if (parameters != null) ...parameters!,
    };
  }
}
