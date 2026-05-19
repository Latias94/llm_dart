import 'openai_responses_native_shell_projection_models.dart';
import 'openai_responses_shell_projection_support.dart';

OpenAIResponsesNativeShellCallProjection? projectOpenAIResponsesApplyPatchCall(
  Map<String, Object?> item, {
  String? responseId,
  String? serviceTier,
  int? outputIndex,
}) {
  final toolCallId = openAIResponsesNativeShellAsString(item['call_id']) ??
      openAIResponsesNativeShellAsString(item['id']);
  if (toolCallId == null) {
    return null;
  }

  return OpenAIResponsesNativeShellCallProjection(
    toolCallId: toolCallId,
    toolName: openAIResponsesApplyPatchToolName,
    input: {
      'callId': toolCallId,
      if (item['operation'] != null) 'operation': item['operation'],
    },
    providerExecuted: false,
    providerMetadata: openAIResponsesNativeShellMetadata(
      item,
      responseId: responseId,
      serviceTier: serviceTier,
      outputIndex: outputIndex,
      extra: {
        'callId': toolCallId,
      },
    ),
  );
}

OpenAIResponsesNativeShellOutputProjection?
    projectOpenAIResponsesApplyPatchOutput(
  Map<String, Object?> item, {
  String? responseId,
  String? serviceTier,
  int? outputIndex,
}) {
  final toolCallId = openAIResponsesNativeShellAsString(item['call_id']) ??
      openAIResponsesNativeShellAsString(item['id']);
  if (toolCallId == null) {
    return null;
  }

  return OpenAIResponsesNativeShellOutputProjection(
    toolCallId: toolCallId,
    toolName: openAIResponsesApplyPatchToolName,
    output: {
      'status':
          openAIResponsesNativeShellAsString(item['status']) ?? 'completed',
      if (item['output'] != null) 'output': item['output'],
    },
    providerMetadata: openAIResponsesNativeShellMetadata(
      item,
      responseId: responseId,
      serviceTier: serviceTier,
      outputIndex: outputIndex,
      extra: {
        'callId': toolCallId,
      },
    ),
  );
}
