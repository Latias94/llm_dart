import 'dart:convert';

import '../../../../core/capability.dart';
import 'anthropic_chat_response.dart';
import 'anthropic_chat_stream_support.dart';
import 'client.dart';

/// Stateful SSE parser for the Anthropic compatibility chat shell.
class AnthropicChatStreamParser {
  final AnthropicClient client;
  late final AnthropicSseFrameBuffer _frameBuffer;
  late final AnthropicChatStreamEventSupport _eventSupport;

  AnthropicChatStreamParser({
    required this.client,
  }) {
    _frameBuffer = AnthropicSseFrameBuffer();
    _eventSupport = AnthropicChatStreamEventSupport(
      logger: client.logger,
    );
  }

  void reset() {
    _frameBuffer.reset();
    _eventSupport.reset();
  }

  List<ChatStreamEvent> parseChunk(String chunk) {
    final events = <ChatStreamEvent>[];

    for (final frame in _frameBuffer.addChunk(chunk)) {
      if (frame.eventType != null) {
        client.logger.fine('Received event type: ${frame.eventType}');
        continue;
      }

      final data = frame.data;
      if (data == null || data.isEmpty) {
        continue;
      }

      if (data == '[DONE]') {
        events.add(CompletionEvent(AnthropicChatResponse({})));
        continue;
      }

      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        final event = _eventSupport.parseStreamEvent(json);
        if (event != null) {
          events.add(event);
        }
      } catch (e) {
        client.logger.fine(
          'Failed to parse stream JSON: '
          '${data.substring(0, data.length > 50 ? 50 : data.length)}..., '
          'error: $e',
        );
      }
    }

    return events;
  }
}
