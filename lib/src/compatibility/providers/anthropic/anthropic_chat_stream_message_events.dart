part of 'anthropic_chat_stream_support.dart';

final class _AnthropicChatStreamMessageEvents {
  final Logger logger;

  _AnthropicChatStreamMessageEvents({
    required this.logger,
  });

  ChatStreamEvent? parseMessageStart(Map<String, dynamic> json) {
    final message = json['message'] as Map<String, dynamic>?;
    if (message == null) {
      return null;
    }

    final rawUsage = message['usage'];
    if (rawUsage == null) {
      return null;
    }

    return CompletionEvent(AnthropicChatResponse({
      'content': [],
      'usage': _mapUsage(rawUsage),
    }));
  }

  ChatStreamEvent parseMessageStop() {
    return CompletionEvent(AnthropicChatResponse({
      'content': [],
      'usage': {},
    }));
  }

  ChatStreamEvent? parseMessageDelta(Map<String, dynamic> json) {
    final delta = json['delta'] as Map<String, dynamic>?;
    if (delta == null) {
      return null;
    }

    final stopReason = delta['stop_reason'] as String?;
    if (stopReason == null) {
      return null;
    }

    final rawUsage = json['usage'];
    final response = AnthropicChatResponse({
      'content': [],
      'usage': rawUsage == null ? null : _mapUsage(rawUsage),
      'stop_reason': stopReason,
    });

    if (stopReason == 'pause_turn') {
      logger.info('Turn paused - long-running operation in progress');
    } else if (stopReason == 'tool_use') {
      logger.info('Stopped for tool use');
    }

    return CompletionEvent(response);
  }

  Map<String, dynamic> _mapUsage(Object rawUsage) {
    if (rawUsage is Map<String, dynamic>) {
      return rawUsage;
    }
    if (rawUsage is Map) {
      return Map<String, dynamic>.from(rawUsage);
    }
    return <String, dynamic>{};
  }
}
