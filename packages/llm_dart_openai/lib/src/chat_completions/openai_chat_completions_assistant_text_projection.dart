import '../common/openai_streaming_support.dart';

OpenAIChatCompletionsDecodedAssistantText
    decodeOpenAIChatCompletionsAssistantText(Map<String, Object?> message) {
  final reasoningBuffer = StringBuffer();
  final textBuffer = StringBuffer();

  final explicitReasoning = extractOpenAIChatCompletionsReasoningText(message);
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

String? extractOpenAIChatCompletionsReasoningText(
  Map<String, Object?> message,
) {
  return firstOpenAINonEmptyString([
    _asString(message['reasoning_content']),
    _asString(message['reasoning']),
    _asString(message['thinking']),
  ]);
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

String? _asString(Object? value) => value is String ? value : null;

final class OpenAIChatCompletionsDecodedAssistantText {
  final String text;
  final String? reasoning;

  const OpenAIChatCompletionsDecodedAssistantText({
    required this.text,
    this.reasoning,
  });
}
