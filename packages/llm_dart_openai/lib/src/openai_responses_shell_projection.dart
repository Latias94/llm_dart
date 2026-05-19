import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_support.dart';

const openAIResponsesLocalShellToolName = 'local_shell';
const openAIResponsesShellToolName = 'shell';
const openAIResponsesApplyPatchToolName = 'apply_patch';

final class OpenAIResponsesNativeShellCallProjection {
  final String toolCallId;
  final String toolName;
  final Object? input;
  final bool providerExecuted;
  final ProviderMetadata? providerMetadata;

  const OpenAIResponsesNativeShellCallProjection({
    required this.toolCallId,
    required this.toolName,
    required this.input,
    required this.providerExecuted,
    required this.providerMetadata,
  });

  ToolCallContent toToolCall() {
    return ToolCallContent(
      toolCallId: toolCallId,
      toolName: toolName,
      input: input,
      providerExecuted: providerExecuted,
    );
  }
}

final class OpenAIResponsesNativeShellOutputProjection {
  final String toolCallId;
  final String toolName;
  final Object? output;
  final ProviderMetadata? providerMetadata;

  const OpenAIResponsesNativeShellOutputProjection({
    required this.toolCallId,
    required this.toolName,
    required this.output,
    required this.providerMetadata,
  });

  ToolResultContent toToolResult() {
    return ToolResultContent(
      toolCallId: toolCallId,
      toolName: toolName,
      output: output,
    );
  }
}

OpenAIResponsesNativeShellCallProjection? projectOpenAIResponsesLocalShellCall(
  Map<String, Object?> item, {
  String? responseId,
  String? serviceTier,
  int? outputIndex,
}) {
  final toolCallId = _asString(item['call_id']) ?? _asString(item['id']);
  if (toolCallId == null) {
    return null;
  }

  final action = _asMap(item['action']) ?? const <String, Object?>{};
  return OpenAIResponsesNativeShellCallProjection(
    toolCallId: toolCallId,
    toolName: openAIResponsesLocalShellToolName,
    input: {
      'action': {
        'type': _asString(action['type']) ?? 'exec',
        if (action['command'] != null) 'command': action['command'],
        if (action['timeout_ms'] != null) 'timeoutMs': action['timeout_ms'],
        if (action['user'] != null) 'user': action['user'],
        if (action['working_directory'] != null)
          'workingDirectory': action['working_directory'],
        if (action['env'] != null) 'env': action['env'],
      },
    },
    providerExecuted: false,
    providerMetadata: _metadata(
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
  final toolCallId = _asString(item['call_id']) ?? _asString(item['id']);
  if (toolCallId == null) {
    return null;
  }

  return OpenAIResponsesNativeShellOutputProjection(
    toolCallId: toolCallId,
    toolName: openAIResponsesLocalShellToolName,
    output: {
      'output': item['output'],
    },
    providerMetadata: _metadata(
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

OpenAIResponsesNativeShellCallProjection? projectOpenAIResponsesShellCall(
  Map<String, Object?> item, {
  String? responseId,
  String? serviceTier,
  int? outputIndex,
}) {
  final toolCallId = _asString(item['call_id']) ?? _asString(item['id']);
  if (toolCallId == null) {
    return null;
  }

  final action = _asMap(item['action']) ?? const <String, Object?>{};
  return OpenAIResponsesNativeShellCallProjection(
    toolCallId: toolCallId,
    toolName: openAIResponsesShellToolName,
    input: {
      'action': {
        if (action['commands'] != null) 'commands': action['commands'],
      },
    },
    providerExecuted: _isShellProviderExecuted(item),
    providerMetadata: _metadata(
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
  final toolCallId = _asString(item['call_id']) ?? _asString(item['id']);
  if (toolCallId == null) {
    return null;
  }

  return OpenAIResponsesNativeShellOutputProjection(
    toolCallId: toolCallId,
    toolName: openAIResponsesShellToolName,
    output: {
      'output': [
        for (final entry in _asList(item['output']))
          _projectShellOutputEntry(entry),
      ],
    },
    providerMetadata: _metadata(
      item,
      responseId: responseId,
      serviceTier: serviceTier,
      outputIndex: outputIndex,
      extra: {
        'callId': toolCallId,
        'outputCount': _asList(item['output']).length,
      },
    ),
  );
}

OpenAIResponsesNativeShellCallProjection? projectOpenAIResponsesApplyPatchCall(
  Map<String, Object?> item, {
  String? responseId,
  String? serviceTier,
  int? outputIndex,
}) {
  final toolCallId = _asString(item['call_id']) ?? _asString(item['id']);
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
    providerMetadata: _metadata(
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
  final toolCallId = _asString(item['call_id']) ?? _asString(item['id']);
  if (toolCallId == null) {
    return null;
  }

  return OpenAIResponsesNativeShellOutputProjection(
    toolCallId: toolCallId,
    toolName: openAIResponsesApplyPatchToolName,
    output: {
      'status': _asString(item['status']) ?? 'completed',
      if (item['output'] != null) 'output': item['output'],
    },
    providerMetadata: _metadata(
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

ProviderMetadata? _metadata(
  Map<String, Object?> item, {
  required String? responseId,
  required String? serviceTier,
  required int? outputIndex,
  Map<String, Object?> extra = const {},
}) {
  return openAIResponsesProviderMetadata({
    'responseId': responseId,
    'itemId': _asString(item['id']),
    'itemType': _asString(item['type']),
    'status': _asString(item['status']),
    'phase': _asString(item['phase']),
    'outputIndex': outputIndex,
    'serviceTier': serviceTier,
    ...extra,
  });
}

Map<String, Object?> _projectShellOutputEntry(Object? value) {
  final entry = _asMap(value) ?? const <String, Object?>{};
  final outcome = _asMap(entry['outcome']);
  return {
    'stdout': entry['stdout'],
    'stderr': entry['stderr'],
    'outcome': _projectShellOutcome(outcome),
  };
}

Map<String, Object?>? _projectShellOutcome(Map<String, Object?>? outcome) {
  final type = _asString(outcome?['type']);
  if (type == 'timeout') {
    return const {'type': 'timeout'};
  }

  if (type == 'exit') {
    return {
      'type': 'exit',
      'exitCode': outcome?['exit_code'] ?? outcome?['exitCode'],
    };
  }

  return outcome;
}

bool _isShellProviderExecuted(Map<String, Object?> item) {
  final environment = _asMap(item['environment']);
  final environmentType = _asString(environment?['type']);
  return environmentType == 'container_auto' ||
      environmentType == 'container_reference';
}

Map<String, Object?>? _asMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return Map<String, Object?>.from(value);
  }

  return null;
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

String? _asString(Object? value) => value is String ? value : null;
