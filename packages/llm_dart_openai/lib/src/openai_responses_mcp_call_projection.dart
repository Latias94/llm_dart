import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_mcp_support.dart';

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

OpenAIResponsesMcpCallProjection? projectOpenAIResponsesMcpCall(
  Map<String, Object?> item,
) {
  final toolCallId = openAIResponsesMcpString(item['approval_request_id']) ??
      openAIResponsesMcpString(item['id']);
  final toolName = openAIResponsesMcpString(item['name']);
  if (toolCallId == null || toolName == null) {
    return null;
  }

  final serverLabel = openAIResponsesMcpString(item['server_label']);
  final arguments = decodeOpenAIResponsesMcpJsonValue(
    openAIResponsesMcpString(item['arguments']) ?? '{}',
  );

  return OpenAIResponsesMcpCallProjection(
    toolCallId: toolCallId,
    toolName: toolName,
    qualifiedToolName: openAIResponsesMcpToolName(toolName),
    arguments: arguments,
    serverLabel: serverLabel,
    providerMetadata: openAIResponsesMcpItemMetadata(
      item,
      approvalRequestId: openAIResponsesMcpString(item['approval_request_id']),
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
