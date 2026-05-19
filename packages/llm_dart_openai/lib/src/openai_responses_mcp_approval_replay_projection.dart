import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_request_encoding_util.dart';
import 'openai_responses_replay_policy.dart';

final class OpenAIResponsesMcpApprovalReplayState {
  final Set<String> _processedApprovalIds = <String>{};

  bool markProcessed(String approvalId) {
    return _processedApprovalIds.add(approvalId);
  }
}

final class OpenAIResponsesMcpApprovalReplayProjection {
  const OpenAIResponsesMcpApprovalReplayProjection();

  List<Object?>? encodeApprovalResponse(
    ToolApprovalResponsePromptPart part, {
    required OpenAIResponsesReplayPolicy replayPolicy,
    required OpenAIResponsesMcpApprovalReplayState approvalState,
  }) {
    if (!approvalState.markProcessed(part.approvalId)) {
      return const [];
    }

    return [
      if (replayPolicy.store) replayPolicy.itemReference(part.approvalId),
      {
        'type': 'mcp_approval_response',
        'approval_request_id': part.approvalId,
        'approve': part.approved,
      },
    ];
  }

  bool shouldSkipDeniedToolResult(ToolResultPromptPart part) {
    final output = part.toolOutput;
    if (output is! ExecutionDeniedToolOutput) {
      return false;
    }

    final metadata = output.providerMetadata?.namespace('openai');
    final approvalId = openAIRequestAsString(metadata?['approvalId']);
    return approvalId != null;
  }
}
