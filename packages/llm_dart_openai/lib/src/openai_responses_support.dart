import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_code_interpreter_projection.dart';
import 'openai_responses_computer_use_projection.dart';
import 'openai_responses_custom_projection.dart';
import 'openai_responses_file_search_projection.dart';
import 'openai_responses_image_generation_projection.dart';
import 'openai_responses_mcp_projection.dart';
import 'openai_responses_shell_projection.dart';
import 'openai_responses_source_projection.dart';
import 'openai_responses_tool_search_projection.dart';
import 'openai_responses_web_search_projection.dart';
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
  final projection = projectOpenAIResponsesMcpApprovalRequest(item);
  if (projection == null) {
    return const [];
  }

  return [
    ToolCallContentPart(
      projection.toToolCall(),
      providerMetadata: projection.providerMetadata,
    ),
    ToolApprovalRequestContentPart(
      projection.toApprovalRequest(),
      providerMetadata: projection.providerMetadata,
    ),
  ];
}

List<ContentPart> decodeOpenAIResponsesMcpCallOutput(
    Map<String, Object?> item) {
  final projection = projectOpenAIResponsesMcpCall(item);
  if (projection == null) {
    return const [];
  }

  return [
    ToolCallContentPart(
      projection.toToolCall(),
      providerMetadata: projection.providerMetadata,
    ),
    ToolResultContentPart(
      projection.toToolResult(),
      providerMetadata: projection.providerMetadata,
    ),
  ];
}

List<ContentPart> decodeOpenAIResponsesCodeInterpreterCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesCodeInterpreterCall(item);
  if (projection == null) {
    return const [];
  }

  return [
    ToolCallContentPart(
      projection.toToolCall(),
      providerMetadata: projection.providerMetadata,
    ),
    ToolResultContentPart(
      projection.toToolResult(),
      providerMetadata: projection.providerMetadata,
    ),
  ];
}

List<ContentPart> decodeOpenAIResponsesImageGenerationCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesImageGenerationCall(item);
  if (projection == null) {
    return const [];
  }

  return [
    ToolCallContentPart(
      projection.toToolCall(),
      providerMetadata: projection.providerMetadata,
    ),
    ToolResultContentPart(
      projection.toToolResult(),
      providerMetadata: projection.providerMetadata,
    ),
  ];
}

List<ContentPart> decodeOpenAIResponsesFileSearchCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesFileSearchCall(item);
  if (projection == null) {
    return const [];
  }

  return [
    ToolCallContentPart(
      projection.toToolCall(),
      providerMetadata: projection.providerMetadata,
    ),
    ToolResultContentPart(
      projection.toToolResult(),
      providerMetadata: projection.providerMetadata,
    ),
  ];
}

List<ContentPart> decodeOpenAIResponsesWebSearchCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesWebSearchCall(item);
  if (projection == null) {
    return const [];
  }

  return [
    ToolCallContentPart(
      projection.toToolCall(),
      providerMetadata: projection.providerMetadata,
    ),
    ToolResultContentPart(
      projection.toToolResult(),
      providerMetadata: projection.providerMetadata,
    ),
  ];
}

List<ContentPart> decodeOpenAIResponsesComputerUseCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesComputerUseCall(item);
  if (projection == null) {
    return const [];
  }

  return [
    ToolCallContentPart(
      projection.toToolCall(),
      providerMetadata: projection.providerMetadata,
    ),
    ToolResultContentPart(
      projection.toToolResult(),
      providerMetadata: projection.providerMetadata,
    ),
  ];
}

ToolCallContentPart? decodeOpenAIResponsesToolSearchCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesToolSearchCall(item);
  if (projection == null) {
    return null;
  }

  return ToolCallContentPart(
    projection.toToolCall(),
    providerMetadata: projection.providerMetadata,
  );
}

ToolResultContentPart? decodeOpenAIResponsesToolSearchOutput(
  Map<String, Object?> item, {
  String? fallbackToolCallId,
}) {
  final projection = projectOpenAIResponsesToolSearchOutput(
    item,
    fallbackToolCallId: fallbackToolCallId,
  );
  if (projection == null) {
    return null;
  }

  return ToolResultContentPart(
    projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}

ToolCallContentPart? decodeOpenAIResponsesLocalShellCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesLocalShellCall(item);
  if (projection == null) {
    return null;
  }

  return ToolCallContentPart(
    projection.toToolCall(),
    providerMetadata: projection.providerMetadata,
  );
}

ToolResultContentPart? decodeOpenAIResponsesLocalShellCallOutputItem(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesLocalShellOutput(item);
  if (projection == null) {
    return null;
  }

  return ToolResultContentPart(
    projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}

ToolCallContentPart? decodeOpenAIResponsesShellCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesShellCall(item);
  if (projection == null) {
    return null;
  }

  return ToolCallContentPart(
    projection.toToolCall(),
    providerMetadata: projection.providerMetadata,
  );
}

ToolResultContentPart? decodeOpenAIResponsesShellCallOutputItem(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesShellOutput(item);
  if (projection == null) {
    return null;
  }

  return ToolResultContentPart(
    projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}

ToolCallContentPart? decodeOpenAIResponsesApplyPatchCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesApplyPatchCall(item);
  if (projection == null) {
    return null;
  }

  return ToolCallContentPart(
    projection.toToolCall(),
    providerMetadata: projection.providerMetadata,
  );
}

ToolResultContentPart? decodeOpenAIResponsesApplyPatchCallOutputItem(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesApplyPatchOutput(item);
  if (projection == null) {
    return null;
  }

  return ToolResultContentPart(
    projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}

CustomContentPart? decodeOpenAIResponsesCustomOutput(
    Map<String, Object?> item) {
  return projectOpenAIResponsesCustomOutputItem(item)?.toContentPart();
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

  return ProviderMetadata.forNamespace('openai', openaiValues);
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
