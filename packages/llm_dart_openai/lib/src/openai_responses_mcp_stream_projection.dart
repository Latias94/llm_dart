import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_stream_util.dart';
import 'openai_responses_support.dart';

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesMcpApprovalRequestItemDone(
  Map<String, Object?> item,
) sync* {
  final approvalId = openAIResponsesAsString(item['approval_request_id']) ??
      openAIResponsesAsString(item['id']);
  final toolName = openAIResponsesAsString(item['name']);
  if (approvalId == null || toolName == null) {
    return;
  }

  final providerMetadata = openAIResponsesItemMetadata(
    item,
    extra: {
      'approvalRequestId': approvalId,
      'serverLabel': openAIResponsesAsString(item['server_label']),
    },
  );
  final qualifiedToolName = 'mcp.$toolName';

  yield ToolCallEvent(
    toolCall: ToolCallContent(
      toolCallId: approvalId,
      toolName: qualifiedToolName,
      input: decodeOpenAIResponsesJsonValue(
        openAIResponsesAsString(item['arguments']) ?? '{}',
      ),
      providerExecuted: true,
      isDynamic: true,
      title: openAIResponsesAsString(item['server_label']),
    ),
    providerMetadata: providerMetadata,
  );
  yield ToolApprovalRequestEvent(
    approvalId: approvalId,
    toolCallId: approvalId,
    providerMetadata: providerMetadata,
  );
}

Iterable<LanguageModelStreamEvent> decodeOpenAIResponsesMcpCallItemDone(
  Map<String, Object?> item,
) sync* {
  final toolCallId = openAIResponsesAsString(item['approval_request_id']) ??
      openAIResponsesAsString(item['id']);
  final toolName = openAIResponsesAsString(item['name']);
  if (toolCallId == null || toolName == null) {
    return;
  }

  final providerMetadata = openAIResponsesItemMetadata(
    item,
    extra: {
      'approvalRequestId': openAIResponsesAsString(
        item['approval_request_id'],
      ),
      'serverLabel': openAIResponsesAsString(item['server_label']),
    },
  );
  final qualifiedToolName = 'mcp.$toolName';
  final arguments = decodeOpenAIResponsesJsonValue(
    openAIResponsesAsString(item['arguments']) ?? '{}',
  );

  yield ToolCallEvent(
    toolCall: ToolCallContent(
      toolCallId: toolCallId,
      toolName: qualifiedToolName,
      input: arguments,
      providerExecuted: true,
      isDynamic: true,
      title: openAIResponsesAsString(item['server_label']),
    ),
    providerMetadata: providerMetadata,
  );
  yield ToolResultEvent(
    toolResult: ToolResultContent(
      toolCallId: toolCallId,
      toolName: qualifiedToolName,
      toolOutput: ToolOutput.fromValue(
        {
          'type': 'mcp_call',
          'serverLabel': openAIResponsesAsString(item['server_label']),
          'name': toolName,
          'arguments': arguments,
          if (item['output'] != null) 'output': item['output'],
          if (item['error'] != null) 'error': item['error'],
        },
        isError: item['error'] != null,
      ),
      isDynamic: true,
    ),
    providerMetadata: providerMetadata,
  );
}
