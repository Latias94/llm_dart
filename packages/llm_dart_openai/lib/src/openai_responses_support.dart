import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_streaming_support.dart';

List<ContentPart> decodeOpenAIResponsesMessageOutput(
    Map<String, Object?> item) {
  final parts = <ContentPart>[];
  final content = _asList(item['content']);

  for (final rawContentPart in content) {
    final contentPart = _asMap(rawContentPart);
    if (contentPart == null) {
      continue;
    }

    final contentType = _asString(contentPart['type']);
    if (contentType == 'output_text') {
      parts.add(
        TextContentPart(
          _asString(contentPart['text']) ?? '',
          providerMetadata: openAIResponsesItemMetadata(
            item,
            extra: {
              'contentType': contentType,
              'logprobs': _jsonListOrNull(contentPart['logprobs']),
            },
          ),
        ),
      );

      for (final annotation in _asList(contentPart['annotations'])) {
        final source =
            decodeOpenAIResponsesSourceAnnotation(_asMap(annotation));
        if (source != null) {
          parts.add(SourceContentPart(source));
        }
      }
      continue;
    }

    if (contentType != null) {
      parts.add(
        CustomContentPart(
          kind: 'openai.message.$contentType',
          data: contentPart,
          providerMetadata: openAIResponsesItemMetadata(item),
        ),
      );
    }
  }

  return parts;
}

List<ContentPart> decodeOpenAIResponsesReasoningOutput(
  Map<String, Object?> item,
) {
  final parts = <ContentPart>[];
  final summaries = _asList(item['summary']);

  for (var index = 0; index < summaries.length; index++) {
    final summary = _asMap(summaries[index]);
    if (summary == null) {
      continue;
    }

    final text = _asString(summary['text']);
    if (text == null || text.isEmpty) {
      continue;
    }

    parts.add(
      ReasoningContentPart(
        text,
        providerMetadata: openAIResponsesItemMetadata(
          item,
          extra: {
            'summaryIndex': index,
            'reasoningEncryptedContent': item['encrypted_content'],
            'encryptedContent': item['encrypted_content'],
          },
        ),
      ),
    );
  }

  return parts;
}

ToolCallContentPart? decodeOpenAIResponsesFunctionCallOutput(
  Map<String, Object?> item, {
  String? fallbackToolCallId,
  String? fallbackArguments,
  String? fallbackToolName,
  Object? decodedInput,
}) {
  final toolCallId =
      _asString(item['call_id']) ?? fallbackToolCallId ?? _asString(item['id']);
  final toolName = _asString(item['name']) ?? fallbackToolName;
  if (toolCallId == null || toolName == null) {
    return null;
  }

  final encodedArguments = resolveOpenAIResponsesFunctionCallArguments(
    item,
    fallbackArguments: fallbackArguments,
  );

  return ToolCallContentPart(
    ToolCallContent(
      toolCallId: toolCallId,
      toolName: toolName,
      input: decodedInput ?? decodeOpenAIResponsesJsonValue(encodedArguments),
      providerExecuted: false,
      isDynamic: false,
      title: _asString(item['title']),
    ),
    providerMetadata: openAIResponsesItemMetadata(
      item,
      extra: {
        'callId': toolCallId,
      },
    ),
  );
}

List<ContentPart> decodeOpenAIResponsesMcpApprovalRequestOutput(
  Map<String, Object?> item,
) {
  final approvalId =
      _asString(item['approval_request_id']) ?? _asString(item['id']);
  final toolName = _asString(item['name']);
  if (approvalId == null || toolName == null) {
    return const [];
  }

  final providerMetadata = openAIResponsesItemMetadata(
    item,
    extra: {
      'approvalRequestId': approvalId,
      'serverLabel': _asString(item['server_label']),
    },
  );
  final qualifiedToolName = 'mcp.$toolName';

  return [
    ToolCallContentPart(
      ToolCallContent(
        toolCallId: approvalId,
        toolName: qualifiedToolName,
        input: decodeOpenAIResponsesJsonValue(
          _asString(item['arguments']) ?? '{}',
        ),
        providerExecuted: true,
        isDynamic: true,
        title: _asString(item['server_label']),
      ),
      providerMetadata: providerMetadata,
    ),
    ToolApprovalRequestContentPart(
      ToolApprovalRequestContent(
        approvalId: approvalId,
        toolCallId: approvalId,
      ),
      providerMetadata: providerMetadata,
    ),
  ];
}

List<ContentPart> decodeOpenAIResponsesMcpCallOutput(
    Map<String, Object?> item) {
  final toolCallId =
      _asString(item['approval_request_id']) ?? _asString(item['id']);
  final toolName = _asString(item['name']);
  if (toolCallId == null || toolName == null) {
    return const [];
  }

  final providerMetadata = openAIResponsesItemMetadata(
    item,
    extra: {
      'approvalRequestId': _asString(item['approval_request_id']),
      'serverLabel': _asString(item['server_label']),
    },
  );
  final qualifiedToolName = 'mcp.$toolName';
  final arguments = decodeOpenAIResponsesJsonValue(
    _asString(item['arguments']) ?? '{}',
  );

  return [
    ToolCallContentPart(
      ToolCallContent(
        toolCallId: toolCallId,
        toolName: qualifiedToolName,
        input: arguments,
        providerExecuted: true,
        isDynamic: true,
        title: _asString(item['server_label']),
      ),
      providerMetadata: providerMetadata,
    ),
    ToolResultContentPart(
      ToolResultContent(
        toolCallId: toolCallId,
        toolName: qualifiedToolName,
        toolOutput: ToolOutput.fromValue(
          {
            'type': 'mcp_call',
            'serverLabel': _asString(item['server_label']),
            'name': toolName,
            'arguments': arguments,
            if (item['output'] != null) 'output': item['output'],
            if (item['error'] != null) 'error': item['error'],
          },
          isError: item['error'] != null,
        ),
        isDynamic: true,
      ),
      providerMetadata: providerMetadata,
    ),
  ];
}

CustomContentPart? decodeOpenAIResponsesCustomOutput(
    Map<String, Object?> item) {
  final type = _asString(item['type']);
  if (type == null) {
    return null;
  }

  return CustomContentPart(
    kind: 'openai.$type',
    data: item,
    providerMetadata: openAIResponsesItemMetadata(
      item,
      extra: {
        if (type == 'compaction') 'encryptedContent': item['encrypted_content'],
      },
    ),
  );
}

SourceReference? decodeOpenAIResponsesSourceAnnotation(
  Map<String, Object?>? annotation,
) {
  if (annotation == null) {
    return null;
  }

  final type = _asString(annotation['type']);
  if (type == 'url_citation') {
    final url = _asString(annotation['url']);
    if (url == null) {
      return null;
    }

    return SourceReference(
      kind: SourceReferenceKind.url,
      sourceId: url,
      uri: Uri.tryParse(url),
      title: _asString(annotation['title']),
      providerMetadata: openAIResponsesProviderMetadata({
        'annotationType': type,
        'startIndex': _asInt(annotation['start_index']),
        'endIndex': _asInt(annotation['end_index']),
      }),
    );
  }

  if (type == 'file_citation') {
    final sourceId =
        _asString(annotation['file_id']) ?? _asString(annotation['filename']);
    if (sourceId == null) {
      return null;
    }

    return SourceReference(
      kind: SourceReferenceKind.document,
      sourceId: sourceId,
      title: _asString(annotation['filename']),
      filename: _asString(annotation['filename']),
      mediaType: 'text/plain',
      providerMetadata: openAIResponsesProviderMetadata({
        'annotationType': type,
        'fileId': _asString(annotation['file_id']),
        'index': _asInt(annotation['index']),
      }),
    );
  }

  if (type == 'container_file_citation') {
    final sourceId =
        _asString(annotation['file_id']) ?? _asString(annotation['filename']);
    if (sourceId == null) {
      return null;
    }

    return SourceReference(
      kind: SourceReferenceKind.document,
      sourceId: sourceId,
      title: _asString(annotation['filename']),
      filename: _asString(annotation['filename']),
      mediaType: 'text/plain',
      providerMetadata: openAIResponsesProviderMetadata({
        'annotationType': type,
        'fileId': _asString(annotation['file_id']),
        'containerId': _asString(annotation['container_id']),
      }),
    );
  }

  if (type == 'file_path') {
    final sourceId = _asString(annotation['file_id']);
    if (sourceId == null) {
      return null;
    }

    return SourceReference(
      kind: SourceReferenceKind.document,
      sourceId: sourceId,
      title: sourceId,
      filename: sourceId,
      mediaType: 'application/octet-stream',
      providerMetadata: openAIResponsesProviderMetadata({
        'annotationType': type,
        'fileId': sourceId,
        'index': _asInt(annotation['index']),
      }),
    );
  }

  return null;
}

SourceEvent? decodeOpenAIResponsesSourceEvent(
  Map<String, Object?>? annotation, {
  required Set<String> emittedAnnotationKeys,
}) {
  final annotationKey = openAIResponsesAnnotationKey(annotation);
  if (annotationKey == null || !emittedAnnotationKeys.add(annotationKey)) {
    return null;
  }

  final source = decodeOpenAIResponsesSourceAnnotation(annotation);
  if (source == null) {
    return null;
  }

  return SourceEvent(source);
}

String? openAIResponsesAnnotationKey(Map<String, Object?>? annotation) {
  if (annotation == null) {
    return null;
  }

  final type = _asString(annotation['type']);
  if (type == null) {
    return null;
  }

  return switch (type) {
    'url_citation' =>
      'url:${_asString(annotation['url'])}:${_asInt(annotation['start_index'])}:${_asInt(annotation['end_index'])}',
    'file_citation' =>
      'file:${_asString(annotation['file_id'])}:${_asString(annotation['filename'])}:${_asInt(annotation['index'])}',
    'container_file_citation' =>
      'container:${_asString(annotation['container_id'])}:${_asString(annotation['file_id'])}:${_asString(annotation['filename'])}',
    'file_path' =>
      'file_path:${_asString(annotation['file_id'])}:${_asInt(annotation['index'])}',
    _ => jsonEncode(annotation),
  };
}

ProviderMetadata? openAIResponsesResponseMetadata(
  Map<String, Object?> response, {
  List<Object?> logprobs = const [],
}) {
  return openAIResponsesProviderMetadata({
    'status': _asString(response['status']),
    'serviceTier': _asString(response['service_tier']),
    if (logprobs.isNotEmpty) 'logprobs': List<Object?>.unmodifiable(logprobs),
  });
}

void collectOpenAIResponsesMessageOutputLogprobs(
  Map<String, Object?> item, {
  required List<Object?> into,
}) {
  for (final rawContentPart in _asList(item['content'])) {
    final contentPart = _asMap(rawContentPart);
    if (contentPart == null ||
        _asString(contentPart['type']) != 'output_text') {
      continue;
    }

    appendOpenAILogprobs(
      into,
      _jsonListOrNull(contentPart['logprobs']),
    );
  }
}

ProviderMetadata? openAIResponsesItemMetadata(
  Map<String, Object?> item, {
  Map<String, Object?> extra = const {},
}) {
  return openAIResponsesProviderMetadata({
    'itemId': _asString(item['id']),
    'itemType': _asString(item['type']),
    'status': _asString(item['status']),
    'phase': _asString(item['phase']),
    ...extra,
  });
}

ProviderMetadata? openAIResponsesStreamItemMetadata({
  required String? responseId,
  required String? serviceTier,
  required Map<String, Object?> chunk,
  required Map<String, Object?>? item,
}) {
  return openAIResponsesProviderMetadata({
    'responseId': responseId,
    'itemId': _asString(chunk['item_id']) ?? _asString(item?['id']),
    'itemType': _asString(item?['type']),
    'phase': _asString(item?['phase']),
    'outputIndex': _asInt(chunk['output_index']),
    'contentIndex': _asInt(chunk['content_index']),
    'summaryIndex': _asInt(chunk['summary_index']),
    'serviceTier': serviceTier,
    'logprobs': _jsonListOrNull(chunk['logprobs']),
  });
}

ProviderMetadata? openAIResponsesStreamTextPartMetadata({
  required String? responseId,
  required String? serviceTier,
  required Map<String, Object?> chunk,
  required Map<String, Object?> part,
}) {
  return openAIResponsesProviderMetadata({
    'responseId': responseId,
    'itemId': _asString(chunk['item_id']),
    'outputIndex': _asInt(chunk['output_index']),
    'contentIndex': _asInt(chunk['content_index']),
    'serviceTier': serviceTier,
    'annotations': _jsonListOrNull(part['annotations']),
    'logprobs': _jsonListOrNull(part['logprobs']),
  });
}

ProviderMetadata? openAIResponsesProviderMetadata(Map<String, Object?> values) {
  final openaiValues = <String, Object?>{};
  for (final entry in values.entries) {
    if (entry.value != null) {
      openaiValues[entry.key] = entry.value;
    }
  }

  if (openaiValues.isEmpty) {
    return null;
  }

  return ProviderMetadata({
    'openai': openaiValues,
  });
}

Object? decodeOpenAIResponsesJsonValue(String value) {
  return tryDecodeOpenAIJsonValue(value).value;
}

String resolveOpenAIResponsesFunctionCallArguments(
  Map<String, Object?> item, {
  String? fallbackArguments,
}) {
  final encoded = _asString(item['arguments']);
  if (encoded != null) {
    return encoded;
  }

  if (fallbackArguments != null && fallbackArguments.isNotEmpty) {
    return fallbackArguments;
  }

  return '{}';
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

List<Object?>? _jsonListOrNull(Object? value) {
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

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return null;
}
