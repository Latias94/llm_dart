import 'package:llm_dart_provider/llm_dart_provider.dart';

const openAIResponsesCustomToolFallbackToolName = 'custom_tool';

final class OpenAIResponsesCustomToolCallProjection {
  final String toolCallId;
  final String toolName;
  final String input;
  final ProviderMetadata? providerMetadata;

  const OpenAIResponsesCustomToolCallProjection({
    required this.toolCallId,
    required this.toolName,
    required this.input,
    required this.providerMetadata,
  });

  ToolCallContent toToolCall() {
    return ToolCallContent(
      toolCallId: toolCallId,
      toolName: toolName,
      input: input,
    );
  }
}

final class OpenAIResponsesCustomToolOutputProjection {
  final String toolCallId;
  final String toolName;
  final Object? output;
  final ProviderMetadata? providerMetadata;

  const OpenAIResponsesCustomToolOutputProjection({
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

OpenAIResponsesCustomToolCallProjection? projectOpenAIResponsesCustomToolCall(
  Map<String, Object?> item, {
  String? responseId,
  String? serviceTier,
  int? outputIndex,
  String? fallbackToolCallId,
  String? fallbackToolName,
  String? fallbackInput,
}) {
  final toolCallId =
      _asString(item['call_id']) ?? fallbackToolCallId ?? _asString(item['id']);
  final toolName = _asString(item['name']) ?? fallbackToolName;
  if (toolCallId == null || toolName == null) {
    return null;
  }

  return OpenAIResponsesCustomToolCallProjection(
    toolCallId: toolCallId,
    toolName: toolName,
    input: _asString(item['input']) ?? fallbackInput ?? '',
    providerMetadata: _metadata(
      item,
      responseId: responseId,
      serviceTier: serviceTier,
      outputIndex: outputIndex,
      callId: toolCallId,
      toolName: toolName,
    ),
  );
}

OpenAIResponsesCustomToolOutputProjection?
    projectOpenAIResponsesCustomToolOutput(
  Map<String, Object?> item, {
  String? responseId,
  String? serviceTier,
  int? outputIndex,
  String? fallbackToolCallId,
  String? fallbackToolName,
}) {
  final toolCallId =
      _asString(item['call_id']) ?? fallbackToolCallId ?? _asString(item['id']);
  if (toolCallId == null) {
    return null;
  }

  final toolName = _asString(item['name']) ??
      fallbackToolName ??
      openAIResponsesCustomToolFallbackToolName;
  return OpenAIResponsesCustomToolOutputProjection(
    toolCallId: toolCallId,
    toolName: toolName,
    output: item['output'],
    providerMetadata: _metadata(
      item,
      responseId: responseId,
      serviceTier: serviceTier,
      outputIndex: outputIndex,
      callId: toolCallId,
      toolName: toolName,
    ),
  );
}

ProviderMetadata? _metadata(
  Map<String, Object?> item, {
  required String? responseId,
  required String? serviceTier,
  required int? outputIndex,
  required String? callId,
  required String? toolName,
}) {
  return _providerMetadata({
    'responseId': responseId,
    'itemId': _asString(item['id']),
    'itemType': _asString(item['type']),
    'status': _asString(item['status']),
    'phase': _asString(item['phase']),
    'outputIndex': outputIndex,
    'serviceTier': serviceTier,
    'callId': callId,
    'toolName': toolName,
  });
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

String? _asString(Object? value) => value is String ? value : null;
