part of 'google_chat_stream_support.dart';

final class _GoogleChatStreamEventSupport {
  const _GoogleChatStreamEventSupport();

  List<ChatStreamEvent> mapPayload(Map<String, dynamic> json) {
    final events = <ChatStreamEvent>[];
    final candidates = json['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return events;

    final firstCandidate = candidates.first;
    if (firstCandidate is! Map<String, dynamic>) return events;

    final content = firstCandidate['content'] as Map<String, dynamic>?;
    if (content == null) {
      return _appendCompletionIfPresent(events, json, firstCandidate);
    }

    final parts = content['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      return _appendCompletionIfPresent(events, json, firstCandidate);
    }

    for (final part in parts) {
      if (part is! Map<String, dynamic>) {
        continue;
      }

      final isThought = part['thought'] as bool? ?? false;
      final text = part['text'] as String?;

      if (isThought && text != null && text.isNotEmpty) {
        events.add(ThinkingDeltaEvent(text));
        continue;
      }

      if (!isThought && text != null && text.isNotEmpty) {
        events.add(TextDeltaEvent(text));
        continue;
      }

      final inlineData = part['inlineData'] as Map<String, dynamic>?;
      if (inlineData != null) {
        final mimeType = inlineData['mimeType'] as String?;
        final data = inlineData['data'] as String?;
        if (mimeType != null && data != null && mimeType.startsWith('image/')) {
          events.add(TextDeltaEvent('[Generated image: $mimeType]'));
          continue;
        }
      }

      final functionCall = part['functionCall'] as Map<String, dynamic>?;
      if (functionCall != null) {
        final name = functionCall['name'] as String;
        final args = functionCall['args'] as Map<String, dynamic>? ?? {};

        final toolCall = ToolCall(
          id: 'call_$name',
          callType: 'function',
          function: FunctionCall(name: name, arguments: jsonEncode(args)),
        );

        events.add(ToolCallDeltaEvent(toolCall));
      }
    }

    return _appendCompletionIfPresent(events, json, firstCandidate);
  }

  List<ChatStreamEvent> _appendCompletionIfPresent(
    List<ChatStreamEvent> events,
    Map<String, dynamic> json,
    Map<String, dynamic> candidate,
  ) {
    final finishReason = candidate['finishReason'] as String?;
    if (finishReason != null) {
      final usage = json['usageMetadata'] as Map<String, dynamic>?;
      events.add(
        CompletionEvent(
          GoogleChatResponse({
            'candidates': const [],
            'usageMetadata': usage,
          }),
        ),
      );
    }

    return events;
  }
}
