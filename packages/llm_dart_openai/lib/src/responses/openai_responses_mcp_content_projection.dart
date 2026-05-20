import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_content_part_support.dart';
import 'openai_responses_mcp_projection.dart';

List<ContentPart> decodeOpenAIResponsesMcpApprovalRequestOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesMcpApprovalRequest(item);
  if (projection == null) {
    return const [];
  }

  return openAIResponsesToolCallAndApprovalContentParts(
    toolCall: projection.toToolCall(),
    approvalRequest: projection.toApprovalRequest(),
    providerMetadata: projection.providerMetadata,
  );
}

List<ContentPart> decodeOpenAIResponsesMcpCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesMcpCall(item);
  if (projection == null) {
    return const [];
  }

  return openAIResponsesToolCallAndResultContentParts(
    toolCall: projection.toToolCall(),
    toolResult: projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}
