import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_mcp_support.dart';

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

OpenAIResponsesMcpApprovalProjection? projectOpenAIResponsesMcpApprovalRequest(
  Map<String, Object?> item,
) {
  final approvalId = openAIResponsesMcpString(item['approval_request_id']) ??
      openAIResponsesMcpString(item['id']);
  final toolName = openAIResponsesMcpString(item['name']);
  if (approvalId == null || toolName == null) {
    return null;
  }

  final serverLabel = openAIResponsesMcpString(item['server_label']);
  return OpenAIResponsesMcpApprovalProjection(
    approvalId: approvalId,
    toolName: toolName,
    qualifiedToolName: openAIResponsesMcpToolName(toolName),
    input: decodeOpenAIResponsesMcpJsonValue(
      openAIResponsesMcpString(item['arguments']) ?? '{}',
    ),
    serverLabel: serverLabel,
    providerMetadata: openAIResponsesMcpItemMetadata(
      item,
      approvalRequestId: approvalId,
      serverLabel: serverLabel,
    ),
  );
}
