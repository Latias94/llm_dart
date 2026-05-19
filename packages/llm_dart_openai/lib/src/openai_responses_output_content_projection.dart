import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_metadata.dart';
import 'openai_responses_source_projection.dart';
import 'openai_responses_stream_util.dart';
import 'openai_streaming_support.dart';

List<ContentPart> decodeOpenAIResponsesMessageOutput(
    Map<String, Object?> item) {
  final parts = <ContentPart>[];
  final content = openAIResponsesAsList(item['content']);

  for (final rawContentPart in content) {
    final contentPart = openAIResponsesAsMap(rawContentPart);
    if (contentPart == null) {
      continue;
    }

    final contentType = openAIResponsesAsString(contentPart['type']);
    if (contentType == 'output_text') {
      parts.add(
        TextContentPart(
          openAIResponsesAsString(contentPart['text']) ?? '',
          providerMetadata: openAIResponsesItemMetadata(
            item,
            extra: {
              'contentType': contentType,
              'logprobs':
                  openAIResponsesJsonListOrNull(contentPart['logprobs']),
            },
          ),
        ),
      );

      for (final annotation
          in openAIResponsesAsList(contentPart['annotations'])) {
        final source = decodeOpenAIResponsesSourceAnnotation(
          openAIResponsesAsMap(annotation),
        );
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
  final summaries = openAIResponsesAsList(item['summary']);

  for (var index = 0; index < summaries.length; index++) {
    final summary = openAIResponsesAsMap(summaries[index]);
    if (summary == null) {
      continue;
    }

    final text = openAIResponsesAsString(summary['text']);
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
  final toolCallId = openAIResponsesAsString(item['call_id']) ??
      fallbackToolCallId ??
      openAIResponsesAsString(item['id']);
  final toolName = openAIResponsesAsString(item['name']) ?? fallbackToolName;
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
      title: openAIResponsesAsString(item['title']),
    ),
    providerMetadata: openAIResponsesItemMetadata(
      item,
      extra: {
        'callId': toolCallId,
      },
    ),
  );
}

void collectOpenAIResponsesMessageOutputLogprobs(
  Map<String, Object?> item, {
  required List<Object?> into,
}) {
  for (final rawContentPart in openAIResponsesAsList(item['content'])) {
    final contentPart = openAIResponsesAsMap(rawContentPart);
    if (contentPart == null ||
        openAIResponsesAsString(contentPart['type']) != 'output_text') {
      continue;
    }

    appendOpenAILogprobs(
      into,
      openAIResponsesJsonListOrNull(contentPart['logprobs']),
    );
  }
}

Object? decodeOpenAIResponsesJsonValue(String value) {
  return tryDecodeOpenAIJsonValue(value).value;
}

String resolveOpenAIResponsesFunctionCallArguments(
  Map<String, Object?> item, {
  String? fallbackArguments,
}) {
  final encoded = openAIResponsesAsString(item['arguments']);
  if (encoded != null) {
    return encoded;
  }

  if (fallbackArguments != null && fallbackArguments.isNotEmpty) {
    return fallbackArguments;
  }

  return '{}';
}
