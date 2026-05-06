import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_streaming_support.dart';

final class OpenAIChatCompletionsSupport {
  final String providerNamespace;

  const OpenAIChatCompletionsSupport({
    required this.providerNamespace,
  });

  List<ToolCallContentPart> decodeToolCalls(List<Object?> rawToolCalls) {
    final result = <ToolCallContentPart>[];

    for (final rawToolCall in rawToolCalls) {
      final toolCall = _asMap(rawToolCall);
      if (toolCall == null) {
        continue;
      }

      final toolCallId = _asString(toolCall['id']);
      final function = _asMap(toolCall['function']);
      final toolName = _asString(function?['name']);
      if (toolCallId == null || toolName == null) {
        continue;
      }

      final encodedArguments = _asString(function?['arguments']) ?? '{}';
      result.add(
        ToolCallContentPart(
          ToolCallContent(
            toolCallId: toolCallId,
            toolName: toolName,
            input: tryDecodeOpenAIJsonValue(encodedArguments).value,
          ),
          providerMetadata: providerMetadata({
            'toolCallId': toolCallId,
          }),
        ),
      );
    }

    return result;
  }

  List<SourceContentPart> decodeTopLevelSources(Map<String, Object?> response) {
    final citations = _asList(response['citations']);
    if (citations.isEmpty) {
      return const [];
    }

    final sources = <SourceContentPart>[];
    for (var index = 0; index < citations.length; index++) {
      final rawCitation = citations[index];
      final url = _asString(rawCitation);
      if (url == null || url.isEmpty) {
        continue;
      }

      sources.add(
        SourceContentPart(
          SourceReference(
            kind: SourceReferenceKind.url,
            sourceId: url,
            uri: Uri.tryParse(url),
            title: url,
            providerMetadata: providerMetadata({
              'citationIndex': index,
            }),
          ),
        ),
      );
    }

    return sources;
  }

  Iterable<SourceEvent> decodeChunkSources(
    Map<String, Object?> chunk, {
    required String? responseId,
    required Set<String> emittedSourceIds,
  }) sync* {
    final citations = _asList(chunk['citations']);
    if (citations.isEmpty) {
      return;
    }

    for (var index = 0; index < citations.length; index++) {
      final rawCitation = citations[index];
      final url = _asString(rawCitation);
      if (url == null || url.isEmpty || !emittedSourceIds.add(url)) {
        continue;
      }

      yield SourceEvent(
        SourceReference(
          kind: SourceReferenceKind.url,
          sourceId: url,
          uri: Uri.tryParse(url),
          title: url,
          providerMetadata: providerMetadata({
            'responseId': responseId,
            'citationIndex': index,
          }),
        ),
      );
    }
  }

  OpenAIChatCompletionsDecodedAssistantText decodeAssistantText(
    Map<String, Object?> message,
  ) {
    final reasoningBuffer = StringBuffer();
    final textBuffer = StringBuffer();

    final explicitReasoning = extractReasoningText(message);
    if (explicitReasoning != null && explicitReasoning.isNotEmpty) {
      reasoningBuffer.write(explicitReasoning);
    }

    final content = message['content'];
    if (content is String) {
      appendOpenAIThinkingAndText(
        content,
        reasoningBuffer: reasoningBuffer,
        textBuffer: textBuffer,
      );
    } else if (content is List) {
      for (final rawPart in content) {
        final part = _asMap(rawPart);
        if (part == null) {
          continue;
        }

        final type = _asString(part['type']);
        final text = _asString(part['text']) ??
            _asString(part['content']) ??
            _asString(part['output_text']);
        if (type == 'reasoning' || type == 'reasoning_content') {
          if (text != null && text.isNotEmpty) {
            reasoningBuffer.write(text);
          }
          continue;
        }

        if (text != null && text.isNotEmpty) {
          appendOpenAIThinkingAndText(
            text,
            reasoningBuffer: reasoningBuffer,
            textBuffer: textBuffer,
          );
        }
      }
    }

    return OpenAIChatCompletionsDecodedAssistantText(
      text: textBuffer.toString(),
      reasoning: reasoningBuffer.isEmpty ? null : reasoningBuffer.toString(),
    );
  }

  String? extractReasoningText(Map<String, Object?> message) {
    return firstOpenAINonEmptyString([
      _asString(message['reasoning_content']),
      _asString(message['reasoning']),
      _asString(message['thinking']),
    ]);
  }

  ProviderMetadata? responseMetadata(
    Map<String, Object?> response,
    Map<String, Object?>? choice, {
    List<Object?>? logprobs,
  }) {
    return providerMetadata({
      'serviceTier': _asString(response['service_tier']),
      'systemFingerprint': _asString(response['system_fingerprint']),
      'finishReason': _asString(choice?['finish_reason']),
      if (logprobs != null && logprobs.isNotEmpty)
        'logprobs': List<Object?>.unmodifiable(logprobs),
    });
  }

  ProviderMetadata? providerMetadata(Map<String, Object?> values) {
    final scopedValues = <String, Object?>{};
    for (final entry in values.entries) {
      if (entry.value != null) {
        scopedValues[entry.key] = entry.value;
      }
    }

    if (scopedValues.isEmpty) {
      return null;
    }

    return ProviderMetadata({
      providerNamespace: scopedValues,
    });
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

  String? _asString(Object? value) {
    return value is String ? value : null;
  }
}

final class OpenAIChatCompletionsDecodedAssistantText {
  final String text;
  final String? reasoning;

  const OpenAIChatCompletionsDecodedAssistantText({
    required this.text,
    this.reasoning,
  });
}
