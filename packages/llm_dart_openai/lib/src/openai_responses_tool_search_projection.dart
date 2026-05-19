import 'package:llm_dart_provider/llm_dart_provider.dart';

const openAIResponsesToolSearchToolName = 'tool_search';

final class OpenAIResponsesToolSearchCallProjection {
  final String toolCallId;
  final String? callId;
  final String execution;
  final Object? arguments;
  final ProviderMetadata? providerMetadata;

  const OpenAIResponsesToolSearchCallProjection({
    required this.toolCallId,
    required this.callId,
    required this.execution,
    required this.arguments,
    required this.providerMetadata,
  });

  bool get providerExecuted => execution == 'server';

  Map<String, Object?> get input => {
        'arguments': arguments,
        'call_id': callId,
      };

  ToolCallContent toToolCall() {
    return ToolCallContent(
      toolCallId: toolCallId,
      toolName: openAIResponsesToolSearchToolName,
      input: input,
      providerExecuted: providerExecuted,
    );
  }
}

final class OpenAIResponsesToolSearchOutputProjection {
  final String toolCallId;
  final String? callId;
  final String execution;
  final List<Object?> tools;
  final ProviderMetadata? providerMetadata;

  const OpenAIResponsesToolSearchOutputProjection({
    required this.toolCallId,
    required this.callId,
    required this.execution,
    required this.tools,
    required this.providerMetadata,
  });

  Map<String, Object?> get output => {
        'tools': tools,
      };

  ToolResultContent toToolResult() {
    return ToolResultContent(
      toolCallId: toolCallId,
      toolName: openAIResponsesToolSearchToolName,
      output: output,
    );
  }
}

OpenAIResponsesToolSearchCallProjection? projectOpenAIResponsesToolSearchCall(
  Map<String, Object?> item, {
  String? responseId,
  String? serviceTier,
  int? outputIndex,
}) {
  final itemId = _asString(item['id']);
  final callId = _asString(item['call_id']);
  final toolCallId = callId ?? itemId;
  if (toolCallId == null) {
    return null;
  }

  final execution = _asString(item['execution']) ?? 'server';
  return OpenAIResponsesToolSearchCallProjection(
    toolCallId: toolCallId,
    callId: callId,
    execution: execution,
    arguments: item['arguments'],
    providerMetadata: openAIResponsesToolSearchMetadata(
      item,
      responseId: responseId,
      serviceTier: serviceTier,
      outputIndex: outputIndex,
      execution: execution,
      callId: callId,
      toolCount: null,
    ),
  );
}

OpenAIResponsesToolSearchOutputProjection?
    projectOpenAIResponsesToolSearchOutput(
  Map<String, Object?> item, {
  String? responseId,
  String? serviceTier,
  int? outputIndex,
  String? fallbackToolCallId,
}) {
  final itemId = _asString(item['id']);
  final callId = _asString(item['call_id']);
  final toolCallId = callId ?? fallbackToolCallId ?? itemId;
  if (toolCallId == null) {
    return null;
  }

  final execution = _asString(item['execution']) ?? 'server';
  final tools = List<Object?>.unmodifiable(_asList(item['tools']));
  return OpenAIResponsesToolSearchOutputProjection(
    toolCallId: toolCallId,
    callId: callId,
    execution: execution,
    tools: tools,
    providerMetadata: openAIResponsesToolSearchMetadata(
      item,
      responseId: responseId,
      serviceTier: serviceTier,
      outputIndex: outputIndex,
      execution: execution,
      callId: callId,
      toolCount: tools.length,
    ),
  );
}

ProviderMetadata? openAIResponsesToolSearchMetadata(
  Map<String, Object?> item, {
  required String? responseId,
  required String? serviceTier,
  required int? outputIndex,
  required String execution,
  required String? callId,
  required int? toolCount,
}) {
  return _providerMetadata({
    'responseId': responseId,
    'itemId': _asString(item['id']),
    'itemType': _asString(item['type']),
    'status': _asString(item['status']),
    'phase': _asString(item['phase']),
    'outputIndex': outputIndex,
    'serviceTier': serviceTier,
    'execution': execution,
    'callId': callId,
    'toolCount': toolCount,
  });
}

String? openAIResponsesTakeHostedToolSearchCallId(List<String> callIds) {
  if (callIds.isEmpty) {
    return null;
  }

  return callIds.removeAt(0);
}

ProviderMetadata? _providerMetadata(Map<String, Object?> values) {
  final openaiValues = <String, Object?>{};
  for (final entry in values.entries) {
    if (entry.value != null) {
      openaiValues[entry.key] = entry.value;
    }
  }

  if (openaiValues.isEmpty) {
    return null;
  }

  return ProviderMetadata.forNamespace('openai', openaiValues);
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

String? _asString(Object? value) {
  return value is String ? value : null;
}
