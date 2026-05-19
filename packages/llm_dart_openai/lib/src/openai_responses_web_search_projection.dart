import 'package:llm_dart_provider/llm_dart_provider.dart';

const openAIResponsesWebSearchToolName = 'web_search';

final class OpenAIResponsesWebSearchProjection {
  final String toolCallId;
  final Map<String, Object?> output;
  final ProviderMetadata? providerMetadata;

  const OpenAIResponsesWebSearchProjection({
    required this.toolCallId,
    required this.output,
    required this.providerMetadata,
  });

  ToolCallContent toToolCall() {
    return ToolCallContent(
      toolCallId: toolCallId,
      toolName: openAIResponsesWebSearchToolName,
      input: const <String, Object?>{},
      providerExecuted: true,
    );
  }

  ToolResultContent toToolResult() {
    return ToolResultContent(
      toolCallId: toolCallId,
      toolName: openAIResponsesWebSearchToolName,
      output: output,
    );
  }
}

OpenAIResponsesWebSearchProjection? projectOpenAIResponsesWebSearchCall(
  Map<String, Object?> item, {
  String? responseId,
  String? serviceTier,
  int? outputIndex,
}) {
  final toolCallId = _asString(item['id']);
  if (toolCallId == null) {
    return null;
  }

  final action = _asMap(item['action']);
  return OpenAIResponsesWebSearchProjection(
    toolCallId: toolCallId,
    output: _projectOutput(action),
    providerMetadata: openAIResponsesWebSearchMetadata(
      item,
      responseId: responseId,
      serviceTier: serviceTier,
      outputIndex: outputIndex,
      actionType: _asString(action?['type']),
      sourceCount: _asListOrNull(action?['sources'])?.length,
    ),
  );
}

ProviderMetadata? openAIResponsesWebSearchMetadata(
  Map<String, Object?> item, {
  required String? responseId,
  required String? serviceTier,
  required int? outputIndex,
  required String? actionType,
  required int? sourceCount,
}) {
  return _providerMetadata({
    'responseId': responseId,
    'itemId': _asString(item['id']),
    'itemType': _asString(item['type']),
    'status': _asString(item['status']),
    'phase': _asString(item['phase']),
    'outputIndex': outputIndex,
    'serviceTier': serviceTier,
    'actionType': actionType,
    'sourceCount': sourceCount,
  });
}

Map<String, Object?> _projectOutput(Map<String, Object?>? action) {
  final actionType = _asString(action?['type']);
  if (action == null || actionType == null) {
    return const <String, Object?>{};
  }

  if (actionType == 'search') {
    return {
      'action': {
        'type': 'search',
        if (_asString(action['query']) case final query?) 'query': query,
      },
      if (_asListOrNull(action['sources']) case final sources?)
        'sources': sources,
    };
  }

  if (actionType == 'open_page') {
    return {
      'action': {
        'type': 'openPage',
        'url': _asString(action['url']),
      },
    };
  }

  if (actionType == 'find_in_page') {
    return {
      'action': {
        'type': 'findInPage',
        'url': _asString(action['url']),
        'pattern': _asString(action['pattern']),
      },
    };
  }

  return {
    'action': action,
  };
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

Map<String, Object?>? _asMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return Map<String, Object?>.from(value);
  }

  return null;
}

List<Object?>? _asListOrNull(Object? value) {
  if (value is List<Object?>) {
    return value;
  }

  if (value is List) {
    return List<Object?>.from(value);
  }

  return null;
}

String? _asString(Object? value) {
  return value is String ? value : null;
}
