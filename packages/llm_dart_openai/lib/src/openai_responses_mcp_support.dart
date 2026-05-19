import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

String openAIResponsesMcpToolName(String toolName) {
  return 'mcp.$toolName';
}

ProviderMetadata? openAIResponsesMcpItemMetadata(
  Map<String, Object?> item, {
  required String? approvalRequestId,
  required String? serverLabel,
}) {
  return _providerMetadata({
    'itemId': openAIResponsesMcpString(item['id']),
    'itemType': openAIResponsesMcpString(item['type']),
    'status': openAIResponsesMcpString(item['status']),
    'phase': openAIResponsesMcpString(item['phase']),
    'approvalRequestId': approvalRequestId,
    'serverLabel': serverLabel,
  });
}

ToolOutput openAIResponsesMcpCallToolOutput(
  Map<String, Object?> item, {
  required String toolName,
  required String? serverLabel,
  required Object? arguments,
}) {
  return ToolOutput.fromValue(
    {
      'type': 'mcp_call',
      'serverLabel': serverLabel,
      'name': toolName,
      'arguments': arguments,
      if (item['output'] != null) 'output': item['output'],
      if (item['error'] != null) 'error': item['error'],
    },
    isError: item['error'] != null,
  );
}

Object? decodeOpenAIResponsesMcpJsonValue(String value) {
  try {
    return jsonDecode(value);
  } catch (_) {
    return value;
  }
}

String? openAIResponsesMcpString(Object? value) {
  return value is String ? value : null;
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
