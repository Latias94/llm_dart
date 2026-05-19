import 'openai_responses_native_shell_projection_models.dart';
import 'openai_responses_shell_projection_support.dart';

OpenAIResponsesNativeShellCallProjection? projectOpenAIResponsesLocalShellCall(
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

  final action = openAIResponsesNativeShellAsMap(item['action']) ??
      const <String, Object?>{};
  return OpenAIResponsesNativeShellCallProjection(
    toolCallId: toolCallId,
    toolName: openAIResponsesLocalShellToolName,
    input: {
      'action': {
        'type': openAIResponsesNativeShellAsString(action['type']) ?? 'exec',
        if (action['command'] != null) 'command': action['command'],
        if (action['timeout_ms'] != null) 'timeoutMs': action['timeout_ms'],
        if (action['user'] != null) 'user': action['user'],
        if (action['working_directory'] != null)
          'workingDirectory': action['working_directory'],
        if (action['env'] != null) 'env': action['env'],
      },
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
    projectOpenAIResponsesLocalShellOutput(
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
    toolName: openAIResponsesLocalShellToolName,
    output: {
      'output': item['output'],
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
