part of 'google_chat_response.dart';

final class _GoogleChatResponseContentSupport {
  const _GoogleChatResponseContentSupport();

  String? extractText(Map<String, dynamic> rawResponse) {
    final parts = _extractParts(rawResponse);
    if (parts == null) return null;

    final textParts = <String>[];
    for (final part in parts) {
      if (_isThought(part)) {
        continue;
      }

      final text = _extractText(part);
      if (text != null && text.isNotEmpty) {
        textParts.add(text);
      }
    }

    return textParts.isEmpty ? null : textParts.join('\n');
  }

  String? extractThinking(Map<String, dynamic> rawResponse) {
    final parts = _extractParts(rawResponse);
    if (parts == null) return null;

    final thinkingParts = <String>[];
    for (final part in parts) {
      if (!_isThought(part)) {
        continue;
      }

      final text = _extractText(part);
      if (text != null && text.isNotEmpty) {
        thinkingParts.add(text);
      }
    }

    return thinkingParts.isEmpty ? null : thinkingParts.join('\n');
  }
}
