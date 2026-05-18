import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_mcp_projection.dart';

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesMcpApprovalRequestItemDone(
  Map<String, Object?> item,
) sync* {
  final projection = projectOpenAIResponsesMcpApprovalRequest(item);
  if (projection == null) {
    return;
  }

  yield ToolCallEvent(
    toolCall: projection.toToolCall(),
    providerMetadata: projection.providerMetadata,
  );
  yield ToolApprovalRequestEvent(
    approvalId: projection.approvalId,
    toolCallId: projection.approvalId,
    providerMetadata: projection.providerMetadata,
  );
}

Iterable<LanguageModelStreamEvent> decodeOpenAIResponsesMcpCallItemDone(
  Map<String, Object?> item,
) sync* {
  final projection = projectOpenAIResponsesMcpCall(item);
  if (projection == null) {
    return;
  }

  yield ToolCallEvent(
    toolCall: projection.toToolCall(),
    providerMetadata: projection.providerMetadata,
  );
  yield ToolResultEvent(
    toolResult: projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}
