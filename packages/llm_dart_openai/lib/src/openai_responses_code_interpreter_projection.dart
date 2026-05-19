import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

const openAIResponsesCodeInterpreterToolName = 'code_interpreter';

final class OpenAIResponsesCodeInterpreterProjection {
  final String toolCallId;
  final String code;
  final String? containerId;
  final List<Object?> outputs;
  final ProviderMetadata? providerMetadata;

  const OpenAIResponsesCodeInterpreterProjection({
    required this.toolCallId,
    required this.code,
    required this.containerId,
    required this.outputs,
    required this.providerMetadata,
  });

  Map<String, Object?> get input => {
        'code': code,
        if (containerId != null) 'containerId': containerId,
      };

  Map<String, Object?> get output => {
        'outputs': outputs,
      };

  ToolCallContent toToolCall() {
    return ToolCallContent(
      toolCallId: toolCallId,
      toolName: openAIResponsesCodeInterpreterToolName,
      input: input,
      providerExecuted: true,
    );
  }

  ToolResultContent toToolResult() {
    return ToolResultContent(
      toolCallId: toolCallId,
      toolName: openAIResponsesCodeInterpreterToolName,
      output: output,
    );
  }
}

OpenAIResponsesCodeInterpreterProjection?
    projectOpenAIResponsesCodeInterpreterCall(
  Map<String, Object?> item, {
  String? responseId,
  String? serviceTier,
  int? outputIndex,
}) {
  final toolCallId = _asString(item['id']) ?? _asString(item['call_id']);
  if (toolCallId == null) {
    return null;
  }

  final outputs = List<Object?>.unmodifiable(_asList(item['outputs']));
  final containerId = _asString(item['container_id']);
  return OpenAIResponsesCodeInterpreterProjection(
    toolCallId: toolCallId,
    code: _asString(item['code']) ?? '',
    containerId: containerId,
    outputs: outputs,
    providerMetadata: openAIResponsesCodeInterpreterMetadata(
      item,
      responseId: responseId,
      serviceTier: serviceTier,
      outputIndex: outputIndex,
      containerId: containerId,
      outputCount: outputs.length,
    ),
  );
}

ProviderMetadata? openAIResponsesCodeInterpreterMetadata(
  Map<String, Object?> item, {
  required String? responseId,
  required String? serviceTier,
  required int? outputIndex,
  required String? containerId,
  required int outputCount,
}) {
  return _providerMetadata({
    'responseId': responseId,
    'itemId': _asString(item['id']),
    'itemType': _asString(item['type']),
    'status': _asString(item['status']),
    'phase': _asString(item['phase']),
    'outputIndex': outputIndex,
    'serviceTier': serviceTier,
    'containerId': containerId,
    'outputCount': outputCount,
  });
}

String openAIResponsesCodeInterpreterInputPrefix(String? containerId) {
  if (containerId == null || containerId.isEmpty) {
    return '{"code":"';
  }

  return '{"containerId":${jsonEncode(containerId)},"code":"';
}

const openAIResponsesCodeInterpreterInputSuffix = '"}';

String openAIResponsesEscapeJsonStringContent(String value) {
  final encoded = jsonEncode(value);
  return encoded.substring(1, encoded.length - 1);
}

bool openAIResponsesCodeInterpreterInputHasOnlyPrefix(String value) {
  return value == openAIResponsesCodeInterpreterInputPrefix(null) ||
      (value.startsWith('{"containerId":') && value.endsWith(',"code":"'));
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
