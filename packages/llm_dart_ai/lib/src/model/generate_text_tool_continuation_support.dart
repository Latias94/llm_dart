import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'generate_text_step_result.dart';

List<ToolCallContent> unresolvedClientToolCallsForStep(
  GenerateTextStepResult step,
) {
  final resolvedToolCallIds = {
    for (final toolResult in step.toolResults) toolResult.toolCallId,
  };

  return step.toolCalls
      .where(
        (toolCall) =>
            !toolCall.providerExecuted &&
            !resolvedToolCallIds.contains(toolCall.toolCallId),
      )
      .toList(growable: false);
}

void validateToolCallContinuationStep(
  GenerateTextStepResult step, {
  required String runnerName,
}) {
  if (step.toolCalls.isEmpty && step.toolApprovalRequests.isEmpty) {
    throw StateError(
      '$runnerName received finishReason.toolCalls without tool calls.',
    );
  }
}
