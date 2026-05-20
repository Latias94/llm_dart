import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../common/openai_request_encoding_util.dart';
import 'openai_responses_tool_search_projection.dart';

final class OpenAIResponsesToolSearchCallReplayProjection {
  final String itemId;
  final String? callId;
  final String execution;
  final Object? arguments;

  const OpenAIResponsesToolSearchCallReplayProjection({
    required this.itemId,
    required this.callId,
    required this.execution,
    required this.arguments,
  });

  Map<String, Object?> toInputItem() {
    return {
      'type': 'tool_search_call',
      'id': itemId,
      'execution': execution,
      'call_id': callId,
      'status': 'completed',
      'arguments': arguments,
    };
  }
}

final class OpenAIResponsesToolSearchOutputReplayProjection {
  final String? itemId;
  final String? callId;
  final String execution;
  final List<Object?> tools;

  const OpenAIResponsesToolSearchOutputReplayProjection({
    required this.itemId,
    required this.callId,
    required this.execution,
    required this.tools,
  });

  Map<String, Object?> toInputItem() {
    return {
      'type': 'tool_search_output',
      if (itemId != null) 'id': itemId,
      'execution': execution,
      'call_id': callId,
      'status': 'completed',
      'tools': tools,
    };
  }
}

OpenAIResponsesToolSearchCallReplayProjection?
    projectOpenAIResponsesToolSearchReplayCall(
  ToolCallPromptPart part, {
  required Map<String, Object?>? metadata,
}) {
  if (part.toolName != openAIResponsesToolSearchToolName) {
    return null;
  }

  final input = _asMap(part.input);
  if (input == null) {
    return null;
  }

  final callId = openAIRequestAsString(input['call_id']);
  final itemId = openAIRequestAsString(metadata?['itemId']) ?? part.toolCallId;
  return OpenAIResponsesToolSearchCallReplayProjection(
    itemId: itemId,
    callId: callId,
    execution: callId == null ? 'server' : 'client',
    arguments: input['arguments'],
  );
}

OpenAIResponsesToolSearchOutputReplayProjection?
    projectOpenAIResponsesToolSearchReplayOutput(
  ToolResultPromptPart part, {
  required Map<String, Object?>? metadata,
}) {
  if (part.toolName != openAIResponsesToolSearchToolName) {
    return null;
  }

  final output = _asMap(part.output);
  if (output == null) {
    return null;
  }

  final tools = _asList(output['tools']);
  return OpenAIResponsesToolSearchOutputReplayProjection(
    itemId: openAIRequestAsString(metadata?['itemId']),
    callId: _resolveToolSearchOutputCallId(part, metadata),
    execution: _resolveToolSearchOutputExecution(part, metadata),
    tools: List<Object?>.unmodifiable(tools),
  );
}

String? _resolveToolSearchOutputCallId(
  ToolResultPromptPart part,
  Map<String, Object?>? metadata,
) {
  final callId = openAIRequestAsString(metadata?['callId']);
  if (callId != null) {
    return callId;
  }

  final execution = openAIRequestAsString(metadata?['execution']);
  if (execution == 'server') {
    return null;
  }

  return part.toolCallId;
}

String _resolveToolSearchOutputExecution(
  ToolResultPromptPart part,
  Map<String, Object?>? metadata,
) {
  final execution = openAIRequestAsString(metadata?['execution']);
  if (execution == 'server') {
    return 'server';
  }
  if (execution == 'client') {
    return 'client';
  }

  return _resolveToolSearchOutputCallId(part, metadata) == null
      ? 'server'
      : 'client';
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
