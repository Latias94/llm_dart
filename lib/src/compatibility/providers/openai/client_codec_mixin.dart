part of 'client.dart';

mixin _OpenAIClientCodecMixin {
  OpenAISseChunkParser get _sseChunkParser;
  OpenAIClientMessageCodec get _messageCodec;

  List<Map<String, dynamic>> parseSSEChunk(String chunk) {
    return _sseChunkParser.parse(chunk);
  }

  /// Reset SSE buffer (call when starting a new stream).
  void resetSSEBuffer() {
    _sseChunkParser.reset();
  }

  /// Convert ChatMessage to OpenAI API format.
  Map<String, dynamic> convertMessage(ChatMessage message) {
    return _messageCodec.convertMessage(message);
  }

  /// Build API messages array from ChatMessage list.
  ///
  /// Note: System prompt should be added by the calling module if needed,
  /// not here to avoid duplication.
  List<Map<String, dynamic>> buildApiMessages(List<ChatMessage> messages) {
    return _messageCodec.buildApiMessages(messages);
  }
}
