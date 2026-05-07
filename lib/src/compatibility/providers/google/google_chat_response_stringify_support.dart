part of 'google_chat_response.dart';

final class _GoogleChatResponseStringifySupport {
  static const _contentSupport = _GoogleChatResponseContentSupport();
  static const _toolSupport = _GoogleChatResponseToolSupport();

  const _GoogleChatResponseStringifySupport();

  String stringify(Map<String, dynamic> rawResponse) {
    final parts = <String>[];

    final thinkingContent = _contentSupport.extractThinking(rawResponse);
    if (thinkingContent != null) {
      parts.add('Thinking: $thinkingContent');
    }

    final calls = _toolSupport.extractToolCalls(rawResponse);
    if (calls != null) {
      parts.add(calls.map((call) => call.toString()).join('\n'));
    }

    final textContent = _contentSupport.extractText(rawResponse);
    if (textContent != null) {
      parts.add(textContent);
    }

    return parts.join('\n');
  }
}
