import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

final class OpenAIResponsesMcpApprovalProjection {
  final String approvalId;
  final String toolName;
  final String qualifiedToolName;
  final Object? input;
  final String? serverLabel;
  final ProviderMetadata? providerMetadata;

  const OpenAIResponsesMcpApprovalProjection({
    required this.approvalId,
    required this.toolName,
    required this.qualifiedToolName,
    required this.input,
    required this.serverLabel,
    required this.providerMetadata,
  });

  ToolCallContent toToolCall() {
    return ToolCallContent(
      toolCallId: approvalId,
      toolName: qualifiedToolName,
      input: input,
      providerExecuted: true,
      isDynamic: true,
      title: serverLabel,
    );
  }

  ToolApprovalRequestContent toApprovalRequest() {
    return ToolApprovalRequestContent(
      approvalId: approvalId,
      toolCallId: approvalId,
    );
  }
}

final class OpenAIResponsesMcpCallProjection {
  final String toolCallId;
  final String toolName;
  final String qualifiedToolName;
  final Object? arguments;
  final String? serverLabel;
  final ProviderMetadata? providerMetadata;
  final ToolOutput toolOutput;

  const OpenAIResponsesMcpCallProjection({
    required this.toolCallId,
    required this.toolName,
    required this.qualifiedToolName,
    required this.arguments,
    required this.serverLabel,
    required this.providerMetadata,
    required this.toolOutput,
  });

  ToolCallContent toToolCall() {
    return ToolCallContent(
      toolCallId: toolCallId,
      toolName: qualifiedToolName,
      input: arguments,
      providerExecuted: true,
      isDynamic: true,
      title: serverLabel,
    );
  }

  ToolResultContent toToolResult() {
    return ToolResultContent(
      toolCallId: toolCallId,
      toolName: qualifiedToolName,
      toolOutput: toolOutput,
      isDynamic: true,
    );
  }
}

OpenAIResponsesMcpApprovalProjection? projectOpenAIResponsesMcpApprovalRequest(
  Map<String, Object?> item,
) {
  final approvalId =
      _asString(item['approval_request_id']) ?? _asString(item['id']);
  final toolName = _asString(item['name']);
  if (approvalId == null || toolName == null) {
    return null;
  }

  final serverLabel = _asString(item['server_label']);
  return OpenAIResponsesMcpApprovalProjection(
    approvalId: approvalId,
    toolName: toolName,
    qualifiedToolName: openAIResponsesMcpToolName(toolName),
    input: _decodeJsonValue(
      _asString(item['arguments']) ?? '{}',
    ),
    serverLabel: serverLabel,
    providerMetadata: openAIResponsesMcpItemMetadata(
      item,
      approvalRequestId: approvalId,
      serverLabel: serverLabel,
    ),
  );
}

OpenAIResponsesMcpCallProjection? projectOpenAIResponsesMcpCall(
  Map<String, Object?> item,
) {
  final toolCallId =
      _asString(item['approval_request_id']) ?? _asString(item['id']);
  final toolName = _asString(item['name']);
  if (toolCallId == null || toolName == null) {
    return null;
  }

  final serverLabel = _asString(item['server_label']);
  final arguments = _decodeJsonValue(
    _asString(item['arguments']) ?? '{}',
  );

  return OpenAIResponsesMcpCallProjection(
    toolCallId: toolCallId,
    toolName: toolName,
    qualifiedToolName: openAIResponsesMcpToolName(toolName),
    arguments: arguments,
    serverLabel: serverLabel,
    providerMetadata: openAIResponsesMcpItemMetadata(
      item,
      approvalRequestId: _asString(item['approval_request_id']),
      serverLabel: serverLabel,
    ),
    toolOutput: openAIResponsesMcpCallToolOutput(
      item,
      toolName: toolName,
      serverLabel: serverLabel,
      arguments: arguments,
    ),
  );
}

String openAIResponsesMcpToolName(String toolName) {
  return 'mcp.$toolName';
}

ProviderMetadata? openAIResponsesMcpItemMetadata(
  Map<String, Object?> item, {
  required String? approvalRequestId,
  required String? serverLabel,
}) {
  return _providerMetadata({
    'itemId': _asString(item['id']),
    'itemType': _asString(item['type']),
    'status': _asString(item['status']),
    'phase': _asString(item['phase']),
    'approvalRequestId': approvalRequestId,
    'serverLabel': serverLabel,
  });
}

ToolOutput openAIResponsesMcpCallToolOutput(
  Map<String, Object?> item, {
  required String toolName,
  required String? serverLabel,
  required Object? arguments,
}) {
  return ToolOutput.fromValue(
    {
      'type': 'mcp_call',
      'serverLabel': serverLabel,
      'name': toolName,
      'arguments': arguments,
      if (item['output'] != null) 'output': item['output'],
      if (item['error'] != null) 'error': item['error'],
    },
    isError: item['error'] != null,
  );
}

ProviderMetadata? _providerMetadata(Map<String, Object?> values) {
  final openaiValues = <String, Object?>{};
  for (final entry in values.entries) {
    if (entry.value != null) {
      openaiValues[entry.key] = entry.value;
    }
  }

  if (openaiValues.isEmpty) {
    return null;
  }

  return ProviderMetadata.forNamespace('openai', openaiValues);
}

Object? _decodeJsonValue(String value) {
  try {
    return jsonDecode(value);
  } catch (_) {
    return value;
  }
}

String? _asString(Object? value) {
  return value is String ? value : null;
}
