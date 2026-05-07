part of 'google_chat_message_codec.dart';

final class _GoogleChatToolMessageSupport {
  final GoogleClient client;

  _GoogleChatToolMessageSupport({
    required this.client,
  });

  List<Map<String, dynamic>> convertToolUse(List<ToolCall> toolCalls) {
    final parts = <Map<String, dynamic>>[];

    for (final toolCall in toolCalls) {
      try {
        final args = jsonDecode(toolCall.function.arguments);
        parts.add({
          'functionCall': {
            'name': toolCall.function.name,
            'args': args,
          },
        });
      } catch (e) {
        client.logger.warning(
          'Failed to parse tool call arguments: '
          '${toolCall.function.arguments}, error: $e',
        );
        parts.add({
          'text': '[Error: Invalid tool call arguments for '
              '${toolCall.function.name}]',
        });
      }
    }

    return parts;
  }

  List<Map<String, dynamic>> convertToolResult(List<ToolCall> results) {
    final parts = <Map<String, dynamic>>[];

    for (final result in results) {
      parts.add({
        'functionResponse': {
          'name': result.function.name,
          'response': {
            'name': result.function.name,
            'content': jsonDecode(result.function.arguments),
          },
        },
      });
    }

    return parts;
  }
}
