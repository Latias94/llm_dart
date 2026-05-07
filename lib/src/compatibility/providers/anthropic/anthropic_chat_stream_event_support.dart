part of 'anthropic_chat_stream_support.dart';

/// Stateful Anthropic stream event decoder.
///
/// This owns provider-specific stream event semantics, including incremental
/// tool-call input aggregation, thinking deltas, stop-reason completion events,
/// and Anthropic error payload mapping.
final class AnthropicChatStreamEventSupport {
  final Logger logger;
  final _AnthropicChatStreamMessageEvents _messageEvents;
  final _AnthropicChatStreamContentBlockEvents _contentBlockEvents;
  final _AnthropicChatStreamErrorEvents _errorEvents;

  AnthropicChatStreamEventSupport({
    required this.logger,
  })  : _messageEvents = _AnthropicChatStreamMessageEvents(logger: logger),
        _contentBlockEvents = _AnthropicChatStreamContentBlockEvents(
          logger: logger,
        ),
        _errorEvents = const _AnthropicChatStreamErrorEvents();

  void reset() {
    _contentBlockEvents.reset();
  }

  ChatStreamEvent? parseStreamEvent(Map<String, dynamic> json) {
    final type = json['type'] as String?;

    switch (type) {
      case 'message_start':
        return _messageEvents.parseMessageStart(json);
      case 'content_block_start':
        _contentBlockEvents.trackContentBlockStart(json);
        break;
      case 'content_block_delta':
        return _contentBlockEvents.parseContentBlockDelta(json);
      case 'content_block_stop':
        return _contentBlockEvents.parseContentBlockStop(json);
      case 'message_delta':
        return _messageEvents.parseMessageDelta(json);
      case 'message_stop':
        return _messageEvents.parseMessageStop();
      case 'error':
        return _errorEvents.parseError(json);
      default:
        logger.warning('Unknown stream event type: $type');
    }

    return null;
  }
}
