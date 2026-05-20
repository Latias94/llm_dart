import 'openai_responses_native_shell_projection_models.dart';
import 'openai_responses_shell_output_projection.dart';
import 'openai_responses_shell_projection_support.dart';

OpenAIResponsesNativeShellCallProjection? projectOpenAIResponsesShellCall(
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
    toolName: openAIResponsesShellToolName,
    input: {
      'action': {
        if (action['commands'] != null) 'commands': action['commands'],
      },
    },
    providerExecuted: _isShellProviderExecuted(item),
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

OpenAIResponsesNativeShellOutputProjection? projectOpenAIResponsesShellOutput(
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
    toolName: openAIResponsesShellToolName,
    output: {
      'output': [
        for (final entry in openAIResponsesNativeShellAsList(item['output']))
          projectOpenAIResponsesShellOutputEntry(entry),
      ],
    },
    providerMetadata: openAIResponsesNativeShellMetadata(
      item,
      responseId: responseId,
      serviceTier: serviceTier,
      outputIndex: outputIndex,
      extra: {
        'callId': toolCallId,
        'outputCount': openAIResponsesNativeShellAsList(item['output']).length,
      },
    ),
  );
}

bool _isShellProviderExecuted(Map<String, Object?> item) {
  final environment = openAIResponsesNativeShellAsMap(item['environment']);
  final environmentType =
      openAIResponsesNativeShellAsString(environment?['type']);
  return environmentType == 'container_auto' ||
      environmentType == 'container_reference';
}
