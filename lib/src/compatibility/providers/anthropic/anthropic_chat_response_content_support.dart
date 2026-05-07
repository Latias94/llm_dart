part of 'anthropic_chat_response.dart';

final class _AnthropicChatResponseContentSupport {
  const _AnthropicChatResponseContentSupport();

  List<Map<String, dynamic>> contentBlocks(Map<String, dynamic> rawResponse) {
    final content = rawResponse['content'];
    if (content is! List || content.isEmpty) {
      return const [];
    }

    return [
      for (final block in content)
        if (block is Map<String, dynamic>)
          block
        else if (block is Map)
          Map<String, dynamic>.from(block),
    ];
  }

  String? extractText(Map<String, dynamic> rawResponse) {
    final textBlocks = contentBlocks(rawResponse)
        .where((block) => block['type'] == 'text')
        .map((block) => block['text'])
        .whereType<String>();

    return textBlocks.isEmpty ? null : textBlocks.join('\n');
  }

  String? extractThinking(Map<String, dynamic> rawResponse) {
    final thinkingBlocks = <String>[];

    for (final block in contentBlocks(rawResponse)) {
      final blockType = block['type'] as String?;
      if (blockType == 'thinking') {
        final thinkingText = block['thinking'] as String?;
        if (thinkingText != null && thinkingText.isNotEmpty) {
          thinkingBlocks.add(thinkingText);
        }
      } else if (blockType == 'redacted_thinking') {
        thinkingBlocks
            .add('[Redacted thinking content - encrypted for safety]');
      }
    }

    return thinkingBlocks.isEmpty ? null : thinkingBlocks.join('\n\n');
  }
}
