import 'dart:convert';

import '../../../../core/capability.dart';
import '../../../../providers/ollama/client.dart';
import 'ollama_chat_response.dart';

class OllamaChatStreamParser {
  final OllamaClient client;

  OllamaChatStreamParser({required this.client});

  List<ChatStreamEvent> parseChunk(String chunk) {
    final events = <ChatStreamEvent>[];
    final lines = chunk.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) {
        continue;
      }

      try {
        final json = jsonDecode(line) as Map<String, dynamic>;
        final event = _parseEvent(json);
        if (event != null) {
          events.add(event);
        }
      } catch (e) {
        client.logger.warning('Failed to parse stream JSON: $line, error: $e');
      }
    }

    return events;
  }

  ChatStreamEvent? _parseEvent(Map<String, dynamic> json) {
    final message = json['message'] as Map<String, dynamic>?;
    if (message != null) {
      final thinking = message['thinking'] as String?;
      if (thinking != null && thinking.isNotEmpty) {
        return ThinkingDeltaEvent(thinking);
      }

      final content = message['content'] as String?;
      if (content != null && content.isNotEmpty) {
        return TextDeltaEvent(content);
      }
    }

    if (json['done'] == true) {
      return CompletionEvent(OllamaChatResponse(json));
    }

    return null;
  }
}
