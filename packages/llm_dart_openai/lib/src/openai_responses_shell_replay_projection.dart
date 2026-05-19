import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_request_encoding_util.dart';

final class OpenAIResponsesNativeToolCallReplayProjection {
  final Map<String, Object?> inputItem;

  const OpenAIResponsesNativeToolCallReplayProjection(this.inputItem);
}

final class OpenAIResponsesNativeToolOutputReplayProjection {
  final Map<String, Object?> inputItem;

  const OpenAIResponsesNativeToolOutputReplayProjection(this.inputItem);
}

OpenAIResponsesNativeToolCallReplayProjection?
    projectOpenAIResponsesLocalShellReplayCall(ToolCallPromptPart part) {
  if (part.toolName != 'local_shell') {
    return null;
  }

  final input = openAIRequestAsMap(part.input);
  final action = openAIRequestAsMap(input?['action']);
  if (action == null) {
    return null;
  }

  return OpenAIResponsesNativeToolCallReplayProjection({
    'type': 'local_shell_call',
    'id': _replayItemId(part) ?? part.toolCallId,
    'call_id': part.toolCallId,
    'action': {
      'type': 'exec',
      if (action['command'] != null) 'command': action['command'],
      if (action['timeoutMs'] != null) 'timeout_ms': action['timeoutMs'],
      if (action['timeout_ms'] != null) 'timeout_ms': action['timeout_ms'],
      if (action['user'] != null) 'user': action['user'],
      if (action['workingDirectory'] != null)
        'working_directory': action['workingDirectory'],
      if (action['working_directory'] != null)
        'working_directory': action['working_directory'],
      if (action['env'] != null) 'env': action['env'],
    },
  });
}

OpenAIResponsesNativeToolCallReplayProjection?
    projectOpenAIResponsesShellReplayCall(ToolCallPromptPart part) {
  if (part.toolName != 'shell') {
    return null;
  }

  final input = openAIRequestAsMap(part.input);
  final action = openAIRequestAsMap(input?['action']);
  if (action == null) {
    return null;
  }

  return OpenAIResponsesNativeToolCallReplayProjection({
    'type': 'shell_call',
    'id': _replayItemId(part) ?? part.toolCallId,
    'call_id': part.toolCallId,
    'status': 'completed',
    'action': {
      if (action['commands'] != null) 'commands': action['commands'],
      if (action['timeoutMs'] != null) 'timeout_ms': action['timeoutMs'],
      if (action['timeout_ms'] != null) 'timeout_ms': action['timeout_ms'],
      if (action['maxOutputLength'] != null)
        'max_output_length': action['maxOutputLength'],
      if (action['max_output_length'] != null)
        'max_output_length': action['max_output_length'],
    },
  });
}

OpenAIResponsesNativeToolCallReplayProjection?
    projectOpenAIResponsesApplyPatchReplayCall(ToolCallPromptPart part) {
  if (part.toolName != 'apply_patch') {
    return null;
  }

  final input = openAIRequestAsMap(part.input);
  if (input == null) {
    return null;
  }

  return OpenAIResponsesNativeToolCallReplayProjection({
    'type': 'apply_patch_call',
    'id': _replayItemId(part) ?? part.toolCallId,
    'call_id': openAIRequestAsString(input['callId']) ??
        openAIRequestAsString(input['call_id']) ??
        part.toolCallId,
    'status': 'completed',
    if (input['operation'] != null) 'operation': input['operation'],
  });
}

OpenAIResponsesNativeToolOutputReplayProjection?
    projectOpenAIResponsesLocalShellReplayOutput(ToolResultPromptPart part) {
  if (part.toolName != 'local_shell') {
    return null;
  }

  final output = openAIRequestAsMap(part.output);
  if (output == null || !output.containsKey('output')) {
    return null;
  }

  return OpenAIResponsesNativeToolOutputReplayProjection({
    'type': 'local_shell_call_output',
    'call_id': part.toolCallId,
    'output': output['output'],
  });
}

OpenAIResponsesNativeToolOutputReplayProjection?
    projectOpenAIResponsesShellReplayOutput(ToolResultPromptPart part) {
  if (part.toolName != 'shell') {
    return null;
  }

  final output = openAIRequestAsMap(part.output);
  final entries = _asList(output?['output']);
  return OpenAIResponsesNativeToolOutputReplayProjection({
    'type': 'shell_call_output',
    'call_id': part.toolCallId,
    'output': [
      for (final entry in entries) _projectShellOutputEntry(entry),
    ],
  });
}

OpenAIResponsesNativeToolOutputReplayProjection?
    projectOpenAIResponsesApplyPatchReplayOutput(ToolResultPromptPart part) {
  if (part.toolName != 'apply_patch') {
    return null;
  }

  final output = openAIRequestAsMap(part.output);
  if (output == null) {
    return null;
  }

  return OpenAIResponsesNativeToolOutputReplayProjection({
    'type': 'apply_patch_call_output',
    'call_id': part.toolCallId,
    'status': openAIRequestAsString(output['status']) ?? 'completed',
    if (output['output'] != null) 'output': output['output'],
  });
}

String? _replayItemId(PromptPart part) {
  final metadata = openAIPromptPartProviderMetadata(part)?.namespace('openai');
  return openAIRequestAsString(metadata?['itemId']);
}

Map<String, Object?> _projectShellOutputEntry(Object? value) {
  final entry = openAIRequestAsMap(value) ?? const <String, Object?>{};
  final outcome = openAIRequestAsMap(entry['outcome']);
  return {
    'stdout': entry['stdout'],
    'stderr': entry['stderr'],
    'outcome': _projectShellOutcome(outcome),
  };
}

Map<String, Object?>? _projectShellOutcome(Map<String, Object?>? outcome) {
  final type = openAIRequestAsString(outcome?['type']);
  if (type == 'timeout') {
    return const {'type': 'timeout'};
  }

  if (type == 'exit') {
    return {
      'type': 'exit',
      'exit_code': outcome?['exitCode'] ?? outcome?['exit_code'],
    };
  }

  return outcome;
}

List<Object?> _asList(Object? value) {
  if (value is List<Object?>) {
    return value;
  }

  if (value is List) {
    return List<Object?>.from(value);
  }

  return const [];
}
